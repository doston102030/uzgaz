import { supabase } from "./supabase";
import { ProductCategory } from "./categories";
import { BannerInput, cleanBanner, PromoBanner } from "./banners";
import {
  ModerationStatus,
  Order,
  OrderStatus,
  Product,
  Seller,
  SellerStatus,
  ServiceCategory,
} from "./types";

// ── Sellers ────────────────────────────────────────────────────────

interface SellerRow {
  id: string;
  company_name: string;
  owner_name: string;
  category: string;
  district: string;
  address: string;
  phone: string;
  status: string;
  rating: number;
  review_count: number;
  created_at: string;
}

function sellerFromRow(row: SellerRow): Seller {
  return {
    id: row.id,
    companyName: row.company_name,
    ownerName: row.owner_name,
    category: row.category as ServiceCategory,
    district: row.district,
    address: row.address,
    phone: row.phone,
    status: row.status as SellerStatus,
    createdAt: row.created_at,
    rating: row.rating,
    reviewCount: row.review_count,
    productCount: 0,
  };
}

export async function fetchSellers(): Promise<Seller[]> {
  const { data, error } = await supabase
    .from("sellers")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data as SellerRow[]).map(sellerFromRow);
}

export async function updateSellerStatus(id: string, status: SellerStatus) {
  const { error } = await supabase.from("sellers").update({ status }).eq("id", id);
  if (error) throw error;
}

export interface NewSeller {
  companyName: string;
  ownerName: string;
  category: ServiceCategory;
  district: string;
  address: string;
  phone: string;
  status: SellerStatus;
}

/** Admin adds a company directly — same row shape the app's application form writes. */
export async function createSeller(input: NewSeller): Promise<Seller> {
  const { data, error } = await supabase
    .from("sellers")
    .insert({
      id: `s${Date.now()}`,
      company_name: input.companyName,
      owner_name: input.ownerName,
      category: input.category,
      district: input.district,
      address: input.address,
      phone: input.phone,
      status: input.status,
    })
    .select()
    .single();
  if (error) throw error;
  return sellerFromRow(data as SellerRow);
}

/** Admin edits a company's details (status has its own buttons). */
export async function updateSeller(id: string, input: Omit<NewSeller, "status">): Promise<Seller> {
  const { data, error } = await supabase
    .from("sellers")
    .update({
      company_name: input.companyName,
      owner_name: input.ownerName,
      category: input.category,
      district: input.district,
      address: input.address,
      phone: input.phone,
    })
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return sellerFromRow(data as SellerRow);
}

/**
 * Removes a company for good. With marketplace_setup.sql the database also
 * drops its company row, products and own categories; its login goes with
 * it (cascade). Past orders stay, unlinked.
 */
export async function deleteSeller(id: string) {
  const { error } = await supabase.from("sellers").delete().eq("id", id);
  if (error) throw error;
}

// ── Seller logins (supabase/seller_login_setup.sql) ───────────────

export const LOGIN_SETUP_HINT =
  "Supabase'da login funksiyalari hali yo'q — supabase/seller_login_setup.sql faylini SQL Editor'da bir marta ishga tushiring.";

const LOGIN_ERRORS: Record<string, string> = {
  login_taken: "Bu login band — boshqasini tanlang.",
  login_invalid: "Login 3–32 belgi bo'lsin: lotin harflari, raqam, nuqta, chiziqcha.",
  password_too_short: "Parol kamida 6 belgidan iborat bo'lsin.",
  seller_not_found: "Sotuvchi topilmadi — ro'yxatni yangilang.",
};

function loginError(error: { code?: string; message: string }): Error {
  // PGRST202 / 42883: function missing, 42P01: table missing — the SQL wasn't run.
  if (error.code === "PGRST202" || error.code === "42883" || error.code === "42P01") {
    return new Error(LOGIN_SETUP_HINT);
  }
  if (error.code === "23505") return new Error(LOGIN_ERRORS.login_taken);
  return new Error(LOGIN_ERRORS[error.message] ?? error.message);
}

