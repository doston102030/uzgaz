import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!url || !anonKey) {
  throw new Error(
    "Supabase sozlamalari topilmadi — .env.local faylida NEXT_PUBLIC_SUPABASE_URL va NEXT_PUBLIC_SUPABASE_ANON_KEY borligini tekshiring.",
  );
}

export const supabase = createClient(url, anonKey);

/** `product-images` ombori (bucket) — sotuvchi paneli ham shunga yuklaydi. */
export const PRODUCT_IMAGES_BUCKET = "product-images";

/**
 * Admin moslagan rasmni Storage'ga yuklaydi va doimiy (public) URL qaytaradi.
 * Nom har safar yangi — fayl o'zgarmaydi, shuning uchun uzoq keshlanadi.
 */
export async function uploadProductImage(file: Blob): Promise<string> {
  const byType: Record<string, string> = { "image/webp": "webp", "image/png": "png", "image/jpeg": "jpg" };
  const ext = byType[file.type] ?? "png";
  const path = `admin-fitted/${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;

  const { error } = await supabase.storage.from(PRODUCT_IMAGES_BUCKET).upload(path, file, {
    cacheControl: "31536000",
    contentType: file.type || undefined,
    upsert: false,
  });
  if (error) throw error;

  const { data } = supabase.storage.from(PRODUCT_IMAGES_BUCKET).getPublicUrl(path);
  return data.publicUrl;
}
