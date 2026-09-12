# Gaz & Energiya — Sotuvchi panel

Andijon viloyati gaz va energiya marketpleysida **sotuvchi kabineti** —
asosiy Flutter ilovadan va admin paneldan mustaqil, alohida Next.js loyihasi.

## Ishga tushirish

```bash
cd seller-panel
npm install
npm run dev
```

`http://localhost:3000` da ochiladi (yoki `npm run dev -- -p 4420` bilan
boshqa portda).

## Nima bor

- **Bosh sahifa** — sotuvchining o'z ko'rsatkichlari, tushum grafigi, so'nggi buyurtmalar.
- **Mahsulotlarim** — mahsulotlar ro'yxati, yangi mahsulot qo'shish (moderatsiyaga yuboriladi), o'chirish.
- **Buyurtmalar** — kelgan buyurtmalarni holatdan-holatga o'tkazish (Yangi → Tayyorlanmoqda → Yetkazishga tayyor → Yopildi) yoki bekor qilish.
- **Hisobotlar** — 30 kunlik tushum grafigi, eng ko'p sotilgan mahsulotlar.
- **Profil** — kompaniya ma'lumotlari va sozlamalar.

## Holati

Hozircha **namunaviy (mock) ma'lumotlar** bilan ishlaydi (`lib/mock-data.ts`) —
"Andijon Gaz Ta'minot" nomli namunaviy sotuvchi hisobi bilan. Supabase
bazasiga hali ulanmagan — bu keyingi bosqich (sotuvchi autentifikatsiyasi
va faqat o'z mahsulot/buyurtmalariga yozish huquqini beruvchi RLS
siyosatlari kerak bo'ladi).