/** Seller id → login, for the sellers that already have one. */
export async function fetchSellerLogins(): Promise<Record<string, string>> {
  const { data, error } = await supabase.rpc("seller_logins");
  if (error) throw loginError(error);
  const map: Record<string, string> = {};
  for (const row of data as { seller_id: string; login: string }[]) map[row.seller_id] = row.login;
  return map;
}

/** Gives a seller a login, or replaces it; a new password signs the seller out everywhere. */
export async function setSellerLogin(sellerId: string, login: string, password: string) {
  const { error } = await supabase.rpc("set_seller_login", {
    p_seller_id: sellerId,
    p_login: login,
    p_password: password,
  });
  if (error) throw loginError(error);
}

// ── Products (moderation) ─────────────────────────────────────────

interface ProductRow {
  id: string;
  name: string;
  image_url: string;
  price: number;
  old_price: number | null;
  rating: number;
  review_count: number;
  is_available: boolean;
  is_popular: boolean;
  company_id: string | null;
  company_name: string;
  category_id: string;
  description: string | null;
  unit: string;
  images: string[] | null;
  stock_qty: number | null;
  moderation_status: string;
  rejection_reason: string | null;
  created_at: string;
}

// The old "default photo" URLs were never uploaded (400) — treat as no photo.
const isRealImage = (url: string | null | undefined): url is string =>
  !!url && !url.includes("/product-images/catalog/");

function productFromRow(row: ProductRow): Product {
  const images = (row.images ?? []).filter(isRealImage);
  const main = isRealImage(row.image_url) ? row.image_url : (images[0] ?? "");
  return {
    id: row.id,
    name: row.name,
    imageUrl: main,
    images: images.length > 0 ? images : main ? [main] : [],
    stockQty: row.stock_qty ?? 0,
    price: row.price,
    oldPrice: row.old_price ?? undefined,
    rating: row.rating,
    reviewCount: row.review_count,
    isAvailable: row.is_available,
    isPopular: row.is_popular,
    companyId: row.company_id ?? "",
    companyName: row.company_name,
    categoryId: row.category_id,
    description: row.description ?? "",
    unit: row.unit,
    moderationStatus: row.moderation_status as ModerationStatus,
    rejectionReason: row.rejection_reason ?? undefined,
    createdAt: row.created_at,
  };
}

export async function fetchProducts(): Promise<Product[]> {
  const { data, error } = await supabase
    .from("products")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data as ProductRow[]).map(productFromRow);
}

export async function updateProductModeration(
  id: string,
  moderationStatus: ModerationStatus,
  rejectionReason?: string,
) {
  const { error } = await supabase
    .from("products")
    .update({ moderation_status: moderationStatus, rejection_reason: rejectionReason ?? null })
    .eq("id", id);
  if (error) throw error;
}

/** Rasmlar ro'yxatini almashtiradi (birinchisi — asosiy). Moderatsiya holatiga tegmaydi. */
export async function updateProductImages(id: string, images: string[]) {
  const { error } = await supabase
    .from("products")
    .update({ image_url: images[0] ?? "", images: images.length > 0 ? images : null })
    .eq("id", id);
  if (error) throw error;
}

export async function deleteProduct(id: string) {
  const { error } = await supabase.from("products").delete().eq("id", id);
  if (error) throw error;
}

// ── Orders (supabase/marketplace_setup.sql) ───────────────────────

export const ORDERS_SETUP_HINT =
  "Supabase'da buyurtmalar jadvali hali yo'q — supabase/marketplace_setup.sql faylini SQL Editor'da bir marta ishga tushiring.";

interface OrderRow {
  id: string;
  order_number: string;
  company_id: string | null;
  company_name: string;
  buyer_name: string;
  buyer_phone: string;
  delivery_method: "delivery" | "selfPickup";
  address: string | null;
  items: { name: string; quantity: number; price: number }[];
  delivery_fee: number;
  total: number;
  status: OrderStatus;
  created_at: string;
}

