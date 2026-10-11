"use client";

import { useEffect, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { SellerHeroBanner } from "@/components/SellerHeroBanner";
import { StatCard } from "@/components/StatCard";
import { RevenueChart } from "@/components/RevenueChart";
import { Badge, BadgeTone } from "@/components/Badge";
import { fetchSellerOrders, fetchSellerProducts, fetchSellerStatus } from "@/lib/db";
import { formatCurrency, formatCurrencyShort, relativeTime } from "@/lib/format";
import { revenueByDay } from "@/lib/stats";
import {
  SELLER_ORDER_STATUS_LABEL,
  SellerOrder,
  SellerOrderStatus,
  SellerProduct,
} from "@/lib/types";
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
  const [products, setProducts] = useState<SellerProduct[]>([]);
  const [orders, setOrders] = useState<SellerOrder[]>([]);
  const [companyName, setCompanyName] = useState("Sotuvchi paneli");

  useEffect(() => {
    let cancelled = false;
    const loadOrders = () =>
      fetchSellerOrders()
        .then((rows) => {
          if (!cancelled) setOrders(rows);
        })
        .catch(() => {});
    void loadOrders();
    // Yangi buyurtma kelsa, bosh sahifadagi raqam ham o'zi yangilanadi.
    const timer = setInterval(() => {
      if (!document.hidden) void loadOrders();
    }, 15_000);
    fetchSellerProducts()
      .then((rows) => {
        if (!cancelled) setProducts(rows);
      })
      .catch(() => {
        // Dashboard statistikasi ixtiyoriy — yuklanmasa 0 ko'rsatiladi.
      });
    fetchSellerStatus()
      .then((status) => {
        if (!cancelled) setCompanyName(status.company_name);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, []);

  const revenue = revenueByDay(orders, 14);
  const periodRevenue = revenue.reduce((sum, d) => sum + d.revenue, 0);
  const activeProducts = products.filter((p) => p.moderationStatus === "approved").length;
  const pendingProducts = products.filter((p) => p.moderationStatus === "pending").length;
  const newOrders = orders.filter((o) => o.status === "yangi").length;

  const recentOrders = orders.slice(0, 5);

  return (
    <>
      <Topbar title="Bosh sahifa" subtitle={`${companyName} faoliyatiga umumiy nazar`} />
      <main className="flex-1 space-y-6 overflow-y-auto p-4 sm:p-6">
        <SellerHeroBanner
          companyName={companyName}
          newOrders={newOrders}
          pendingProducts={pendingProducts}
        />

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
          {recentOrders.length === 0 ? (
            <p className="px-5 py-10 text-center text-sm text-foreground/40">
              Hozircha buyurtma yo&apos;q — xaridor ilovadan buyurtma bersa, shu yerda chiqadi.
            </p>
          ) : (
            <ul className="mt-3 divide-y divide-border border-t border-border">
              {recentOrders.map((o) => (
                <li key={o.id}>
                  <Link href="/orders" className="flex items-center gap-3 px-5 py-3 hover:bg-surface-muted/60">
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold text-foreground">
                        {o.orderNumber}
                        <span className="font-normal text-foreground/55"> · {o.buyerName}</span>
                      </p>
                      <p className="mt-0.5 flex items-center gap-2 text-xs text-foreground/45">
                        {relativeTime(o.placedAt)}
                        <span className="sm:hidden">
                          <Badge label={SELLER_ORDER_STATUS_LABEL[o.status]} tone={ORDER_TONE[o.status]} />
                        </span>
                      </p>
                    </div>
                    <span className="hidden sm:block">
                      <Badge label={SELLER_ORDER_STATUS_LABEL[o.status]} tone={ORDER_TONE[o.status]} />
                    </span>
                    <p className="shrink-0 text-right text-sm font-semibold text-foreground sm:w-32">
                      {formatCurrency(o.total)}
                    </p>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      </main>
    </>
  );
}
