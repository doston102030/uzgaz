import { Company, Order, Product, Seller } from "./types";

// Demo kompaniyalar tozalandi — real kompaniyalarni o'zingiz (rasmlari bilan) qo'shasiz.
export const companies: Company[] = [];

// Demo mahsulotlar tozalandi — real mahsulotlarni o'zingiz (rasmlari bilan) qo'shasiz.
export const products: Product[] = [];

export const sellers: Seller[] = [];

export const orders: Order[] = [];

export function revenueByDay(days = 14) {
  const out: { date: string; revenue: number; orders: number }[] = [];
  const base = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(base);
    d.setDate(d.getDate() - i);
    const revenue = 0;
    const ordersCount = 0;
    const pad = (n: number) => (n < 10 ? `0${n}` : String(n));
    out.push({
      date: `${pad(d.getDate())}.${pad(d.getMonth() + 1)}`,
      revenue,
      orders: ordersCount,
    });
  }
  return out;
}
