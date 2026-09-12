-- Gaz & Energiya — Empty catalog tables, no demo/sample rows.
-- Run this once in Supabase Dashboard → SQL Editor → New query → Run.
-- Safe to re-run (idempotent). Add your own companies/products afterwards
-- via Table Editor, or send their details to Claude to insert for you.

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

-- No seed rows here on purpose — see catalog_setup.sql if you ever want
-- the demo data (Andijon Gaz Ta'minot, Asaka Energiya Servis, …) back for
-- testing.
