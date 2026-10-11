"use client";

import { useEffect, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { StatCard } from "@/components/StatCard";
import { RevenueChart } from "@/components/RevenueChart";
import { TopProductsChart } from "@/components/TopProductsChart";
import { fetchSellerOrders, fetchSellerProfile } from "@/lib/db";
import { formatCurrencyShort } from "@/lib/format";
import { ordersSince, revenueByDay } from "@/lib/stats";
import { SellerOrder } from "@/lib/types";
import { TrendingUp, ShoppingBag, Percent, Star } from "lucide-react";

export default function ReportsPage() {
  const [allOrders, setAllOrders] = useState<SellerOrder[]>([]);
  const [rating, setRating] = useState<string>("—");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    fetchSellerOrders()
      .then((rows) => {
        if (!cancelled) setAllOrders(rows);
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err.message : "Buyurtmalarni yuklab bo'lmadi.");
      });
    fetchSellerProfile()
      .then((p) => {
        if (!cancelled && p.reviewCount > 0) setRating(p.rating.toFixed(1));
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);

  // Oxirgi 30 kun; bekor qilinganlar savdo hisoblanmaydi.
  const orders = ordersSince(allOrders, 30);
  const sold = orders.filter((o) => o.status !== "bekorQilindi");
  const completed = orders.filter((o) => o.status === "yopildi");

  const revenue = revenueByDay(orders, 30);
  const totalRevenue = revenue.reduce((s, d) => s + d.revenue, 0);
  const avgOrder = completed.length > 0 ? totalRevenue / completed.length : 0;

  const revenueByProduct = new Map<string, number>();
  for (const o of completed) {
    for (const item of o.items) {
      revenueByProduct.set(
        item.productName,
        (revenueByProduct.get(item.productName) ?? 0) + item.price * item.quantity,
      );
    }
  }
  const topProducts = [...revenueByProduct.entries()]
    .map(([name, revenue]) => ({ name, revenue }))
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 6);

  const completionRate = orders.length > 0 ? Math.round((completed.length / orders.length) * 100) : 0;

  return (
    <>
      <Topbar title="Hisobotlar" subtitle="Oxirgi 30 kunlik savdo ko'rsatkichlari" />
      <main className="flex-1 space-y-6 overflow-y-auto p-4 sm:p-6">
        {error && (
          <p className="rounded-xl border border-warning/30 bg-warning-tint px-4 py-3 text-sm text-foreground/75">
            {error}
          </p>
        )}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard
            label="30 kunlik tushum"
            value={formatCurrencyShort(totalRevenue)}
            icon={TrendingUp}
            tone="success"
          />
          <StatCard
            label="O'rtacha buyurtma"
            value={formatCurrencyShort(avgOrder)}
            icon={ShoppingBag}
            tone="brand"
          />
          <StatCard
            label="Yakunlanish darajasi"
            value={`${completionRate}%`}
            icon={Percent}
            tone="info"
          />
          <StatCard label="Reyting" value={rating} icon={Star} tone="warning" />
        </div>

        <div className="grid grid-cols-1 gap-6 xl:grid-cols-2">
          <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
            <h2 className="text-sm font-bold text-foreground">Tushum dinamikasi</h2>
            <p className="text-xs text-foreground/45">Oxirgi 30 kun · yetkazilgan buyurtmalar</p>
            <div className="mt-2">
              <RevenueChart data={revenue} />
            </div>
          </div>
          <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
            <h2 className="text-sm font-bold text-foreground">Eng ko&apos;p sotilgan mahsulotlar</h2>
            <p className="text-xs text-foreground/45">Yetkazilgan buyurtmalar bo&apos;yicha tushum</p>
            <div className="mt-2">
              {topProducts.length > 0 ? (
                <TopProductsChart data={topProducts} />
              ) : (
                <p className="py-16 text-center text-sm text-foreground/40">
                  Hali yetkazilgan buyurtma yo&apos;q.
                </p>
              )}
            </div>
          </div>
        </div>

        <p className="text-xs text-foreground/45">
          30 kunda {orders.length} ta buyurtma: {completed.length} tasi yetkazildi,{" "}
          {sold.length - completed.length} tasi jarayonda, {orders.length - sold.length} tasi bekor qilindi.
        </p>
      </main>
    </>
  );
}
