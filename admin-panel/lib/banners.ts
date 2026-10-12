import { CATEGORY_LABEL } from "./types";

export const BANNER_ICONS = { flame: "Olov", cylinder: "Ballon", bolt: "Elektr", truck: "Yetkazish", tag: "Aksiya" } as const;
export type BannerIcon = keyof typeof BANNER_ICONS;
export const BUNDLED_BANNER_IMAGE = "asset:assets/images/promo_gas_cylinder.png";

export interface PromoBanner {
  id: string;
  title: string;
  caption: string;
  accent: string;
  imageUrl: string | null;
  icon: BannerIcon;
  link: string;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
}

export type BannerInput = Omit<PromoBanner, "id" | "createdAt">;

export function isWebUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return /^https?:$/.test(url.protocol) && !!url.hostname && !url.username && !url.password;
  } catch {
    return false;
  }
}

export function bannerLinkLabel(link: string): string {
  if (!link) return "Havolasiz";
  if (link === "services") return "Xizmatlar";
  if (link.startsWith("category:")) {
    return CATEGORY_LABEL[link.slice(9) as keyof typeof CATEGORY_LABEL] ?? "Noma'lum kategoriya";
  }
  return link.startsWith("url:") ? link.slice(4) : "Noma'lum havola";
}

/** Keep invalid links/images out of the app's carousel, even outside the form. */
export function cleanBanner(input: BannerInput): BannerInput {
  const title = input.title.trim();
  const caption = input.caption.trim();
  const link = input.link.trim();
  const imageUrl = input.imageUrl?.trim() || null;
  if (!title || [...title].length > 60) throw new Error("Sarlavha 1–60 belgidan iborat bo'lsin.");
  if ([...caption].length > 90) throw new Error("Izoh 90 belgidan oshmasin.");
  if (!/^#[0-9a-f]{6}$/i.test(input.accent)) throw new Error("Rangni #RRGGBB shaklida kiriting.");
  if (!(input.icon in BANNER_ICONS)) throw new Error("Banner belgisini tanlang.");
  if (!Number.isSafeInteger(input.sortOrder) || input.sortOrder < 0 || input.sortOrder > 2147483647) {
    throw new Error("Tartib 0 dan 2147483647 gacha butun son bo'lsin.");
  }
  const category = link.startsWith("category:") && Object.hasOwn(CATEGORY_LABEL, link.slice(9));
  if (link && link !== "services" && !category && !(link.startsWith("url:") && isWebUrl(link.slice(4)))) {
    throw new Error("Havola to'g'ri http:// yoki https:// manzil bo'lsin (login va parolsiz).");
  }
  if (imageUrl && imageUrl !== BUNDLED_BANNER_IMAGE && !isWebUrl(imageUrl)) {
    throw new Error("Rasm uchun http:// yoki https:// manzil kiriting, yoki fayl yuklang.");
  }
  return { ...input, title, caption, link, imageUrl };
}