function orderFromRow(row: OrderRow): Order {
  return {
    id: row.id,
    orderNumber: row.order_number,
    date: row.created_at,
    buyerName: row.buyer_name || "Mehmon",
    buyerPhone: row.buyer_phone,
    companyId: row.company_id ?? "",
    companyName: row.company_name,
    items: (row.items ?? []).map((i) => ({ productName: i.name, quantity: i.quantity, price: i.price })),
    total: row.total,
    deliveryFee: row.delivery_fee,
    status: row.status,
    address: row.delivery_method === "selfPickup" ? "O'zi olib ketadi" : (row.address ?? ""),
  };
}

export async function fetchOrders(): Promise<Order[]> {
  const { data, error } = await supabase
    .from("orders")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) {
    // PGRST205 / 42P01: the table doesn't exist yet — the SQL wasn't run.
    if (error.code === "PGRST205" || error.code === "42P01") throw new Error(ORDERS_SETUP_HINT);
    throw error;
  }
  return (data as OrderRow[]).map(orderFromRow);
}

/** Admin override — e.g. cancelling a disputed order. */
export async function updateOrderStatus(id: string, status: OrderStatus) {
  const { error } = await supabase.from("orders").update({ status }).eq("id", id);
  if (error) throw error;
}

// ── Categories (product_categories, marketplace_setup.sql) ────────

export const CATEGORIES_SETUP_HINT =
  "Kategoriyalar jadvali hali yo'q — supabase/marketplace_setup.sql faylini SQL Editor'da bir marta ishga tushiring.";

interface CategoryRow {
  id: string;
  label: string;
  icon: string;
  seller_id: string | null;
  sort_order: number;
  is_active: boolean;
}

const CATEGORY_COLUMNS = "id, label, icon, seller_id, sort_order, is_active";

function categoryFromRow(row: CategoryRow): ProductCategory {
  return {
    id: row.id,
    label: row.label,
    icon: row.icon,
    sellerId: row.seller_id,
    sortOrder: row.sort_order,
    isActive: row.is_active,
  };
}

const isMissing = (error: { code?: string }) =>
  error.code === "PGRST205" || error.code === "42P01" || error.code === "PGRST202";

function categoryError(error: { code?: string; message: string }): Error {
  if (error.code === "23505") return new Error("Bu nomli kategoriya allaqachon bor.");
  if (error.code === "23514") return new Error("Kategoriya nomi 1–40 belgi bo'lsin.");
  if (isMissing(error)) return new Error(CATEGORIES_SETUP_HINT);
  return new Error(error.message);
}

/** Every category — platform ones first, then sellers' own. `ready: false` = no table yet. */
export async function fetchCategories(): Promise<{ categories: ProductCategory[]; ready: boolean }> {
  const { data, error } = await supabase
    .from("product_categories")
    .select(CATEGORY_COLUMNS)
    .order("sort_order")
    .order("created_at");
  if (error) {
    if (isMissing(error)) return { categories: [], ready: false };
    throw error;
  }
  return { categories: (data as CategoryRow[]).map(categoryFromRow), ready: true };
}

export async function createCategory(input: { label: string; icon: string; sortOrder: number }) {
  const { data, error } = await supabase
    .from("product_categories")
    .insert({ id: `c${Date.now()}`, label: input.label, icon: input.icon, sort_order: input.sortOrder })
    .select(CATEGORY_COLUMNS)
    .single();
  if (error) throw categoryError(error);
  return categoryFromRow(data as CategoryRow);
}

