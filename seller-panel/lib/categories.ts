import {
  Cylinder,
  Flame,
  Fuel,
  Package,
  Tag,
  Truck,
  Wrench,
  Zap,
  type LucideIcon,
} from "lucide-react";

// Mahsulot kategoriyalari — Supabase `product_categories` (marketplace_setup.sql).
// Umumiylarini admin boshqaradi (sellerId = null), sotuvchi o'zinikini qo'shadi.

export interface ProductCategory {
  id: string;
  label: string;
  icon: string;
  /** null — platforma kategoriyasi (admin boshqaradi). */
  sellerId: string | null;
  sortOrder: number;
  isActive: boolean;
}

export const CATEGORY_ICONS: Record<string, LucideIcon> = {
  cylinder: Cylinder,
  fuel: Fuel,
  wrench: Wrench,
  flame: Flame,
  zap: Zap,
  truck: Truck,
  package: Package,
  tag: Tag,
};

/** Jadval hali yo'q bo'lsa ham forma ishlashi uchun — SQL'dagi boshlang'ich qatorlar. */
export const DEFAULT_CATEGORIES: ProductCategory[] = [
  { id: "gazBallon", label: "Yangi gaz ballon", icon: "cylinder", sellerId: null, sortOrder: 1, isActive: true },
  { id: "gazToldirish", label: "Gaz ballon to'ldirish", icon: "fuel", sellerId: null, sortOrder: 2, isActive: true },
  { id: "gazTamirlash", label: "Gaz ta'mirlash", icon: "wrench", sellerId: null, sortOrder: 3, isActive: true },
];

const PALETTE = [
  "var(--color-brand)",
  "var(--color-energy-green)",
  "var(--color-energy-flame)",
  "var(--color-energy-electric)",
  "var(--color-info)",
  "var(--color-energy-amber)",
  "var(--color-energy-mint)",
];

const FIXED_COLOR: Record<string, string> = {
  gazBallon: "var(--color-brand)",
  gazToldirish: "var(--color-energy-green)",
  gazTamirlash: "var(--color-energy-flame)",
};

/** Har bir kategoriyaga doim bir xil rang (id bo'yicha). */
export function categoryColor(id: string): string {
  if (FIXED_COLOR[id]) return FIXED_COLOR[id];
  let hash = 0;
  for (const ch of id) hash = (hash * 31 + ch.charCodeAt(0)) | 0;
  return PALETTE[Math.abs(hash) % PALETTE.length];
}

/** Ro'yxatda bo'lmagan id (eski erkin matnli kategoriya) — id'ning o'zi nom bo'ladi. */
export function categoryLabel(id: string, categories: ProductCategory[]): string {
  return categories.find((c) => c.id === id)?.label ?? id;
}

const sameText = (a: string) => a.trim().toLowerCase().replace(/[‘’ʻʼ`]/g, "'").replace(/\s+/g, " ");

export function sameLabel(a: string, b: string) {
  return sameText(a) === sameText(b);
}

/** "  gaz  plita " → "Gaz plita". */
export function cleanLabel(raw: string): string {
  const label = raw.trim().replace(/\s+/g, " ");
  return label.charAt(0).toUpperCase() + label.slice(1);
}
