import { supabase } from "./supabase";
import { currentSellerId } from "./auth";
import { DEFAULT_CATEGORIES, ProductCategory } from "./categories";
import { ModerationStatus, SellerOrder, SellerOrderStatus, SellerProduct } from "./types";

// ── Sotuvchi holati (status) ──────────────────────────────────────

export interface SellerStatusRow {
  status: "pending" | "approved" | "rejected" | "suspended";
  company_name: string;
  owner_name: string;
}

export async function fetchSellerStatus(): Promise<SellerStatusRow> {
  const sellerId = currentSellerId();
  if (!sellerId) throw new Error("Sotuvchi hisobiga kirilmagan.");
  const { data, error } = await supabase
    .from("sellers")
    .select("status, company_name, owner_name")
    .eq("id", sellerId)
    .single();
  if (error) throw error;
  return data as SellerStatusRow;
}

// ── Mahsulotlar ─────────────────────────────────────────────────────

/** Jadval/ustun hali yo'q (SQL ishga tushirilmagan) xatolari. */
function isSetupMissing(error: { code?: string }) {
  return error.code === "PGRST205" || error.code === "42P01" || error.code === "PGRST204";
}

export const MARKETPLACE_SETUP_HINT =
  "Bu funksiya uchun administrator supabase/marketplace_setup.sql faylini SQL Editor'da bir marta ishga tushirishi kerak.";

interface ProductRow {
  id: string;
  name: string;
  image_url: string;
  images: string[] | null;
  category_id: string;
  description: string | null;
  price: number;
  old_price: number | null;
  unit: string;
  stock_qty: number;
  is_available: boolean;
  moderation_status: string;
  rejection_reason: string | null;
  created_at: string;
}

const PRODUCT_COLUMNS =
  "id, name, image_url, images, category_id, description, price, old_price, unit, stock_qty, is_available, moderation_status, rejection_reason, created_at";

// Eski "standart rasm" manzillari omborda yo'q (400) — rasmsiz deb hisoblaymiz.
const isRealImage = (url: string | null | undefined): url is string =>
  !!url && !url.includes("/product-images/catalog/");

function productFromRow(row: ProductRow): SellerProduct {
  const images = (row.images ?? []).filter(isRealImage);
  return {
    id: row.id,
    name: row.name,
    imageUrl: isRealImage(row.image_url) ? row.image_url : "",
    images: images.length > 0 ? images : undefined,
    categoryId: row.category_id,
    description: row.description ?? "",
    price: row.price,
    oldPrice: row.old_price ?? undefined,
    unit: row.unit,
    stockQty: row.stock_qty,
    isAvailable: row.is_available,
    moderationStatus: row.moderation_status as ModerationStatus,
    rejectionReason: row.rejection_reason ?? undefined,
    createdAt: row.created_at,
  };
}

export async function fetchSellerProducts(): Promise<SellerProduct[]> {
  const sellerId = currentSellerId();
  if (!sellerId) return [];
  const { data, error } = await supabase
    .from("products")
    .select(PRODUCT_COLUMNS)
    .eq("company_id", sellerId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data as ProductRow[]).map(productFromRow);
}

export interface ProductInput {
  name: string;
  /** Birinchi rasm; rasm bo'lmasa "" — ilova va panel o'z belgisini ko'rsatadi. */
  imageUrl: string;
  images?: string[];
  categoryId: string;
  description: string;
  price: number;
  oldPrice?: number;
  unit: string;
  stockQty: number;
}

function productFields(input: ProductInput) {
  return {
    name: input.name,
    image_url: input.imageUrl,
    images: input.images ?? null,
    category_id: input.categoryId,
    description: input.description,
    price: input.price,
    old_price: input.oldPrice ?? null,
    unit: input.unit,
    stock_qty: input.stockQty,
  };
}

