import { SellerOrder, SellerProduct, SellerProfile } from "./types";

export const profile: SellerProfile = {
  companyName: "Andijon Gaz Ta'minot",
  ownerName: "Sherzod Yo'ldoshev",
  category: "gazBallon",
  description:
    "50 va 25 litrlik gaz ballonlari, tez yetkazib berish bilan — Andijon shahri va yaqin tumanlar bo'ylab.",
  address: "Bobur shoh ko'chasi 108",
  district: "Andijon shahri",
  phone: "+998 74 225 10 10",
  workingHours: "08:00 - 22:00",
  deliveryFee: 15000,
  rating: 4.8,
  reviewCount: 214,
  createdAt: "2024-02-11",
};

// Demo mahsulotlar tozalandi — real mahsulotlaringizni (rasmlari bilan) shu yerdan qo'shasiz.
export const products: SellerProduct[] = [];

export const orders: SellerOrder[] = [
  {
    id: "so1",
    orderNumber: "#GE234701",
    buyerName: "Nodira Yusupova",
    buyerPhone: "+998 90 111 22 33",
    items: [{ productName: "Gaz ballon 50L", quantity: 1, price: 120000 }],
    total: 135000,
    status: "yangi",
    deliveryMethod: "delivery",
    address: "Andijon shahri, Bog'ishamol ko'chasi 12",
    placedAt: "2025-09-12T15:50:00",
  },
  {
    id: "so2",
    orderNumber: "#GE234690",
    buyerName: "Aziz Karimov",
    buyerPhone: "+998 93 333 44 55",
    items: [{ productName: "Gaz ballon 25L", quantity: 2, price: 76000 }],
    total: 152000,
    status: "tayyorlanmoqda",
    deliveryMethod: "delivery",
    address: "Andijon tumani, 12-mavze",
    placedAt: "2025-09-12T14:38:00",
  },
  {
    id: "so3",
    orderNumber: "#GE234655",
    buyerName: "Malika Tosheva",
    buyerPhone: "+998 97 123 45 67",
    items: [{ productName: "Gaz ballon 50L", quantity: 1, price: 120000 }],
    total: 120000,
    status: "yetkazishga",
    deliveryMethod: "selfPickup",
    placedAt: "2025-09-12T12:10:00",
  },
  {
    id: "so4",
    orderNumber: "#GE234512",
    buyerName: "Bekzod Rashidov",
    buyerPhone: "+998 90 999 88 77",
    items: [{ productName: "Gaz ballon 25L", quantity: 3, price: 76000 }],
    total: 228000,
    status: "yopildi",
    deliveryMethod: "delivery",
    address: "Shahrixon tumani, 19-kvartal",
    placedAt: "2025-09-11T13:20:00",
  },
  {
    id: "so5",
    orderNumber: "#GE234488",
    buyerName: "Shahnoza Alieva",
    buyerPhone: "+998 95 555 66 77",
    items: [{ productName: "Gaz ballon 50L", quantity: 2, price: 120000 }],
    total: 240000,
    status: "yopildi",
    deliveryMethod: "selfPickup",
    placedAt: "2025-09-09T09:00:00",
  },
  {
    id: "so6",
    orderNumber: "#GE234290",
    buyerName: "Umid Sattorov",
    buyerPhone: "+998 91 222 11 00",
    items: [{ productName: "Benzin AI-95", quantity: 40, price: 12500 }],
    total: 500000,
    status: "bekorQilindi",
    deliveryMethod: "delivery",
    address: "Asaka tumani, Mustaqillik ko'chasi 24",
    placedAt: "2025-09-07T17:45:00",
  },
];

export function revenueByDay(days = 14) {
  const out: { date: string; revenue: number }[] = [];
  const base = new Date("2025-09-12");
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(base);
    d.setDate(d.getDate() - i);
    const seed = d.getDate() + d.getMonth() * 3;
    const revenue = 320_000 + ((seed * 211) % 480_000);
    const pad = (n: number) => (n < 10 ? `0${n}` : String(n));
    out.push({ date: `${pad(d.getDate())}.${pad(d.getMonth() + 1)}`, revenue });
  }
  return out;
}
