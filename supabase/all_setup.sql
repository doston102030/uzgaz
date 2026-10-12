-- Hammasi bir faylda: yangi Supabase loyihasi uchun. SQL Editor'ga to'liq tashlab Run bosing.

-- ======== catalog_setup.sql ========
-- Gaz & Energiya — Catalog tables (companies + products) backing the
-- buyer-facing marketplace. Run this once in Supabase Dashboard →
-- SQL Editor → New query → Run. Safe to re-run (idempotent).
--
-- Scope note: only the buyer catalog moves to a real table this pass.
-- Orders/cart/checkout and seller-side product management stay mock for
-- now — they're a separate, transactional piece (status flows, seller
-- fulfilment) that deserves its own migration.
--
-- Security note: nothing in the app writes to these tables yet (the
-- catalog is read-only from the client), so — unlike the Storage
-- buckets, which the app itself uploads into — there is no public write
-- policy here at all. Only the project owner (via this SQL Editor, or
-- later a real admin role) can change catalog rows.
--
-- Demo rows are intentionally not created.

-- ── companies ──────────────────────────────────────────────────────
create table if not exists public.companies (
  id text primary key,
  name text not null,
  logo_url text,
  rating numeric not null default 0,
  review_count integer not null default 0,
  distance_km numeric not null default 0,
  product_price integer not null default 0,
  delivery_fee integer not null default 0,
  eta_minutes integer not null default 0,
  working_hours text not null default '',
  is_available boolean not null default true,
  latitude double precision not null default 0,
  longitude double precision not null default 0,
  address text not null default '',
  phone text not null default '',
  tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.companies enable row level security;

drop policy if exists "public read companies" on public.companies;
create policy "public read companies" on public.companies
  for select using (true);

-- ── products ───────────────────────────────────────────────────────
create table if not exists public.products (
  id text primary key,
  name text not null,
  image_url text not null default '',
  price integer not null,
  old_price integer,
  rating numeric not null default 0,
  review_count integer not null default 0,
  is_available boolean not null default true,
  is_popular boolean not null default false,
  company_id text references public.companies(id) on delete set null,
  company_name text not null,
  category_id text not null,
  description text,
  unit text not null default 'dona',
  specs jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;

drop policy if exists "public read products" on public.products;
create policy "public read products" on public.products
  for select using (true);

create index if not exists products_category_id_idx on public.products (category_id);
create index if not exists products_company_id_idx on public.products (company_id);

-- Catalog starts empty; add real companies and products explicitly.

-- ======== storage_setup.sql ========
-- Gaz & Energiya — Storage setup for image uploads (product photos,
-- profile avatars, company logos).
--
-- Run this once in Supabase Dashboard → SQL Editor → New query → Run.
-- Safe to re-run: bucket inserts are idempotent and policies are dropped
-- before being recreated.

-- 1) Buckets — public read (so images show up in the app for anyone),
--    5 MB cap, images only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('product-images', 'product-images', true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('avatars',        'avatars',        true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('company-logos',  'company-logos',  true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2) Policies on storage.objects.
--
-- Demo phase note: the app doesn't sign users into Supabase Auth yet (it
-- still uses local mock accounts — see the "Faqat ulanish" scope agreed
-- earlier), so these policies allow uploads from anyone holding the
-- publishable/anon key, same as the buckets' public read. Once real
-- Supabase Auth is wired, replace "true" in the upload/update/delete
-- policies below with an owner check, e.g.
--   (storage.foldername(name))[1] = auth.uid()::text
-- so users can only write inside their own folder.

drop policy if exists "public read product-images" on storage.objects;
drop policy if exists "public write product-images" on storage.objects;
drop policy if exists "public read avatars" on storage.objects;
drop policy if exists "public write avatars" on storage.objects;
drop policy if exists "public read company-logos" on storage.objects;
drop policy if exists "public write company-logos" on storage.objects;

create policy "public read product-images" on storage.objects
  for select using (bucket_id = 'product-images');
create policy "public write product-images" on storage.objects
  for all using (bucket_id = 'product-images') with check (bucket_id = 'product-images');

create policy "public read avatars" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "public write avatars" on storage.objects
  for all using (bucket_id = 'avatars') with check (bucket_id = 'avatars');

create policy "public read company-logos" on storage.objects
  for select using (bucket_id = 'company-logos');
create policy "public write company-logos" on storage.objects
  for all using (bucket_id = 'company-logos') with check (bucket_id = 'company-logos');


-- ======== seller_workflow_setup.sql ========
-- Gaz & Energiya — Seller workflow: a real `sellers` table + moderation
-- columns on `products`, so the Admin and Seller web panels share one
-- backend instead of each keeping independent local mock data.
--
-- Run once in Supabase Dashboard → SQL Editor → New query → Run.
-- Safe to re-run (idempotent).
--
-- SECURITY NOTE: like storage_setup.sql, the app has no real Supabase Auth
-- yet, so the write policies below are open to anyone holding the
-- anon/publishable key — same trust model already accepted for image
-- uploads. Before real third-party sellers sign up, add Supabase Auth and
-- replace `using (true)` / `with check (true)` below with real ownership
-- checks (e.g. a seller may only write rows where id = auth.uid()).

-- ── sellers ────────────────────────────────────────────────────────
create table if not exists public.sellers (
  id text primary key,
  company_name text not null,
  owner_name text not null,
  category text not null,
  district text not null,
  address text not null default '',
  phone text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'suspended')),
  rating numeric not null default 0,
  review_count integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.sellers enable row level security;

drop policy if exists "public read sellers" on public.sellers;
create policy "public read sellers" on public.sellers
  for select using (true);

drop policy if exists "public write sellers" on public.sellers;
create policy "public write sellers" on public.sellers
  for all using (true) with check (true);

-- ── products: add seller-side moderation columns ──────────────────
-- (existing rows default to 'approved' so the live buyer catalog is
-- unaffected — see the buyer query change note below)
alter table public.products
  add column if not exists moderation_status text not null default 'approved'
    check (moderation_status in ('pending', 'approved', 'rejected'));
alter table public.products add column if not exists stock_qty integer not null default 0;
alter table public.products add column if not exists rejection_reason text;
alter table public.products add column if not exists images text[];

-- Buyer-facing catalog reads only ever used `for select using (true)` with
-- no write policy at all. Sellers now need to insert/update their own
-- products (and admins need to update moderation_status), so open writes
-- the same way products-images Storage already is:
drop policy if exists "public write products" on public.products;
create policy "public write products" on public.products
  for all using (true) with check (true);

-- IMPORTANT — pair this migration with a buyer-app query change: the
-- Flutter catalog fetch (lib/features/products/data/datasources/
-- supabase_products_datasource.dart) must add
-- `.eq('moderation_status', 'approved')` so pending/rejected seller
-- submissions never show to real buyers. Already done in this pass.

-- Sellers are created explicitly; no demo account is seeded.

-- ======== seller_login_setup.sql ========
-- Gaz & Energiya — seller logins: the admin gives each company a login and
-- password, the seller signs in to the Seller web panel with them.
--
-- Run once in Supabase Dashboard → SQL Editor → New query → Run, after
-- seller_workflow_setup.sql. Safe to re-run (idempotent).
--
-- Why not Supabase Auth: the project requires email confirmation, sellers
-- have no email, and the anon key cannot set another user's password.
--
-- The table has RLS on and no policies, so the anon key cannot read it —
-- not even the bcrypt hashes. Everything goes through the security-definer
-- functions below.
--
-- SECURITY NOTE: the admin panel has no login yet, so `set_seller_login`
-- is callable with the anon key — same trust model as the open write
-- policies in seller_workflow_setup.sql. Restrict it to a real admin role
-- once the admin panel gets authentication.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.seller_credentials (
  seller_id text primary key references public.sellers(id) on delete cascade,
  login text not null unique,
  password_hash text not null,
  -- Shared by all of the seller's signed-in browsers; a new password
  -- clears it, which signs every one of them out.
  session_token uuid,
  updated_at timestamptz not null default now()
);

alter table public.seller_credentials enable row level security;
revoke all on public.seller_credentials from anon, authenticated;

-- ── admin: give or change a login ─────────────────────────────────
create or replace function public.set_seller_login(
  p_seller_id text,
  p_login text,
  p_password text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
#variable_conflict use_column
declare
  v_login text := lower(trim(coalesce(p_login, '')));
begin
  if not exists (select 1 from public.sellers s where s.id = p_seller_id) then
    raise exception 'seller_not_found';
  end if;
  if v_login !~ '^[a-z0-9._-]{3,32}$' then
    raise exception 'login_invalid';
  end if;
  if length(coalesce(p_password, '')) < 6 then
    raise exception 'password_too_short';
  end if;
  if exists (
    select 1 from public.seller_credentials c
    where c.login = v_login and c.seller_id <> p_seller_id
  ) then
    raise exception 'login_taken';
  end if;

  insert into public.seller_credentials (seller_id, login, password_hash, session_token, updated_at)
  values (p_seller_id, v_login, crypt(p_password, gen_salt('bf')), null, now())
  on conflict (seller_id) do update
    set login = excluded.login,
        password_hash = excluded.password_hash,
        session_token = null,
        updated_at = now();
end;
$$;

-- ── admin: which sellers already have a login ─────────────────────
create or replace function public.seller_logins()
returns table (seller_id text, login text, updated_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select c.seller_id, c.login, c.updated_at from public.seller_credentials c;
$$;

-- ── seller panel: sign in ─────────────────────────────────────────
-- Empty result = wrong login or password (deliberately not told apart).
create or replace function public.seller_sign_in(p_login text, p_password text)
returns table (
  token uuid,
  seller_id text,
  company_name text,
  owner_name text,
  status text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
#variable_conflict use_column
declare
  v_cred public.seller_credentials;
begin
  select * into v_cred
  from public.seller_credentials c
  where c.login = lower(trim(coalesce(p_login, '')));

  if not found or v_cred.password_hash <> crypt(coalesce(p_password, ''), v_cred.password_hash) then
    return;
  end if;

  if v_cred.session_token is null then
    update public.seller_credentials c
    set session_token = gen_random_uuid()
    where c.seller_id = v_cred.seller_id
    returning c.session_token into v_cred.session_token;
  end if;

  return query
    select v_cred.session_token, s.id, s.company_name, s.owner_name, s.status
    from public.sellers s
    where s.id = v_cred.seller_id;
end;
$$;

-- ── seller panel: restore a saved session ─────────────────────────
-- Text, not uuid, so a garbled saved token is "signed out", not an error.
create or replace function public.seller_session(p_token text)
returns table (seller_id text, company_name text, owner_name text, status text)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.company_name, s.owner_name, s.status
  from public.seller_credentials c
  join public.sellers s on s.id = c.seller_id
  where c.session_token is not null and c.session_token::text = p_token;
$$;

revoke all on function public.set_seller_login(text, text, text) from public;
revoke all on function public.seller_logins() from public;
revoke all on function public.seller_sign_in(text, text) from public;
revoke all on function public.seller_session(text) from public;
grant execute on function public.set_seller_login(text, text, text) to anon, authenticated;
grant execute on function public.seller_logins() to anon, authenticated;
grant execute on function public.seller_sign_in(text, text) to anon, authenticated;
grant execute on function public.seller_session(text) to anon, authenticated;

notify pgrst, 'reload schema';

-- ======== marketplace_setup.sql ========
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

-- ======== promo_banners_setup.sql ========
-- Gaz & Energiya — Bosh sahifadagi reklama bannerlari.
--
-- Admin paneldagi "Reklama" bo'limi shu jadvalni boshqaradi, ilova (Bosh
-- sahifa karuseli) undan o'qiydi: faqat is_active = true, sort_order bo'yicha.
-- Jadval bo'lmasa yoki bo'sh bo'lsa, ilova o'zining 3 ta standart bannerini
-- ko'rsataveradi.
--
-- SQL Editor'da bir marta ishga tushiring. Qayta ishga tushirish xavfsiz.

create table if not exists public.promo_banners (
  id text primary key,
  -- Sarlavha (katta, qora) va izoh (rangli, ostida).
  title text not null check (length(trim(title)) between 1 and 60),
  caption text not null default '' check (length(caption) <= 90),
  -- Banner rangi: fon tusi, izoh va bezak shu rangda. #RRGGBB.
  accent text not null default '#2563EB' check (accent ~ '^#[0-9A-Fa-f]{6}$'),
  -- O'ngdagi rasm: Storage URL'i (shaffof PNG/WEBP eng yaxshi), yoki
  -- ilova ichidagi rasm "asset:assets/images/…". Bo'sh bo'lsa — [icon].
  image_url text,
  -- Rasm yo'q bo'lsa chiziladigan belgi: flame | cylinder | bolt | truck | tag.
  icon text not null default 'flame',
  -- Bosilganda: "category:<ServiceCategory>" (katalog shu toifada),
  -- "services" (elektr quvvatlash), "url:https://…" yoki bo'sh (hech narsa).
  link text not null default '',
  sort_order integer not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Hozirgi uchta banner — SQL ishga tushgach Bosh sahifa o'zgarmaydi.
insert into public.promo_banners (id, title, caption, accent, image_url, icon, link, sort_order) values
  ('suyultirilgan', 'Suyultirilgan gaz', 'Subsidiya narxida, aholi uchun', '#16A34A', null, 'flame',
   'category:suyultirilganGaz', 1),
  ('yetkazish', 'Gaz ballon yetkazish', '35 daqiqada eshigingizga', '#2563EB',
   'asset:assets/images/promo_gas_cylinder.png', 'cylinder', 'category:gazBallon', 2),
  ('elektr', 'Elektr quvvatlash', 'Zaryadlash tarmog‘i kengaymoqda', '#8B5CF6', null, 'bolt', 'services', 3)
on conflict (id) do nothing;

alter table public.promo_banners enable row level security;

-- Boshqa jadvallar kabi demo ishonch modeli: anon kalit o'qiydi va yozadi
-- (admin panel ham anon kalit bilan ishlaydi). Haqiqiy Supabase Auth
-- kelganda yozish faqat admin'ga qoldiriladi.
drop policy if exists "public read promo_banners" on public.promo_banners;
create policy "public read promo_banners" on public.promo_banners
  for select using (true);

drop policy if exists "public write promo_banners" on public.promo_banners;
create policy "public write promo_banners" on public.promo_banners
  for all using (true) with check (true);

notify pgrst, 'reload schema';
