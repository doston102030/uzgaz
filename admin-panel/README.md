# Gaz & Energiya — Admin panel

Andijon viloyati gaz va energiya marketpleysi uchun **boshqaruv paneli** —
asosiy Flutter ilovadan mustaqil, alohida Next.js loyihasi.

## Ishga tushirish

```bash
cd admin-panel
npm install
npm run dev
```

`http://localhost:3000` da ochiladi (yoki `npm run dev -- -p 4410` bilan
boshqa portda).

## Nima bor

- **Bosh sahifa** — KPI kartalar, tushum grafigi, tasdiqlash kutayotganlar, so'nggi buyurtmalar.
- **Sotuvchilar** — arizalar (tasdiqlash/rad etish), qo'shish, tahrirlash, to'xtatish, o'chirish,
  seller panelga login/parol berish.
- **Mahsulotlar** — moderatsiya: tasdiqlash, sababi bilan rad etish, sotuvdan olish, batafsil ko'rish.
- **Kategoriyalar** — umumiy kategoriyalar (qo'shish, nomi/belgisini tahrirlash, tartib, yashirish)
  va sotuvchilarning o'z kategoriyalari (umumiyga aylantirish).
- **Buyurtmalar** — barcha buyurtmalar, filtr, qidiruv, tafsilot, nizoli buyurtmani bekor qilish.
- **Tizim** — qaysi `supabase/*.sql` fayllari bazada ishga tushirilgani, platforma ko'rsatkichlari.

Topbar'dagi qo'ng'iroqcha — yangi arizalar, moderatsiya va qabul qilinmagan buyurtmalar soni.
Telefon/planshetda menyu chap tomondan ochiladi.

## Holati

Ma'lumotlar Supabase'da (`.env.local` — `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`).
Kerakli SQL fayllar: `seller_workflow_setup.sql`, `seller_login_setup.sql`,
`marketplace_setup.sql` (yoki hammasi bir faylda — `all_setup.sql`). Holatini **Tizim** sahifasi ko'rsatadi.

Admin panelga kirish paroli hali yo'q va jadvallar umumiy (anon) kalit bilan yoziladi — sinov
bosqichi uchun. Haqiqiy foydalanuvchilardan oldin Supabase Auth va RLS siyosatlari kerak.
