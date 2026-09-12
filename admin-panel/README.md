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
- **Kompaniyalar** — barcha ro'yxatdan o'tgan kompaniyalar, faollashtirish/to'xtatish.
- **Mahsulotlar** — moderatsiya navbati (kutilmoqda/faol/rad etilgan), tasdiqlash/rad etish.
- **Sotuvchilar** — yangi arizalar, tasdiqlash/rad etish/to'xtatish.
- **Buyurtmalar** — barcha kompaniyalar bo'yicha buyurtmalar, filtr va qidiruv.
- **Sozlamalar** — platforma sozlamalari (namunaviy).

## Holati

Hozircha **namunaviy (mock) ma'lumotlar** bilan ishlaydi (`lib/mock-data.ts`) —
Andijon shahri va tumanlari bo'yicha realistik kompaniya/mahsulot/sotuvchi/
buyurtma namunalari. Supabase bazasiga hali ulanmagan — bu keyingi bosqich
(haqiqiy yozish huquqi uchun admin autentifikatsiyasi va RLS siyosatlari
kerak bo'ladi).