export async function insertSellerProduct(
  input: ProductInput,
  companyName: string,
): Promise<SellerProduct> {
  const sellerId = currentSellerId();
  if (!sellerId) throw new Error("Sotuvchi hisobiga kirilmagan.");
  const { data, error } = await supabase
    .from("products")
    .insert({
      id: `sp${Date.now()}`,
      ...productFields(input),
      company_id: sellerId,
      company_name: companyName,
      moderation_status: "pending",
    })
    .select(PRODUCT_COLUMNS)
    .single();
  if (error) {
    // 23503: products.company_id → companies; the seller has no company
    // row until supabase/marketplace_setup.sql has run.
    if (error.code === "23503") {
      throw new Error(
        "Kompaniyangiz hali katalogga ulanmagan — administrator supabase/marketplace_setup.sql faylini SQL Editor'da ishga tushirishi kerak.",
      );
    }
    throw error;
  }
  return productFromRow(data as ProductRow);
}

export async function updateSellerProduct(id: string, input: ProductInput): Promise<SellerProduct> {
  const { data, error } = await supabase
    .from("products")
    .update({
      ...productFields(input),
      // Tahrirlangan mahsulot admin tomonidan qayta ko'rib chiqiladi.
      moderation_status: "pending",
      rejection_reason: null,
    })
    .eq("id", id)
    .eq("company_id", currentSellerId())
    .select(PRODUCT_COLUMNS)
    .single();
  if (error) throw error;
  return productFromRow(data as ProductRow);
}

/** Sotuvdan vaqtincha olish / qaytarish — moderatsiya qayta boshlanmaydi. */
export async function setProductAvailability(id: string, isAvailable: boolean) {
  const { error } = await supabase
    .from("products")
    .update({ is_available: isAvailable })
    .eq("id", id)
    .eq("company_id", currentSellerId());
  if (error) throw error;
}

export async function deleteSellerProduct(id: string) {
  const { error } = await supabase
    .from("products")
    .delete()
    .eq("id", id)
    .eq("company_id", currentSellerId());
  if (error) throw error;
}

// ── Kategoriyalar (product_categories) ────────────────────────────

interface CategoryRow {
  id: string;
  label: string;
  icon: string;
  seller_id: string | null;
  sort_order: number;
  is_active: boolean;
}

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

/**
 * Platforma kategoriyalari + sotuvchining o'zinikilari. `ready: false` —
 * jadval hali yo'q: standart uchtasi ko'rsatiladi, yangisini qo'shib bo'lmaydi.
 */
export async function fetchCategories(): Promise<{ categories: ProductCategory[]; ready: boolean }> {
  const sellerId = currentSellerId();
  const { data, error } = await supabase
    .from("product_categories")
    .select("id, label, icon, seller_id, sort_order, is_active")
    .or(sellerId ? `seller_id.is.null,seller_id.eq.${sellerId}` : "seller_id.is.null")
    .order("sort_order")
    .order("created_at");
  if (error) {
    if (isSetupMissing(error)) return { categories: DEFAULT_CATEGORIES, ready: false };
    throw error;
  }
  return { categories: (data as CategoryRow[]).map(categoryFromRow), ready: true };
}

function categoryError(error: { code?: string; message: string }): Error {
  if (error.code === "23505") return new Error("Bu nomli kategoriya allaqachon bor.");
  if (error.code === "23514") return new Error("Kategoriya nomi 1–40 belgi bo'lsin.");
  if (isSetupMissing(error)) return new Error(MARKETPLACE_SETUP_HINT);
  return new Error(error.message);
}

export async function createCategory(label: string): Promise<ProductCategory> {
  const sellerId = currentSellerId();
  if (!sellerId) throw new Error("Sotuvchi hisobiga kirilmagan.");
  const { data, error } = await supabase
    .from("product_categories")
    .insert({ id: `c${Date.now()}`, label, icon: "tag", seller_id: sellerId })
    .select("id, label, icon, seller_id, sort_order, is_active")
    .single();
  if (error) throw categoryError(error);
  return categoryFromRow(data as CategoryRow);
}

/**
 * Nomni o'zgartiradi — o'zinikini yoki umumiysini (umumiyniki hamma sotuvchi
 * uchun o'zgaradi). Mahsulotlar id bilan bog'liq, ularga tegilmaydi.
 */
export async function renameCategory(category: ProductCategory, label: string): Promise<ProductCategory> {
  const query = supabase.from("product_categories").update({ label }).eq("id", category.id);
  const scoped =
    category.sellerId === null ? query.is("seller_id", null) : query.eq("seller_id", currentSellerId());
  const { data, error } = await scoped
    .select("id, label, icon, seller_id, sort_order, is_active")
    .single();
  if (error) throw categoryError(error);
  return categoryFromRow(data as CategoryRow);
}

