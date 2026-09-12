import { Topbar } from "@/components/Topbar";
import { StatCard } from "@/components/StatCard";
import { RevenueChart } from "@/components/RevenueChart";
import { TopProductsChart } from "@/components/TopProductsChart";
import { orders, revenueByDay } from "@/lib/mock-data";
import { formatCurrencyShort } from "@/lib/format";
import { TrendingUp, ShoppingBag, Percent, Star } from "lucide-react";

export default function ReportsPage() {
  const revenue = revenueByDay(30);
  const totalRevenue = revenue.reduce((s, d) => s + d.revenue, 0);
  const avgOrder = orders.length > 0
    ? orders.reduce((s, o) => s + o.total, 0) / orders.length
    : 0;

  const revenueByProduct = new Map<string, number>();
  for (const o of orders) {
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

  const completedOrders = orders.filter((o) => o.status === "yopildi").length;
  const completionRate =
    orders.length > 0 ? Math.round((completedOrders / orders.length) * 100) : 0;

  return (
    <>
      <Topbar title="Hisobotlar" subtitle="Oxirgi 30 kunlik savdo ko'rsatkichlari" />
      <main className="flex-1 space-y-6 overflow-y-auto p-6">
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
          <StatCard
            label="Reyting"
            value="4.8"
            icon={Star}
            tone="warning"
          />
        </div>

        <div className="grid grid-cols-1 gap-6 xl:grid-cols-2">
          <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
            <h2 className="text-sm font-bold text-foreground">Tushum dinamikasi</h2>
            <p className="text-xs text-foreground/45">Oxirgi 30 kun</p>
            <div className="mt-2">
              <RevenueChart data={revenue} />
            </div>
          </div>
          <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
            <h2 className="text-sm font-bold text-foreground">Eng ko&apos;p sotilgan mahsulotlar</h2>
            <p className="text-xs text-foreground/45">Buyurtmalar bo&apos;yicha tushum</p>
            <div className="mt-2">
              <TopProductsChart data={topProducts} />
            </div>
          </div>
        </div>

        <div className="rounded-2xl border border-dashed border-border bg-surface-muted p-6 text-xs leading-relaxed text-foreground/55">
          Bu hisobotlar hozircha namunaviy ma&apos;lumotlar asosida hisoblanmoqda. Supabase
          bazasiga ulanganda, real buyurtma va to&apos;lov tarixi bo&apos;yicha avtomatik
          yangilanadi.
        </div>
      </main>
    </>
  );
}
