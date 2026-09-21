import { supabase } from "./supabase";
import { ModerationStatus, Product, Seller, SellerStatus, ServiceCategory } from "./types";

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
  moderation_status: string;
  rejection_reason: string | null;
  created_at: string;
}

function productFromRow(row: ProductRow): Product {
  return {
    id: row.id,
    name: row.name,
    imageUrl: row.image_url,
    price: row.price,
    oldPrice: row.old_price ?? undefined,
    rating: row.rating,
    reviewCount: row.review_count,
    isAvailable: row.is_available,
    isPopular: row.is_popular,
    companyId: row.company_id ?? "",
    companyName: row.company_name,
    categoryId: row.category_id as ServiceCategory,
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
