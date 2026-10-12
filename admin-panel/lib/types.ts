export type ServiceCategory =
  | "gazBallon"
  | "suyultirilganGaz"
  | "metanGaz"
  | "propanGaz"
  | "elektrQuvvatlash"
  | "benzin"
  | "dizel"
  | "market";

export const CATEGORY_LABEL: Record<ServiceCategory, string> = {
  gazBallon: "Gaz ballon",
  suyultirilganGaz: "Suyultirilgan gaz",
  metanGaz: "Metan gaz",
  propanGaz: "Propan gaz",
  elektrQuvvatlash: "Elektr quvvatlash",
  benzin: "Benzin",
  dizel: "Dizel",
  market: "Market",
};

export const CATEGORY_COLOR: Record<ServiceCategory, string> = {
  gazBallon: "var(--color-brand)",
  suyultirilganGaz: "var(--color-energy-green)",
  metanGaz: "var(--color-energy-mint)",
  propanGaz: "var(--color-energy-flame)",
  elektrQuvvatlash: "var(--color-energy-electric)",
  benzin: "var(--color-energy-amber)",
  dizel: "var(--color-energy-slate)",
  market: "var(--color-info)",
};

export type ModerationStatus = "pending" | "approved" | "rejected";

export interface Product {
  id: string;
  name: string;
  /** "" — rasm yo'q (panel kategoriya belgisini ko'rsatadi). */
  imageUrl: string;
  images: string[];
  stockQty: number;
  price: number;
  oldPrice?: number;
  rating: number;
  reviewCount: number;
  isAvailable: boolean;
  isPopular: boolean;
  companyId: string;
  companyName: string;
  categoryId: string;
  description: string;
  unit: string;
  moderationStatus: ModerationStatus;
  rejectionReason?: string;
  createdAt: string;
}

export type SellerStatus = "pending" | "approved" | "rejected" | "suspended";

/** Andijon viloyati: viloyat markazi + 14 tuman — ilovadagi ro'yxat bilan bir xil yozilishda. */
export const DISTRICTS = [
  "Andijon shahri",
  "Andijon tumani",
  "Asaka",
  "Baliqchi",
  "Bo‘z",
  "Buloqboshi",
  "Izboskan",
  "Jalaquduq",
  "Marhamat",
  "Oltinko‘l",
  "Paxtaobod",
  "Qo‘rg‘ontepa",
  "Shahrixon",
  "Ulug‘nor",
  "Xo‘jaobod",
] as const;

export interface Seller {
  id: string;
  companyName: string;
  ownerName: string;
  category: ServiceCategory;
  district: string;
  address: string;
  phone: string;
  status: SellerStatus;
  createdAt: string;
  rating: number;
  reviewCount: number;
  productCount: number;
}

export type OrderStatus =
  | "qabulQilindi"
  | "tayyorlanmoqda"
  | "yolda"
  | "yetkazildi"
  | "bekorQilindi";

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  qabulQilindi: "Qabul qilindi",
  tayyorlanmoqda: "Tayyorlanmoqda",
  yolda: "Yo'lda",
  yetkazildi: "Yetkazildi",
  bekorQilindi: "Bekor qilindi",
};

export interface OrderItem {
  productName: string;
  quantity: number;
  price: number;
}

export interface Order {
  id: string;
  orderNumber: string;
  date: string;
  buyerName: string;
  buyerPhone: string;
  companyId: string;
  companyName: string;
  items: OrderItem[];
  total: number;
  deliveryFee: number;
  paymentMethod?: string;
  status: OrderStatus;
  address: string;
}
