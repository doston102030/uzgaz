import { SellerOrder, SellerProduct, SellerProfile } from "./types";

export const profile: SellerProfile | null = null;

// Demo mahsulotlar tozalandi — real mahsulotlaringizni (rasmlari bilan) shu yerdan qo'shasiz.
export const products: SellerProduct[] = [];

export const orders: SellerOrder[] = [];

export function revenueByDay(days = 14) {
  const out: { date: string; revenue: number }[] = [];
  const base = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(base);
    d.setDate(d.getDate() - i);
    const revenue = 0;
    const pad = (n: number) => (n < 10 ? `0${n}` : String(n));
    out.push({ date: `${pad(d.getDate())}.${pad(d.getMonth() + 1)}`, revenue });
  }
  return out;
}