export async function updateCategory(
  id: string,
  patch: Partial<{ label: string; icon: string; sortOrder: number; isActive: boolean; sellerId: null }>,
) {
  const row: Record<string, unknown> = {};
  if (patch.label !== undefined) row.label = patch.label;
  if (patch.icon !== undefined) row.icon = patch.icon;
  if (patch.sortOrder !== undefined) row.sort_order = patch.sortOrder;
  if (patch.isActive !== undefined) row.is_active = patch.isActive;
  if (patch.sellerId === null) row.seller_id = null;
  const { data, error } = await supabase
    .from("product_categories")
    .update(row)
    .eq("id", id)
    .select(CATEGORY_COLUMNS)
    .single();
  if (error) throw categoryError(error);
  return categoryFromRow(data as CategoryRow);
}

/** Refuses while products still use it — hide it instead, or move them first. */
export async function deleteCategory(id: string) {
  const { count, error: countError } = await supabase
    .from("products")
    .select("id", { count: "exact", head: true })
    .eq("category_id", id);
  if (countError) throw countError;
  if (count) {
    throw new Error(`Bu kategoriyada ${count} ta mahsulot bor — o'chirish o'rniga yashiring.`);
  }
  const { error } = await supabase.from("product_categories").delete().eq("id", id);
  if (error) throw categoryError(error);
}

// ── Topbar bell ───────────────────────────────────────────────────

export interface AdminAlerts {
  pendingSellers: number;
  pendingProducts: number;
  newOrders: number;
}

export async function fetchAdminAlerts(): Promise<AdminAlerts> {
  const count = async (query: PromiseLike<{ count: number | null; error: unknown }>) => {
    const { count, error } = await query;
    return error ? 0 : (count ?? 0);
  };
  const [pendingSellers, pendingProducts, newOrders] = await Promise.all([
    count(supabase.from("sellers").select("id", { count: "exact", head: true }).eq("status", "pending")),
    count(
      supabase.from("products").select("id", { count: "exact", head: true }).eq("moderation_status", "pending"),
    ),
    count(supabase.from("orders").select("id", { count: "exact", head: true }).eq("status", "qabulQilindi")),
  ]);
  return { pendingSellers, pendingProducts, newOrders };
}

// ── System page: which SQL files has the database had? ────────────

export interface SetupCheck {
  file: string;
  title: string;
  detail: string;
  ok: boolean | null;
}

async function exists(probe: PromiseLike<{ error: { code?: string; message: string } | null }>) {
  const { error } = await probe;
  if (!error) return true;
  if (isMissing(error)) return false;
  return null; // network or something else — unknown
}

export async function checkSetup(): Promise<SetupCheck[]> {
  const [sellers, logins, orders, categories, banners, mirror] = await Promise.all([
    exists(supabase.from("sellers").select("id").limit(1)),
    exists(supabase.rpc("seller_logins")),
    exists(supabase.from("orders").select("id").limit(1)),
    exists(supabase.from("product_categories").select("id").limit(1)),
    exists(supabase.from("promo_banners").select("id, title, caption, accent, image_url, icon, link, sort_order, is_active, created_at").limit(1)),
    // Every seller mirrored into companies (the products foreign key needs it).
    (async () => {
      const [{ data: s, error: e1 }, { data: c, error: e2 }] = await Promise.all([
        supabase.from("sellers").select("id"),
        supabase.from("companies").select("id"),
      ]);
      if (e1 || e2) return null;
      const companyIds = new Set((c ?? []).map((r) => r.id as string));
      return (s ?? []).every((r) => companyIds.has(r.id as string));
    })(),
  ]);
  return [
    {
      file: "seller_workflow_setup.sql",
      title: "Sotuvchilar va moderatsiya",
      detail: "sellers jadvali, mahsulot moderatsiyasi ustunlari",
      ok: sellers,
    },
    {
      file: "seller_login_setup.sql",
      title: "Sotuvchi loginlari",
      detail: "admin bergan login/parol bilan seller panelga kirish",
      ok: logins,
    },
    {
      file: "marketplace_setup.sql",
      title: "Buyurtmalar, kategoriyalar, sotuvchi ↔ kompaniya",
      detail: "orders, product_categories jadvallari; sotuvchi mahsulot qo'sha olishi",
      ok: orders === null || categories === null || mirror === null ? null : orders && categories && mirror,
    },
    {
      file: "promo_banners_setup.sql",
      title: "Reklama bannerlari",
      detail: "bosh sahifa bannerlari, rasmlari va ko'rsatish tartibi",
      ok: banners,
    },
  ];
}

