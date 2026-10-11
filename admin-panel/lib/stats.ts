import { Order } from "./types";

/** Revenue = delivered orders, bucketed by the day they were placed. */
export function revenueByDay(orders: Order[], days = 14) {
  const pad = (n: number) => (n < 10 ? `0${n}` : String(n));
  const key = (d: Date) => `${pad(d.getDate())}.${pad(d.getMonth() + 1)}`;
  const revenue = new Map<string, number>();
  const counts = new Map<string, number>();
  for (const o of orders) {
    const k = key(new Date(o.date));
    if (o.status !== "bekorQilindi") counts.set(k, (counts.get(k) ?? 0) + 1);
    if (o.status === "yetkazildi") revenue.set(k, (revenue.get(k) ?? 0) + o.total);
  }
  const out: { date: string; revenue: number; orders: number }[] = [];
  const base = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(base);
    d.setDate(d.getDate() - i);
    out.push({ date: key(d), revenue: revenue.get(key(d)) ?? 0, orders: counts.get(key(d)) ?? 0 });
  }
  return out;
}
