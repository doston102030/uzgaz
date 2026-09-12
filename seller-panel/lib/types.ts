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

export interface SellerProfile {
  companyName: string;
  ownerName: string;
  category: ServiceCategory;
  description: string;
  address: string;
  district: string;
  phone: string;
  workingHours: string;
  deliveryFee: number;
  rating: number;
  reviewCount: number;
  createdAt: string;
}

export type ModerationStatus = "pending" | "approved" | "rejected";

export interface SellerProduct {
  id: string;
  name: string;
  imageUrl: string;
  categoryId: ServiceCategory;
  description: string;
  price: number;
  oldPrice?: number;
  unit: string;
  stockQty: number;
  moderationStatus: ModerationStatus;
  rejectionReason?: string;
  createdAt: string;
}

export type SellerOrderStatus =
  | "yangi"
  | "tayyorlanmoqda"
  | "yetkazishga"
  | "yopildi"
  | "bekorQilindi";

export const SELLER_ORDER_STATUS_LABEL: Record<SellerOrderStatus, string> = {
  yangi: "Yangi",
  tayyorlanmoqda: "Tayyorlanmoqda",
  yetkazishga: "Yetkazishga tayyor",
  yopildi: "Yopildi",
  bekorQilindi: "Bekor qilindi",
};

export const SELLER_ORDER_FLOW: SellerOrderStatus[] = [
  "yangi",
  "tayyorlanmoqda",
  "yetkazishga",
  "yopildi",
];

export interface SellerOrderItem {
  productName: string;
  quantity: number;
  price: number;
}

export interface SellerOrder {
  id: string;
  orderNumber: string;
  buyerName: string;
  buyerPhone: string;
  items: SellerOrderItem[];
  total: number;
  status: SellerOrderStatus;
  deliveryMethod: "delivery" | "selfPickup";
  address?: string;
  placedAt: string;
}
