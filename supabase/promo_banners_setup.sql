-- Gaz & Energiya — Bosh sahifadagi reklama bannerlari.
--
-- Admin paneldagi "Reklama" bo'limi shu jadvalni boshqaradi, ilova (Bosh
-- sahifa karuseli) undan o'qiydi: faqat is_active = true, sort_order bo'yicha.
-- Jadvalga ulanib bo'lmasa, ilova standart bannerlarni ko'rsatadi.
-- Jadval bo'sh yoki barcha bannerlar o'chirilgan bo'lsa, reklama yashiriladi.
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
