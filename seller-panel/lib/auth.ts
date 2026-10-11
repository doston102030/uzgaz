import { supabase } from "./supabase";

// Login/parolni admin beradi (admin panel → Sotuvchilar → "Login berish").
// Tekshiruv Supabase'dagi `seller_sign_in` / `seller_session` funksiyalarida —
// supabase/seller_login_setup.sql.

export interface SellerSession {
  id: string;
  companyName: string;
  ownerName: string;
  status: "pending" | "approved" | "rejected" | "suspended";
}

interface SessionRow {
  seller_id: string;
  company_name: string;
  owner_name: string;
  status: SellerSession["status"];
}

const TOKEN_KEY = "ge.seller.token";

// Kirgan sotuvchi — lib/db.ts so'rovlari shu id bilan ishlaydi.
let activeSellerId = "";

export function currentSellerId(): string {
  return activeSellerId;
}

export const LOGIN_SETUP_HINT =
  "Kirish hali sozlanmagan — administrator supabase/seller_login_setup.sql faylini ishga tushirishi kerak.";

function sessionFromRow(row: SessionRow): SellerSession {
  activeSellerId = row.seller_id;
  return {
    id: row.seller_id,
    companyName: row.company_name,
    ownerName: row.owner_name,
    status: row.status,
  };
}

function readToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

function writeToken(token: string | null) {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {
    // Brauzer xotirasi yopiq bo'lsa, sessiya faqat shu oynada yashaydi.
  }
}

function isSetupMissing(error: { code?: string }) {
  return error.code === "PGRST202" || error.code === "42883" || error.code === "42P01";
}

/** Noto'g'ri login/parol — `null`; tarmoq yoki sozlama xatosi — `Error`. */
export async function signIn(login: string, password: string): Promise<SellerSession | null> {
  const { data, error } = await supabase.rpc("seller_sign_in", {
    p_login: login.trim().toLowerCase(),
    p_password: password,
  });
  if (error) throw new Error(isSetupMissing(error) ? LOGIN_SETUP_HINT : error.message);
  const row = (data as (SessionRow & { token: string })[])[0];
  if (!row) return null;
  writeToken(row.token);
  return sessionFromRow(row);
}

/**
 * Saqlangan sessiyani tiklaydi. Token yo'q yoki bekor qilingan (admin yangi
 * parol bergan) bo'lsa — `null`. Tarmoq xatosida tokenni o'chirmaydi.
 */
export async function restoreSession(): Promise<SellerSession | null> {
  const token = readToken();
  if (!token) return null;
  const { data, error } = await supabase.rpc("seller_session", { p_token: token });
  if (error) {
    if (isSetupMissing(error)) return null;
    throw new Error(error.message);
  }
  const row = (data as SessionRow[])[0];
  if (!row) {
    signOut();
    return null;
  }
  return sessionFromRow(row);
}

export function signOut() {
  activeSellerId = "";
  writeToken(null);
}
