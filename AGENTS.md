# Gaz & Energiya — agentlar uchun ko'rsatma

Bu loyihada bir vaqtda bir nechta agent ishlaydi. Fayl to'qnashuvining
oldini olish uchun quyidagi tartibga rioya qiling.

## Birinchi qadam

**`TEAM_CHAT.md` faylini o'qing.** Unda kim nima qilayotgani, ish taqsimoti,
ochiq muammolar va oxirgi holat yozilgan. Ish boshlashdan oldin o'sha yerga
nima qilmoqchi ekanligingizni qo'shing, tugagach — natijani yozing.

## Ish taqsimoti

| Agent | Hududi |
|---|---|
| Codex | `lib/features/map/**`, `pubspec.yaml`, `android/**` |
| Claude (dizayn) | `lib/core/**`, `lib/features/**` (map'dan tashqari) |
| Claude (tekshiruvchi) | kod yozmaydi — serverlarni yuritadi va sinaydi |

O'z hududingizdan tashqariga chiqmang. Kerak bo'lsa `TEAM_CHAT.md` orqali so'rang.

**Umumiy fayl:** `lib/app/router/app_router.dart` — xarita marshruti shu yerda.
Tegishdan oldin chatga yozing.

## Loyiha haqida

Flutter marketplace (Clean Architecture, Riverpod, GoRouter) + ikkita Next.js
paneli (`admin-panel/`, `seller-panel/`). Ma'lumotlar Supabase'da; panellarning
kalitlari `.env.local` da (commit qilinmaydi).

Ishlab turgan serverlar: Flutter ilova Chrome'da, admin `:3000`, seller `:3001`.
Ularni qayta ishga tushirmang — allaqachon ishlayapti.

## Qoidalar

- Interfeys matni **o'zbek tilida** (loyihaning qolgan qismi shunday)
- Kod izohlari va commit xabarlari — atrofdagi uslubga mos
- `.env.local` fayllarini commit qilmang
- Katta o'zgarishdan oldin `git status` ni tekshiring — boshqa agent ishlayotgan bo'lishi mumkin
