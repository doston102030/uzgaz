-- Gaz & Energiya — marketplace: every seller is a buyer-facing company, and
-- orders live in a real table shared by the app and both web panels.
--
-- Run once in Supabase Dashboard → SQL Editor → New query → Run, after
-- seller_login_setup.sql. Safe to re-run (idempotent).
--
-- Why: products.company_id references companies(id), but the seller panel
-- writes the seller's id there — every product insert failed with 23503
-- (foreign key). Mirroring each seller into companies fixes that and also
-- gives the buyer app what it already reads for a company: name, map pin,
-- delivery fee, working hours, cheapest price.
--
-- SECURITY NOTE: same trust model as seller_workflow_setup.sql — there is
-- no Supabase Auth yet, so orders are readable/writable with the anon key
-- (buyer names, phones and addresses included). Before real customers use
-- the app, add Supabase Auth and replace the open policies below with
-- ownership checks (buyer = auth.uid(), seller = their company_id).

-- ── 1. Demo companies (were pending remove_demo_companies.sql) ────
delete from public.companies c
using (values
  ('c1', 'Andijon Gaz Markazi'),
  ('c2', 'Asaka Energiya Servis'),
  ('c3', 'Shahrixon Gaz Ta''minot'),
  ('c4', 'Xo''jaobod Metan Servis'),
  ('c5', 'Marhamat Sanoat Gaz'),
  ('c6', 'Andijon GazPlus')
) as demo(id, name)
where c.id = demo.id and c.name = demo.name
  and not exists (select 1 from public.products p where p.company_id = c.id)
  and not exists (select 1 from public.sellers s where s.id = c.id);

