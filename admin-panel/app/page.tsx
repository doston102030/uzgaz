import { Topbar } from "@/components/Topbar";
import { StatCard } from "@/components/StatCard";
import { RevenueChart } from "@/components/RevenueChart";
import { Badge, CategoryTag } from "@/components/Badge";
import { companies, orders, products, revenueByDay, sellers } from "@/lib/mock-data";
import { formatCurrency, formatCurrencyShort, relativeTime } from "@/lib/format";
import { CATEGORY_COLOR, CATEGORY_LABEL, ORDER_STATUS_LABEL, OrderStatus } from "@/lib/types";
import { ClipboardList, Wallet, Users, ShieldAlert, ArrowRight } from "lucide-react";
import Link from "next/link";

const ORDER_TONE: Record<OrderStatus, "info" | "warning" | "success" | "danger" | "brand"> = {
  qabulQilindi: "info",
  tayyorlanmoqda: "warning",
  yolda: "brand",
  yetkazildi: "success",
  bekorQilindi: "danger",
};

export default function DashboardPage() {
  const revenue = revenueByDay(14);
  const monthRevenue = revenue.reduce((sum, d) => sum + d.revenue, 0);
  const activeSellers = sellers.filter((s) => s.status === "approved").length;
  const pendingApprovals =
    sellers.filter((s) => s.status === "pending").length +
    products.filter((p) => p.moderationStatus === "pending").length;
  const todayOrders = orders.filter((o) => o.date.startsWith("2025-09-12"));

  const recentOrders = [...orders]
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
    .slice(0, 5);
  const pendingSellers = sellers.filter((s) => s.status === "pending");
  const pendingProducts = products.filter((p) => p.moderationStatus === "pending");

  return (
    <>
      <Topbar
        title="Boshqaruv paneli"
        subtitle={`${companies.length} ta kompaniya · Andijon viloyati bo'yicha`}
      />
      <main className="flex-1 space-y-6 overflow-y-auto p-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard
            label="Bugungi buyurtmalar"
            value={String(todayOrders.length)}
            icon={ClipboardList}
            tone="brand"
            trend={{ value: "12% o'sish", positive: true }}
          />
          <StatCard
            label="Oxirgi 14 kunlik tushum"
            value={formatCurrencyShort(monthRevenue)}
            icon={Wallet}
            tone="success"
            trend={{ value: "8% o'sish", positive: true }}
          />
          <StatCard
            label="Faol sotuvchilar"
            value={String(activeSellers)}
            icon={Users}
            tone="info"
          />
          <StatCard
            label="Kutilayotgan tasdiqlash"
            value={String(pendingApprovals)}
            icon={ShieldAlert}
            tone="warning"
          />
        </div>

        <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
          <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02] xl:col-span-2">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-sm font-bold text-foreground">Tushum dinamikasi</h2>
                <p className="text-xs text-foreground/45">Oxirgi 14 kun, barcha kompaniyalar bo&apos;yicha</p>
              </div>
            </div>
            <div className="mt-2">
              <RevenueChart data={revenue} />
            </div>
          </div>

          <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-bold text-foreground">Tasdiqlash kutmoqda</h2>
              <Link href="/sellers" className="text-xs font-semibold text-brand hover:underline">
                Barchasi
              </Link>
            </div>
            <div className="mt-3 space-y-3">
              {pendingSellers.map((s) => (
                <div key={s.id} className="flex items-center gap-3 rounded-xl bg-surface-muted p-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-brand-light to-brand text-xs font-bold text-white">
                    {s.companyName.slice(0, 2).toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold text-foreground">{s.companyName}</p>
                    <p className="truncate text-xs text-foreground/45">
                      Yangi sotuvchi · {s.district}
                    </p>
                  </div>
                  <Badge label="Yangi" tone="warning" />
                </div>
              ))}
              {pendingProducts.map((p) => (
                <div key={p.id} className="flex items-center gap-3 rounded-xl bg-surface-muted p-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-amber-300 to-warning text-xs font-bold text-white">
                    {p.name.slice(0, 2).toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold text-foreground">{p.name}</p>
                    <p className="truncate text-xs text-foreground/45">
                      Yangi mahsulot · {p.companyName}
                    </p>
                  </div>
                  <Badge label="Kutilmoqda" tone="warning" />
                </div>
              ))}
              {pendingSellers.length + pendingProducts.length === 0 && (
                <p className="rounded-xl bg-surface-muted p-3 text-center text-xs text-foreground/45">
                  Hozircha kutilayotgan tasdiqlashlar yo&apos;q.
                </p>
              )}
            </div>
          </div>
        </div>

        <div className="rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]">
          <div className="flex items-center justify-between p-5 pb-0">
            <h2 className="text-sm font-bold text-foreground">So&apos;nggi buyurtmalar</h2>
            <Link
              href="/orders"
              className="flex items-center gap-1 text-xs font-semibold text-brand hover:underline"
            >
              Barchasi <ArrowRight className="h-3.5 w-3.5" />
            </Link>
          </div>
          <div className="overflow-x-auto">
            <table className="mt-4 w-full min-w-[640px] text-left text-sm">
              <thead>
                <tr className="border-y border-border text-xs uppercase tracking-wide text-foreground/40">
                  <th className="px-5 py-2.5 font-medium">Buyurtma</th>
                  <th className="px-5 py-2.5 font-medium">Xaridor</th>
                  <th className="px-5 py-2.5 font-medium">Kompaniya</th>
                  <th className="px-5 py-2.5 font-medium">Summasi</th>
                  <th className="px-5 py-2.5 font-medium">Holati</th>
                  <th className="px-5 py-2.5 font-medium">Vaqti</th>
                </tr>
              </thead>
              <tbody>
                {recentOrders.map((o) => (
                  <tr key={o.id} className="border-b border-border last:border-0">
                    <td className="px-5 py-3 font-semibold text-foreground">{o.orderNumber}</td>
                    <td className="px-5 py-3 text-foreground/70">{o.buyerName}</td>
                    <td className="px-5 py-3 text-foreground/70">{o.companyName}</td>
                    <td className="px-5 py-3 font-semibold text-foreground">
                      {formatCurrency(o.total)}
                    </td>
                    <td className="px-5 py-3">
                      <Badge label={ORDER_STATUS_LABEL[o.status]} tone={ORDER_TONE[o.status]} />
                    </td>
                    <td className="px-5 py-3 text-foreground/45">{relativeTime(o.date)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
          <h2 className="text-sm font-bold text-foreground">Kategoriyalar bo&apos;yicha mahsulotlar</h2>
          <div className="mt-4 flex flex-wrap gap-2">
            {Object.entries(CATEGORY_LABEL).map(([key, label]) => {
              const count = products.filter((p) => p.categoryId === key).length;
              return (
                <CategoryTag
                  key={key}
                  label={`${label} · ${count}`}
                  color={CATEGORY_COLOR[key as keyof typeof CATEGORY_COLOR]}
                />
              );
            })}
          </div>
        </div>
      </main>
    </>
  );
}