// ── Home-page advertising (supabase/promo_banners_setup.sql) ──────

export const BANNERS_SETUP_HINT =
  "Reklama jadvali hali yo'q. Tizim bo'limidan promo_banners_setup.sql faylini olib, Supabase SQL Editor'da ishga tushiring.";

interface BannerRow {
  id: string; title: string; caption: string; accent: string; image_url: string | null;
  icon: PromoBanner["icon"]; link: string; sort_order: number; is_active: boolean; created_at: string;
}

const BANNER_COLUMNS = "id, title, caption, accent, image_url, icon, link, sort_order, is_active, created_at";
const missingBannerSchema = (error: { code?: string }) =>
  isMissing(error) || error.code === "PGRST204" || error.code === "42703" || error.code === "42883";

function bannerError(error: { code?: string; message: string }): Error {
  if (missingBannerSchema(error)) return new Error(BANNERS_SETUP_HINT);
  if (error.message === "banner_order_stale") return new Error("Bannerlar ro'yxati o'zgardi. Yangilab, qayta tartiblang.");
  if (error.code === "PGRST116") return new Error("Banner topilmadi. Ro'yxatni yangilang.");
  if (error.code === "23514") return new Error("Banner ma'lumotlari talablarga mos emas. Maydonlarni tekshiring.");
  return new Error(error.message);
}

function bannerFromRow(row: BannerRow): PromoBanner {
  return { id: row.id, title: row.title, caption: row.caption, accent: row.accent,
    imageUrl: row.image_url, icon: row.icon, link: row.link, sortOrder: row.sort_order,
    isActive: row.is_active, createdAt: row.created_at };
}

function bannerToRow(input: BannerInput) {
  const b = cleanBanner(input);
  return { title: b.title, caption: b.caption, accent: b.accent, image_url: b.imageUrl,
    icon: b.icon, link: b.link, sort_order: b.sortOrder, is_active: b.isActive };
}

export async function fetchBanners(): Promise<{ banners: PromoBanner[]; ready: boolean }> {
  const { data, error } = await supabase.from("promo_banners").select(BANNER_COLUMNS)
    .order("sort_order").order("created_at").order("id");
  if (error) {
    if (missingBannerSchema(error)) return { banners: [], ready: false };
    throw bannerError(error);
  }
  return { banners: (data as BannerRow[]).map(bannerFromRow), ready: true };
}

export async function createBanner(input: BannerInput): Promise<PromoBanner> {
  const { data, error } = await supabase.from("promo_banners")
    .insert({ id: crypto.randomUUID(), ...bannerToRow(input) }).select(BANNER_COLUMNS).single();
  if (error) throw bannerError(error);
  return bannerFromRow(data as BannerRow);
}

export async function updateBanner(id: string, input: BannerInput): Promise<PromoBanner> {
  const { data, error } = await supabase.from("promo_banners").update(bannerToRow(input))
    .eq("id", id).select(BANNER_COLUMNS).single();
  if (error) throw bannerError(error);
  return bannerFromRow(data as BannerRow);
}

export async function setBannerActive(id: string, isActive: boolean): Promise<PromoBanner> {
  const { data, error } = await supabase.from("promo_banners").update({ is_active: isActive })
    .eq("id", id).select(BANNER_COLUMNS).single();
  if (error) throw bannerError(error);
  return bannerFromRow(data as BannerRow);
}

export async function deleteBanner(id: string) {
  const { error } = await supabase.from("promo_banners").delete().eq("id", id).select("id").single();
  if (error) throw bannerError(error);
}