/** Ishlatilayotgan kategoriya o'chirilmaydi — avval mahsulotlarni boshqasiga o'tkazish kerak. */
export async function deleteCategory(id: string) {
  const sellerId = currentSellerId();
  const { count, error: countError } = await supabase
    .from("products")
    .select("id", { count: "exact", head: true })
    .eq("company_id", sellerId)
    .eq("category_id", id);
  if (countError) throw countError;
  if (count) {
    throw new Error(
      `Bu kategoriyada ${count} ta mahsulot bor — avval ularni boshqa kategoriyaga o'tkazing.`,
    );
  }
  const { error } = await supabase
    .from("product_categories")
    .delete()
    .eq("id", id)
    .eq("seller_id", sellerId);
  if (error) throw categoryError(error);
}

// ── Bildirishnomalar (topbar qo'ng'iroqchasi) ─────────────────────

export interface SellerAlerts {
  newOrders: number;
  rejectedProducts: number;
  pendingProducts: number;
}

export async function fetchSellerAlerts(): Promise<SellerAlerts> {
  const sellerId = currentSellerId();
  const count = async (query: PromiseLike<{ count: number | null; error: unknown }>) => {
    const { count, error } = await query;
    return error ? 0 : (count ?? 0);
  };
  const [newOrders, rejectedProducts, pendingProducts] = await Promise.all([
    count(
      supabase
        .from("orders")
        .select("id", { count: "exact", head: true })
        .eq("company_id", sellerId)
        .eq("status", "qabulQilindi"),
    ),
    count(
      supabase
        .from("products")
        .select("id", { count: "exact", head: true })
        .eq("company_id", sellerId)
        .eq("moderation_status", "rejected"),
    ),
    count(
      supabase
        .from("products")
        .select("id", { count: "exact", head: true })
        .eq("company_id", sellerId)
        .eq("moderation_status", "pending"),
    ),
  ]);
  return { newOrders, rejectedProducts, pendingProducts };
}

// ── Buyurtmalar (supabase/marketplace_setup.sql) ──────────────────

export const ORDERS_SETUP_HINT =
  "Supabase'da buyurtmalar jadvali hali yo'q — administrator supabase/marketplace_setup.sql faylini SQL Editor'da bir marta ishga tushirishi kerak.";

// Bazada holat nomlari ilovadagi bilan bir xil; panel o'z nomlarini ko'rsatadi.
const ORDER_STATUS_FROM_DB: Record<string, SellerOrderStatus> = {
  qabulQilindi: "yangi",
  tayyorlanmoqda: "tayyorlanmoqda",
  yolda: "yetkazishga",
  yetkazildi: "yopildi",
  bekorQilindi: "bekorQilindi",
};

const ORDER_STATUS_TO_DB: Record<SellerOrderStatus, string> = {
  yangi: "qabulQilindi",
  tayyorlanmoqda: "tayyorlanmoqda",
  yetkazishga: "yolda",
  yopildi: "yetkazildi",
  bekorQilindi: "bekorQilindi",
};

interface OrderRow {
  id: string;
  order_number: string;
  buyer_name: string;
  buyer_phone: string;
  items: { name: string; quantity: number; price: number }[];
  total: number;
  status: string;
  delivery_method: "delivery" | "selfPickup";
  payment_method: string;
  address: string | null;
  created_at: string;
}

const ORDER_COLUMNS =
  "id, order_number, buyer_name, buyer_phone, items, total, status, delivery_method, payment_method, address, created_at";

function orderFromRow(row: OrderRow): SellerOrder {
  return {
    id: row.id,
    orderNumber: row.order_number,
    buyerName: row.buyer_name || "Mehmon",
    buyerPhone: row.buyer_phone,
    items: (row.items ?? []).map((i) => ({
      productName: i.name,
      quantity: i.quantity,
      price: i.price,
    })),
    total: row.total,
    status: ORDER_STATUS_FROM_DB[row.status] ?? "yangi",
    deliveryMethod: row.delivery_method,
    paymentMethod: row.payment_method,
    address: row.address ?? undefined,
    placedAt: row.created_at,
  };
}

