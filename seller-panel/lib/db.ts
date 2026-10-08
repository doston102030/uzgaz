import { supabase } from "./supabase";
import { ModerationStatus, SellerProduct, ServiceCategory } from "./types";

// Sotuvchi tanlanmaguncha demo hisobga avtomatik ulanmaydi.
export const SELLER_ID = process.env.NEXT_PUBLIC_SELLER_ID?.trim() || "";

// ── Sotuvchi holati (status) ──────────────────────────────────────

export interface SellerStatusRow {
  status: "pending" | "approved" | "rejected" | "suspended";
  company_name: string;
  owner_name: string;
}

export async function fetchSellerStatus(): Promise<SellerStatusRow> {
  if (!SELLER_ID) throw new Error("Sotuvchi hisobi hali ulanmagan.");
  const { data, error } = await supabase
    .from("sellers")
    .select("status, company_name, owner_name")
    .eq("id", SELLER_ID)
    .single();
  if (error) throw error;
  return data as SellerStatusRow;
}

// ── Mahsulotlar ─────────────────────────────────────────────────────

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
  moderation_status: string;
  rejection_reason: string | null;
  created_at: string;
}

function productFromRow(row: ProductRow): SellerProduct {
  return {
    id: row.id,
    name: row.name,
    imageUrl: row.image_url,
    images: row.images ?? undefined,
    categoryId: row.category_id as ServiceCategory,
    description: row.description ?? "",
    price: row.price,
    oldPrice: row.old_price ?? undefined,
    unit: row.unit,
    stockQty: row.stock_qty,
    moderationStatus: row.moderation_status as ModerationStatus,
    rejectionReason: row.rejection_reason ?? undefined,
    createdAt: row.created_at,
  };
}

export async function fetchSellerProducts(): Promise<SellerProduct[]> {
  if (!SELLER_ID) return [];
  const { data, error } = await supabase
    .from("products")
    .select(
      "id, name, image_url, images, category_id, description, price, old_price, unit, stock_qty, moderation_status, rejection_reason, created_at",
    )
    .eq("company_id", SELLER_ID)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data as ProductRow[]).map(productFromRow);
}

interface ProductInput {
  name: string;
  imageUrl: string;
  images?: string[];
  categoryId: ServiceCategory;
  description: string;
  price: number;
  unit: string;
  stockQty: number;
}

export async function insertSellerProduct(
  input: ProductInput,
  companyName: string,
): Promise<SellerProduct> {
  if (!SELLER_ID) throw new Error("Sotuvchi hisobi hali ulanmagan.");
  await fetchSellerStatus();
  const id = `sp${Date.now()}`;
  const { data, error } = await supabase
    .from("products")
    .insert({
      id,
      name: input.name,
      image_url: input.imageUrl,
      images: input.images ?? null,
      category_id: input.categoryId,
      description: input.description,
      price: input.price,
      unit: input.unit,
      stock_qty: input.stockQty,
      company_id: SELLER_ID,
      company_name: companyName,
      moderation_status: "pending",
    })
    .select(
      "id, name, image_url, images, category_id, description, price, old_price, unit, stock_qty, moderation_status, rejection_reason, created_at",
    )
    .single();
  if (error) throw error;
  return productFromRow(data as ProductRow);
}

export async function updateSellerProduct(
  id: string,
  input: ProductInput,
): Promise<SellerProduct> {
  const { data, error } = await supabase
    .from("products")
    .update({
      name: input.name,
      image_url: input.imageUrl,
      images: input.images ?? null,
      category_id: input.categoryId,
      description: input.description,
      price: input.price,
      unit: input.unit,
      stock_qty: input.stockQty,
      // Tahrirlangan mahsulot admin tomonidan qayta ko'rib chiqiladi.
      moderation_status: "pending",
      rejection_reason: null,
    })
    .eq("id", id)
    .select(
      "id, name, image_url, images, category_id, description, price, old_price, unit, stock_qty, moderation_status, rejection_reason, created_at",
    )
    .single();
  if (error) throw error;
  return productFromRow(data as ProductRow);
}

export async function deleteSellerProduct(id: string) {
  const { error } = await supabase.from("products").delete().eq("id", id);
  if (error) throw error;
}
