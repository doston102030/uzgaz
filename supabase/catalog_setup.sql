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

-- ── seed: companies ────────────────────────────────────────────────
insert into public.companies
  (id, name, rating, review_count, distance_km, product_price, delivery_fee, eta_minutes,
   working_hours, is_available, latitude, longitude, address, phone, tags)
values
  ('c1','UzGaz Servis',4.8,214,1.2,120000,15000,35,'08:00 - 22:00',true,41.3111,69.2797,
   'Yunusobod tumani, Amir Temur shoh ko‘chasi 108','+998712001010',array['Sertifikatlangan','Tez yetkazish']),
  ('c2','Mega Gaz',4.6,158,2.4,118000,12000,45,'09:00 - 21:00',true,41.3021,69.2650,
   'Mirobod tumani, Nukus ko‘chasi 24','+998712002020',array['Ommabop']),
  ('c3','Ali Gaz',4.5,97,3.1,115000,10000,50,'24/7',true,41.2856,69.2034,
   'Chilonzor tumani, Bunyodkor shoh ko‘chasi 12','+998712003030',array['24/7']),
  ('c4','Bukhara Gaz',4.7,132,4.0,121000,18000,55,'08:00 - 20:00',false,41.3268,69.2287,
   'Shayxontohur tumani, Navoiy ko‘chasi 45','+998712004040',array[]::text[]),
  ('c5','Sanoat Gaz',4.4,76,2.9,117000,14000,40,'08:00 - 23:00',true,41.2995,69.2401,
   'Yakkasaroy tumani, Shota Rustaveli ko‘chasi 7','+998712005050',array[]::text[]),
  ('c6','GazPlus',4.9,301,1.8,125000,0,30,'24/7',true,41.3155,69.2503,
   'Mirzo Ulug‘bek tumani, Buyuk Ipak Yo‘li 61','+998712006060',array['Yetkazish bepul','24/7'])
on conflict (id) do update set
  name = excluded.name, rating = excluded.rating, review_count = excluded.review_count,
  distance_km = excluded.distance_km, product_price = excluded.product_price,
  delivery_fee = excluded.delivery_fee, eta_minutes = excluded.eta_minutes,
  working_hours = excluded.working_hours, is_available = excluded.is_available,
  latitude = excluded.latitude, longitude = excluded.longitude, address = excluded.address,
  phone = excluded.phone, tags = excluded.tags;

-- ── seed: products ─────────────────────────────────────────────────
-- image_url points at the real photos already uploaded to the
-- `product-images` Storage bucket (see storage_setup.sql).
insert into public.products
  (id, name, image_url, price, old_price, rating, review_count, is_available, is_popular,
   company_id, company_name, category_id, description, unit, specs)
values
  ('p1','Gaz ballon 50L',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/gazBallon.jpg',
   120000,135000,4.8,214,true,true,'c1','UzGaz Servis','gazBallon',
   '50 litrlik po‘lat gaz ballon — uy xo‘jaligi va kichik tijorat uchun. Har bir ballon to‘ldirishdan oldin bosim va zichlik bo‘yicha tekshiriladi.',
   'dona','{"Hajm":"50 litr","Og‘irligi":"22 kg","Material":"Po‘lat","Sertifikat":"O‘z DSt 1234"}'),
  ('p2','Gaz ballon 25L',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/gazBallon.jpg',
   76000,null,4.6,143,true,true,'c2','Mega Gaz','gazBallon',
   'Kichik uy xo‘jaligi uchun qulay 25 litrlik ballon. Yengil, ko‘chirish oson.',
   'dona','{"Hajm":"25 litr","Og‘irligi":"12 kg","Material":"Po‘lat"}'),
  ('p3','Propan ballon 27L',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/propanGaz.jpg',
   62000,null,4.3,58,true,false,'c3','Ali Gaz','propanGaz',
   'Yuqori tozalikdagi suyultirilgan propan gazi, isitish va pishirish uchun.',
   'dona','{"Hajm":"27 litr","Tozaligi":"98,5%"}'),
  ('p4','Metan gaz (CNG)',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/metanGaz.jpg',
   45000,null,4.5,89,false,false,'c5','Sanoat Gaz','metanGaz',
   'Avtomobillar uchun siqilgan tabiiy gaz. Stansiyada to‘ldirish.',
   'm³','{"Bosim":"200 bar","Turi":"CNG"}'),
  ('p5','Suyultirilgan gaz',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/suyultirilganGaz.jpg',
   133000,149000,4.9,301,true,true,'c6','GazPlus','suyultirilganGaz',
   'Aholi uchun subsidiya narxidagi suyultirilgan gaz. Miqdor cheklangan, buyurtma tasdiqlangach 24 soat ichida yetkaziladi.',
   'dona','{"Hajm":"50 litr","Toifa":"Aholi uchun"}'),
  ('p6','Elektr quvvatlash — 60 kVt',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/elektrQuvvatlash.jpg',
   1200,null,4.7,126,true,false,'c6','GazPlus Energy','elektrQuvvatlash',
   'Tezkor DC quvvatlash stansiyasi. 30 daqiqada 80% zaryad.',
   'kVt·s','{"Quvvat":"60 kVt","Konnektor":"CCS2 / GB/T"}'),
  ('p7','Benzin AI-95',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/benzin.jpg',
   12500,null,4.6,412,true,true,'c1','UzGaz Servis','benzin',
   'Yevro-5 standartidagi AI-95 benzini.',
   'litr','{"Oktan soni":"95","Standart":"Yevro-5"}'),
  ('p8','Benzin AI-92',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/benzin.jpg',
   11200,null,4.4,268,true,false,'c2','Mega Gaz','benzin',
   'Kundalik foydalanish uchun AI-92 benzini.',
   'litr','{"Oktan soni":"92","Standart":"Yevro-4"}'),
  ('p9','Dizel Yevro-5',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/dizel.jpg',
   13800,null,4.5,174,true,false,'c5','Sanoat Gaz','dizel',
   'Past oltingugurtli Yevro-5 dizel yoqilg‘isi.',
   'litr','{"Standart":"Yevro-5","Oltingugurt":"10 ppm"}'),
  ('p10','Motor moyi 4L',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/market.jpg',
   285000,320000,4.7,63,true,false,'c4','Bukhara Gaz','market',
   'Sintetik motor moyi 5W-40, 4 litrlik idishda.',
   'dona','{"Hajm":"4 litr","Turi":"5W-40 sintetik"}'),
  ('p11','Gaz reduktori',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/market.jpg',
   95000,null,4.2,41,true,false,'c3','Ali Gaz','market',
   'Ballon uchun bosim reduktori, manometr bilan.',
   'dona','{"Chiqish bosimi":"30 mbar"}'),
  ('p12','Propan ballon 12L',
   'https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog/propanGaz.jpg',
   38000,null,4.1,27,true,false,'c2','Mega Gaz','propanGaz',
   'Sayohat va dala sharoiti uchun ixcham propan ballon.',
   'dona','{"Hajm":"12 litr","Og‘irligi":"7 kg"}')
on conflict (id) do update set
  name = excluded.name, image_url = excluded.image_url, price = excluded.price,
  old_price = excluded.old_price, rating = excluded.rating, review_count = excluded.review_count,
  is_available = excluded.is_available, is_popular = excluded.is_popular,
  company_id = excluded.company_id, company_name = excluded.company_name,
  category_id = excluded.category_id, description = excluded.description,
  unit = excluded.unit, specs = excluded.specs;