function ordersError(error: { code?: string; message: string }): Error {
  // PGRST205 / 42P01: jadval yo'q — SQL hali ishga tushirilmagan.
  if (error.code === "PGRST205" || error.code === "42P01") return new Error(ORDERS_SETUP_HINT);
  return new Error(error.message);
}

export async function fetchSellerOrders(): Promise<SellerOrder[]> {
  const sellerId = currentSellerId();
  if (!sellerId) return [];
  const { data, error } = await supabase
    .from("orders")
    .select(ORDER_COLUMNS)
    .eq("company_id", sellerId)
    .order("created_at", { ascending: false });
  if (error) throw ordersError(error);
  return (data as OrderRow[]).map(orderFromRow);
}

/**
 * Buyurtmani `from` holatidan `to` ga o'tkazadi. Shu orada xaridor bekor
 * qilgan bo'lsa, hech narsa yozilmaydi va yangilangan buyurtma qaytadi.
 */
export async function updateSellerOrderStatus(
  id: string,
  from: SellerOrderStatus,
  to: SellerOrderStatus,
): Promise<SellerOrder> {
  const sellerId = currentSellerId();
  if (!sellerId) throw new Error("Sotuvchi hisobiga kirilmagan.");
  const { data, error } = await supabase
    .from("orders")
    .update({ status: ORDER_STATUS_TO_DB[to] })
    .eq("id", id)
    .eq("company_id", sellerId)
    .eq("status", ORDER_STATUS_TO_DB[from])
    .select(ORDER_COLUMNS);
  if (error) throw ordersError(error);
  if (data.length > 0) return orderFromRow(data[0] as OrderRow);
  const { data: current, error: readError } = await supabase
    .from("orders")
    .select(ORDER_COLUMNS)
    .eq("id", id)
    .single();
  if (readError) throw ordersError(readError);
  return orderFromRow(current as OrderRow);
}

// ── Profil: sellers (admin ko'radigan) + companies (xaridor ko'radigan) ──

export interface SellerProfileData {
  companyName: string;
  ownerName: string;
  category: string;
  district: string;
  address: string;
  phone: string;
  status: SellerStatusRow["status"];
  rating: number;
  reviewCount: number;
  workingHours: string;
  deliveryFee: number;
  etaMinutes: number;
  /** false — companies qatori yo'q (marketplace_setup.sql ishga tushirilmagan). */
  hasStorefront: boolean;
}

export async function fetchSellerProfile(): Promise<SellerProfileData> {
  const sellerId = currentSellerId();
  if (!sellerId) throw new Error("Sotuvchi hisobiga kirilmagan.");
  const [seller, company] = await Promise.all([
    supabase.from("sellers").select("*").eq("id", sellerId).single(),
    supabase
      .from("companies")
      .select("working_hours, delivery_fee, eta_minutes")
      .eq("id", sellerId)
      .maybeSingle(),
  ]);
  if (seller.error) throw seller.error;
  const s = seller.data;
  const c = company.data;
  return {
    companyName: s.company_name,
    ownerName: s.owner_name,
    category: s.category,
    district: s.district,
    address: s.address,
    phone: s.phone,
    status: s.status,
    rating: Number(s.rating),
    reviewCount: s.review_count,
    workingHours: c?.working_hours ?? "09:00 - 21:00",
    deliveryFee: c?.delivery_fee ?? 15000,
    etaMinutes: c?.eta_minutes ?? 40,
    hasStorefront: c != null,
  };
}

export async function saveSellerProfile(input: SellerProfileData) {
  const sellerId = currentSellerId();
  if (!sellerId) throw new Error("Sotuvchi hisobiga kirilmagan.");
  const { error } = await supabase
    .from("sellers")
    .update({
      company_name: input.companyName,
      owner_name: input.ownerName,
      address: input.address,
      phone: input.phone,
    })
    .eq("id", sellerId);
  if (error) throw error;
  if (!input.hasStorefront) return;
  const { error: companyError } = await supabase
    .from("companies")
    .update({
      working_hours: input.workingHours,
      delivery_fee: input.deliveryFee,
      eta_minutes: input.etaMinutes,
    })
    .eq("id", sellerId);
  if (companyError) throw companyError;
}
