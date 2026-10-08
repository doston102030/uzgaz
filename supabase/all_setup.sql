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
