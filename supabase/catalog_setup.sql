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
