# Gaz & Energiya — Flutter Marketplace

O'zbekiston uchun energiya marketpleysi. Clean Architecture + Feature-Based
tuzilma, Riverpod, GoRouter, mock data bilan **backend'siz to'liq ishga
tushadigan** loyiha.

## Ishga tushirish

```bash
cd gaz_energiya
flutter pub get
flutter run
```

Firebase, xarita yoki to'lov provayderi kalitlari hozircha kerak emas —
ilova to'liq mock data bilan ishlaydi (Map ekrani chizilgan stand-in
ko'rinishda; pastdagi "Xarita" bo'limiga qarang).

## Nima tayyor (ushbu yetkazishda)

- **Arxitektura**: `app/`, `core/`, `features/<name>/{data,domain,presentation}`
  — master promptdagi papka tuzilmasi 1:1.
- **Theme**: ranglar, tipografika, spacing/radius tokenlari, light+dark tema.
- **Routing**: GoRouter, pastki navigatsiya (`StatefulShellRoute`) + to'liq
  ekranli sahifalar (checkout, product detail va h.k.).
- **Qayta ishlatiladigan komponentlar**: AppButton, AppTextField, ProductCard,
  CompanyCard, ServiceCard, MapCompanyCard, PriceRow, OrderStatus(Timeline/Badge),
  BottomNavigation, LoadingSkeleton, EmptyState, ErrorState, CustomDialog,
  RatingWidget, QuantitySelector, AddressCard, PaymentMethodCard.
- **To'liq foydalanuvchi oqimi ishlaydi** (mock data bilan, real navigatsiya):
  Splash → Onboarding → Login/Register → Home → **Elektr quvvatlash** xizmat
  ekrani (rasmda ko'rsatilganidek) → Katalog → Mahsulot tafsiloti →
  Kompaniyalarni solishtirish (5–6 ta) → Yetkazish/O'zim olib ketaman →
  Manzil tanlash → Savat → Checkout → To'lov → Buyurtma tasdiqlandi →
  Live tracking (haydovchi, status timeline, "qo'ng'iroq qilish" tugmasi) →
  Buyurtmalar tarixi (Barchasi/Faol/Yakunlangan) → Profil.
- **Mock data**: 6 ta kompaniya, 5 ta mahsulot, 3 ta buyurtma, 2 ta manzil —
  barchasi realistik UZ narxlar va nomlar bilan.
- **Lokalizatsiya skeleton**: `lib/l10n/app_{uz,ru,en}.arb` + `l10n.yaml`
  (kod-generatsiya uchun `flutter gen-l10n` ishga tushirilishi kerak).

## Keyingi bosqichlar (hali qo'lda bajarilmagan)

Bu — to'liq production ilovaning katta va ishlaydigan skeletoni, lekin
quyidagilar hali **haqiqiy tashqi xizmatlarga ulanmagan** (mock/placeholder
holatda):

1. **Firebase** (Auth, Firestore, Storage, FCM) — hozir `AuthNotifier` va
   barcha repositorylar mock. `firebase_options.dart` generatsiya qilib,
   `main.dart`dagi izohlarni oching.
2. **Xarita** — `MapPage`dagi `_MapCanvas`ni haqiqiy xarita provayderiga
   almashtiring. Yandex MapKit (`yandex_maps_mapkit_lite`) sinab ko'rildi —
   Dart tomoni ishladi, lekin bu Flutter versiyasi (3.44.8) bilan paketning
   Android compileSdk talabi o'rtasida Gradle darajasida ziddiyat chiqdi
   (`flutter_plugin_android_lifecycle` 36+ talab qiladi, plugin 35 bilan
   build qilingan). Keyingi urinishda avval `flutter upgrade` qilib ko'ring
   — odatda shu turdagi mos kelmaslikni yangi Flutter versiyasi hal qiladi.
   "Mening joylashuvim" tugmasi allaqachon haqiqiy GPS bilan ishlaydi
   (`geolocator`, web'da ham) — shuni asos qilib xaritani ulash mumkin.
3. **To'lov provayderi** — `PaymentPage` hozir faqat UI; Payme/Click/Uzcard
   SDK integratsiyasi va tokenizatsiya kerak (xom karta raqami/CVV HECH
   QACHON saqlanmasligi kerak — bu talab kod komментарийларида
   ta'kidlangan).
4. **`.arb` → Dart kod-generatsiyasi**: `flutter gen-l10n` ishga tushiring,
   so'ng UI matnlarini qattiq yozilgan uz satrlardan `AppLocalizations.of(context)`
   ga o'tkazing (hozir barcha matnlar to'g'ridan-to'g'ri o'zbekcha yozilgan,
   lekin arb fayllar RU/EN tarjimalari bilan tayyor).
5. **freezed/json_serializable model klasslari** — hozir entity'lar oddiy
   `Equatable` klasslar; `build_runner` bilan `.g.dart`/`.freezed.dart`
   generatsiyasi keyingi bosqichda qo'shiladi.
6. Push-bildirishnomalar, offline-cache, pagination, va Node.js/NestJS
   REST API migratsiyasi (`core/network/dio_client.dart` allaqachon shu
   migratsiyaga tayyor bo'lgan holda yozilgan).

Loyihani davom ettirish uchun menga ayting — masalan "Firebase Auth qo'sh",
"Google Maps ulash", yoki "keyingi ekranni chuqurroq ishla" — men shu
skeleton ustida davom etib, feature-by-feature to'ldiraman (master
promptdagi PHASE 1–9 tartibida).
