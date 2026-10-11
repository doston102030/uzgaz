"use client";

import { useEffect, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { HeroBanner } from "@/components/HeroBanner";
import { StatCard } from "@/components/StatCard";
import { RevenueChart } from "@/components/RevenueChart";
import { Badge, CategoryTag } from "@/components/Badge";
import { fetchCategories, fetchOrders, fetchProducts, fetchSellers } from "@/lib/db";
import { categoryColor, categoryLabel, DEFAULT_CATEGORIES, ProductCategory } from "@/lib/categories";
import { formatCurrency, formatCurrencyShort, relativeTime } from "@/lib/format";
import { revenueByDay } from "@/lib/stats";
import {
  ORDER_STATUS_LABEL,
  Order,
  OrderStatus,
  Product,
  Seller,
} from "@/lib/types";
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
  const [sellers, setSellers] = useState<Seller[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [categories, setCategories] = useState<ProductCategory[]>(DEFAULT_CATEGORIES);

  useEffect(() => {
    let cancelled = false;
    const load = () => {
      // Each block is optional — one failing (e.g. orders before the SQL
      // runs) leaves the others' numbers on screen.
      fetchSellers()
        .then((rows) => !cancelled && setSellers(rows))
        .catch(() => {});
      fetchProducts()
        .then((rows) => !cancelled && setProducts(rows))
        .catch(() => {});
      fetchOrders()
        .then((rows) => !cancelled && setOrders(rows))
        .catch(() => {});
    };
    load();
    fetchCategories()
      .then(({ categories, ready }) => !cancelled && ready && setCategories(categories))
      .catch(() => {});
    const timer = setInterval(() => {
      if (!document.hidden) load();
    }, 30_000);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, []);

  const revenue = revenueByDay(orders, 14);
  const periodRevenue = revenue.reduce((sum, d) => sum + d.revenue, 0);
  const activeSellers = sellers.filter((s) => s.status === "approved").length;
  const pendingSellers = sellers.filter((s) => s.status === "pending");
  const pendingProducts = products.filter((p) => p.moderationStatus === "pending");
  const pendingApprovals = pendingSellers.length + pendingProducts.length;
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);
  const todayOrders = orders.filter((o) => new Date(o.date) >= startOfToday);

  const recentOrders = orders.slice(0, 5);

  const productsByCategory = new Map<string, number>();
  for (const p of products) {
    productsByCategory.set(p.categoryId, (productsByCategory.get(p.categoryId) ?? 0) + 1);
  }

  return (
    <>
      <Topbar
        title="Boshqaruv paneli"
        subtitle={`${sellers.length} ta kompaniya · Andijon viloyati bo'yicha`}
      />
      <main className="flex-1 space-y-6 overflow-y-auto p-4 sm:p-6">
        <HeroBanner companyCount={sellers.length} activeSellerCount={activeSellers} />

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard
            label="Bugungi buyurtmalar"
            value={String(todayOrders.length)}
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
              <Link href="/sellers?tab=pending" className="text-xs font-semibold text-brand hover:underline">
                Barchasi
              </Link>
            </div>
            <div className="mt-3 space-y-3">
              {pendingSellers.slice(0, 4).map((s) => (
                <Link
                  key={s.id}
                  href="/sellers?tab=pending"
                  className="flex items-center gap-3 rounded-xl bg-surface-muted p-3 transition-colors hover:bg-brand-tint"
                >
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
                </Link>
              ))}
              {pendingProducts.slice(0, 4).map((p) => (
                <Link
                  key={p.id}
                  href="/products"
                  className="flex items-center gap-3 rounded-xl bg-surface-muted p-3 transition-colors hover:bg-brand-tint"
                >
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
                </Link>
              ))}
              {pendingApprovals > 8 && (
                <p className="text-center text-xs text-foreground/45">va yana {pendingApprovals - 8} ta…</p>
              )}
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
          {recentOrders.length === 0 ? (
            <p className="px-5 py-10 text-center text-sm text-foreground/40">Hozircha buyurtma yo&apos;q.</p>
          ) : (
            <ul className="mt-3 divide-y divide-border border-t border-border">
              {recentOrders.map((o) => (
                <li key={o.id}>
                  <Link href="/orders" className="flex items-center gap-3 px-5 py-3 hover:bg-surface-muted/60">
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold text-foreground">
                        {o.orderNumber}
                        <span className="font-normal text-foreground/55">
                          {" "}
                          · {o.buyerName} → {o.companyName}
                        </span>
                      </p>
                      <p className="mt-0.5 flex items-center gap-2 text-xs text-foreground/45">
                        {relativeTime(o.date)}
                        <span className="sm:hidden">
                          <Badge label={ORDER_STATUS_LABEL[o.status]} tone={ORDER_TONE[o.status]} />
                        </span>
                      </p>
                    </div>
                    <span className="hidden sm:block">
                      <Badge label={ORDER_STATUS_LABEL[o.status]} tone={ORDER_TONE[o.status]} />
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

        <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
          <h2 className="text-sm font-bold text-foreground">Kategoriyalar bo&apos;yicha mahsulotlar</h2>
          <div className="mt-4 flex flex-wrap gap-2">
            {[...productsByCategory.entries()].map(([id, count]) => (
              <CategoryTag
                key={id}
                label={`${categoryLabel(id, categories)} · ${count}`}
                color={categoryColor(id)}
              />
            ))}
            {productsByCategory.size === 0 && (
              <p className="text-xs text-foreground/45">Hali mahsulot yo&apos;q.</p>
            )}
          </div>
        </div>
      </main>
    </>
  );
}
