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
