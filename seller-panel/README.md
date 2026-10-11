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

Demo sotuvchi, buyurtmalar va tushumlar olib tashlangan. Mahsulotlar va
sotuvchi holati Supabase'dan olinadi. Panelga `/login` sahifasida kiriladi:
login va parolni admin beradi (admin panel → Sotuvchilar → "Login berish").
Buning uchun Supabase'da bir marta `supabase/seller_login_setup.sql` ishga
tushirilgan bo'lishi kerak. Profilni saqlash va buyurtmalar backend'i hali
ulanmagan; ular bo'sh boshlanadi. Jadvallarning egalikni tekshiruvchi RLS
siyosatlari alohida ish sifatida qoladi.