-- ── 2. Seller → company mirror ────────────────────────────────────
-- District centres — the same numbers as AndijonDistrict in
-- lib/core/constants/app_constants.dart, so a new company's pin sits where
-- the map's district chip points. Unknown district → Andijon shahri.
create or replace function public.district_point(p_district text)
returns table (latitude double precision, longitude double precision)
language sql
immutable
as $$
  select coalesce(d.lat, 40.7833), coalesce(d.lng, 72.3444)
  from (select 1) one
  left join (values
    ('andijon shahri', 40.7833, 72.3444),
    ('andijon tumani', 40.8206, 72.4206),
    ('asaka',          40.6414, 72.2331),
    ('baliqchi',       40.6186, 72.1622),
    ('bo''z',          40.8781, 72.5417),
    ('buloqboshi',     40.7206, 72.4500),
    ('izboskan',       40.8272, 72.4728),
    ('jalaquduq',      40.9106, 72.6494),
    ('marhamat',       40.4497, 72.2739),
    ('oltinko''l',     40.5433, 72.1547),
    ('paxtaobod',      40.6069, 72.2917),
    ('qo''rg''ontepa', 40.7156, 72.0925),
    ('shahrixon',      40.7275, 72.0281),
    ('ulug''nor',      40.6394, 72.6208),
    ('xo''jaobod',     40.8781, 72.6494)
  ) as d(name, lat, lng)
    -- ‘ ’ ʻ ʼ ` all mean the same apostrophe in Uzbek Latin.
    on d.name = lower(trim(translate(coalesce(p_district, ''), '‘’ʻʼ`', '''''''''''')));
$$;

-- New companies start with the defaults of the app's seller form
-- (09:00 - 21:00, 15 000 so'm delivery); later updates only touch the
-- fields the seller row owns, so a seller's own edits are kept.
create or replace function public.sync_seller_company()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    delete from public.products where company_id = old.id;
    delete from public.companies where id = old.id;
    return old;
  end if;

  insert into public.companies as c (
    id, name, address, phone, is_available, rating, review_count, tags,
    working_hours, delivery_fee, eta_minutes, latitude, longitude
  )
  select new.id, new.company_name, new.address, new.phone,
         new.status = 'approved', new.rating, new.review_count, '{}',
         '09:00 - 21:00', 15000, 40, p.latitude, p.longitude
  from public.district_point(new.district) p
  on conflict (id) do update set
    name = excluded.name,
    address = excluded.address,
    phone = excluded.phone,
    is_available = excluded.is_available,
    rating = excluded.rating,
    review_count = excluded.review_count,
    -- Re-pin only when the district changed.
    latitude = case when tg_op = 'UPDATE' and old.district is distinct from new.district
                    then excluded.latitude else c.latitude end,
    longitude = case when tg_op = 'UPDATE' and old.district is distinct from new.district
                     then excluded.longitude else c.longitude end;
  return new;
end;
$$;

drop trigger if exists sellers_sync_company on public.sellers;
create trigger sellers_sync_company
  after insert or update or delete on public.sellers
  for each row execute function public.sync_seller_company();

-- Backfill sellers that existed before the trigger (no-op update fires it).
update public.sellers set status = status;

-- The seller panel profile and the app's seller form edit the
-- buyer-facing details (working hours, delivery fee, ETA, logo).
-- Rows themselves are only created/removed by the trigger above.
drop policy if exists "public update companies" on public.companies;
create policy "public update companies" on public.companies
  for update using (true) with check (true);

-- ── 3. Cheapest approved price on the company card ────────────────
create or replace function public.refresh_company_price(p_company_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.companies c
  set product_price = coalesce((
    select min(p.price) from public.products p
    where p.company_id = c.id and p.moderation_status = 'approved' and p.is_available
  ), 0)
  where c.id = p_company_id;
$$;

create or replace function public.products_refresh_company_price()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op <> 'INSERT' and old.company_id is not null then
    perform public.refresh_company_price(old.company_id);
  end if;
  if tg_op <> 'DELETE' and new.company_id is not null
     and new.company_id is distinct from (case when tg_op = 'UPDATE' then old.company_id end) then
    perform public.refresh_company_price(new.company_id);
  end if;
  return null;
end;
$$;

drop trigger if exists products_company_price on public.products;
create trigger products_company_price
  after insert or update or delete on public.products
  for each row execute function public.products_refresh_company_price();

-- ── 4. Orders ─────────────────────────────────────────────────────
-- One row per order; items are a snapshot (name/price at order time), so
-- later product edits never rewrite a past receipt.
-- items: [{"product_id", "name", "quantity", "price", "category_id"}]
create sequence if not exists public.orders_number_seq start 234522;

create table if not exists public.orders (
  id text primary key,
  order_number text not null unique
    default ('#GE' || nextval('public.orders_number_seq')),
  company_id text references public.companies(id) on delete set null,
  company_name text not null,
  buyer_name text not null default '',
  buyer_phone text not null default '',
  delivery_method text not null default 'delivery'
    check (delivery_method in ('delivery', 'selfPickup')),
  payment_method text not null default '',
  address text,
  items jsonb not null default '[]'::jsonb,
  subtotal integer not null default 0,
  delivery_fee integer not null default 0,
  total integer not null default 0,
  status text not null default 'qabulQilindi'
    check (status in ('qabulQilindi', 'tayyorlanmoqda', 'yolda', 'yetkazildi', 'bekorQilindi')),
  cancel_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter sequence public.orders_number_seq owned by public.orders.order_number;

create index if not exists orders_company_id_idx on public.orders (company_id, created_at desc);
create index if not exists orders_buyer_phone_idx on public.orders (buyer_phone, created_at desc);

create or replace function public.orders_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists orders_touch_updated_at on public.orders;
create trigger orders_touch_updated_at
  before update on public.orders
  for each row execute function public.orders_touch_updated_at();

alter table public.orders enable row level security;

drop policy if exists "public read orders" on public.orders;
create policy "public read orders" on public.orders
  for select using (true);

drop policy if exists "public write orders" on public.orders;
create policy "public write orders" on public.orders
  for all using (true) with check (true);

grant usage, select on sequence public.orders_number_seq to anon, authenticated;

-- ── 5. Product categories ─────────────────────────────────────────
-- Platform categories (seller_id null) are managed in the admin panel; a
-- seller may add their own (seller_id = that seller). Products store only
-- the id, so renaming a category (the pencil in both panels) never has to
-- touch products. A product whose category_id is not here shows the id
-- itself as its label (older free-text categories).
create table if not exists public.product_categories (
  id text primary key,
  label text not null check (length(trim(label)) between 1 and 40),
  icon text not null default 'tag',
  seller_id text references public.sellers(id) on delete cascade,
  sort_order integer not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- One name per owner, ignoring case and surrounding spaces.
create unique index if not exists product_categories_owner_label_idx
  on public.product_categories (coalesce(seller_id, ''), lower(trim(label)));

insert into public.product_categories (id, label, icon, sort_order) values
  ('gazBallon', 'Yangi gaz ballon', 'cylinder', 1),
  ('gazToldirish', 'Gaz ballon to''ldirish', 'fuel', 2),
  ('gazTamirlash', 'Gaz ta''mirlash', 'wrench', 3)
on conflict (id) do nothing;

alter table public.product_categories enable row level security;

drop policy if exists "public read product_categories" on public.product_categories;
create policy "public read product_categories" on public.product_categories
  for select using (true);

drop policy if exists "public write product_categories" on public.product_categories;
create policy "public write product_categories" on public.product_categories
  for all using (true) with check (true);

notify pgrst, 'reload schema';
