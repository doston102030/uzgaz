import { Topbar } from "@/components/Topbar";
import { StatCard } from "@/components/StatCard";
import { RevenueChart } from "@/components/RevenueChart";
import { Badge, BadgeTone } from "@/components/Badge";
import { orders, products, revenueByDay } from "@/lib/mock-data";
import { formatCurrency, formatCurrencyShort, relativeTime } from "@/lib/format";
import { SELLER_ORDER_STATUS_LABEL, SellerOrderStatus } from "@/lib/types";
import { ClipboardList, Wallet, PackageCheck, ShieldAlert, ArrowRight } from "lucide-react";
import Link from "next/link";

const ORDER_TONE: Record<SellerOrderStatus, BadgeTone> = {
  yangi: "info",
  tayyorlanmoqda: "warning",
  yetkazishga: "brand",
  yopildi: "success",
  bekorQilindi: "danger",
};

export default function DashboardPage() {
  const revenue = revenueByDay(14);
  const periodRevenue = revenue.reduce((sum, d) => sum + d.revenue, 0);
  const activeProducts = products.filter((p) => p.moderationStatus === "approved").length;
  const pendingProducts = products.filter((p) => p.moderationStatus === "pending").length;
  const newOrders = orders.filter((o) => o.status === "yangi").length;

  const recentOrders = [...orders]
    .sort((a, b) => new Date(b.placedAt).getTime() - new Date(a.placedAt).getTime())
    .slice(0, 5);

  return (
    <>
      <Topbar title="Bosh sahifa" subtitle="Andijon Gaz Ta'minot faoliyatiga umumiy nazar" />
      <main className="flex-1 space-y-6 overflow-y-auto p-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard
            label="Yangi buyurtmalar"
            value={String(newOrders)}
            icon={ClipboardList}
            tone="brand"
          />
          <StatCard
            label="Oxirgi 14 kunlik tushum"
            value={formatCurrencyShort(periodRevenue)}
            icon={Wallet}
            tone="success"
            trend={{ value: "6% o'sish", positive: true }}
          />
          <StatCard
            label="Faol mahsulotlar"
            value={String(activeProducts)}
            icon={PackageCheck}
            tone="info"
          />
          <StatCard
            label="Moderatsiyada"
            value={String(pendingProducts)}
            icon={ShieldAlert}
            tone="warning"
          />
        </div>

        <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
          <div>
            <h2 className="text-sm font-bold text-foreground">Tushum dinamikasi</h2>
            <p className="text-xs text-foreground/45">Oxirgi 14 kun</p>
          </div>
          <div className="mt-2">
            <RevenueChart data={revenue} />
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
                    <td className="px-5 py-3 font-semibold text-foreground">
                      {formatCurrency(o.total)}
                    </td>
                    <td className="px-5 py-3">
                      <Badge label={SELLER_ORDER_STATUS_LABEL[o.status]} tone={ORDER_TONE[o.status]} />
                    </td>
                    <td className="px-5 py-3 text-foreground/45">{relativeTime(o.placedAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </>
  );
}
