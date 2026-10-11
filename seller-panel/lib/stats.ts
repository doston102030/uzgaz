import { SellerOrder } from "./types";

/** Tushum — yetkazilgan ("Yopildi") buyurtmalar, buyurtma kuni bo'yicha. */
export function revenueByDay(orders: SellerOrder[], days = 14) {
  const pad = (n: number) => (n < 10 ? `0${n}` : String(n));
  const key = (d: Date) => `${pad(d.getDate())}.${pad(d.getMonth() + 1)}`;
  const totals = new Map<string, number>();
  for (const o of orders) {
    if (o.status !== "yopildi") continue;
    const k = key(new Date(o.placedAt));
    totals.set(k, (totals.get(k) ?? 0) + o.total);
  }
  const out: { date: string; revenue: number }[] = [];
  const base = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(base);
    d.setDate(d.getDate() - i);
    out.push({ date: key(d), revenue: totals.get(key(d)) ?? 0 });
  }
  return out;
}

export function ordersSince(orders: SellerOrder[], days: number) {
  const from = new Date();
  from.setHours(0, 0, 0, 0);
  from.setDate(from.getDate() - (days - 1));
  return orders.filter((o) => new Date(o.placedAt) >= from);
}
