"use client";

import { useMemo, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge, BadgeTone } from "@/components/Badge";
import { orders as seedOrders } from "@/lib/mock-data";
import { ORDER_STATUS_LABEL, Order, OrderStatus } from "@/lib/types";
import { formatCurrency, formatDateTime } from "@/lib/format";
import clsx from "clsx";

const STATUS_TONE: Record<OrderStatus, BadgeTone> = {
  qabulQilindi: "info",
  tayyorlanmoqda: "warning",
  yolda: "brand",
  yetkazildi: "success",
  bekorQilindi: "danger",
};

const FILTERS: { key: OrderStatus | "all"; label: string }[] = [
  { key: "all", label: "Barchasi" },
  { key: "qabulQilindi", label: "Qabul qilindi" },
  { key: "tayyorlanmoqda", label: "Tayyorlanmoqda" },
  { key: "yolda", label: "Yo'lda" },
  { key: "yetkazildi", label: "Yetkazildi" },
  { key: "bekorQilindi", label: "Bekor qilindi" },
];

export default function OrdersPage() {
  const [orders] = useState<Order[]>(seedOrders);
  const [filter, setFilter] = useState<OrderStatus | "all">("all");
  const [query, setQuery] = useState("");

  const list = useMemo(() => {
    let out = filter === "all" ? orders : orders.filter((o) => o.status === filter);
    const q = query.trim().toLowerCase();
    if (q) {
      out = out.filter(
        (o) =>
          o.orderNumber.toLowerCase().includes(q) ||
          o.buyerName.toLowerCase().includes(q) ||
          o.companyName.toLowerCase().includes(q),
      );
    }
    return [...out].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }, [orders, filter, query]);

  const totalSum = list.reduce((s, o) => s + o.total, 0);

  return (
    <>
      <Topbar
        title="Buyurtmalar"
        subtitle={`${orders.length} ta buyurtma · jami ${formatCurrency(totalSum)}`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex flex-wrap gap-2">
            {FILTERS.map((f) => (
              <button
                key={f.key}
                onClick={() => setFilter(f.key)}
                className={clsx(
                  "rounded-xl px-3.5 py-2 text-xs font-semibold transition-colors",
                  filter === f.key
                    ? "bg-brand text-white shadow-sm shadow-brand/30"
                    : "bg-surface text-foreground/60 hover:bg-surface-muted",
                )}
              >
                {f.label}
              </button>
            ))}
          </div>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Buyurtma raqami, xaridor yoki kompaniya..."
            className="w-full max-w-xs rounded-xl border border-border bg-surface px-4 py-2 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light"
          />
        </div>

        <div className="overflow-hidden rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[880px] text-left text-sm">
              <thead>
                <tr className="border-b border-border text-xs uppercase tracking-wide text-foreground/40">
                  <th className="px-5 py-3 font-medium">Buyurtma</th>
                  <th className="px-5 py-3 font-medium">Xaridor</th>
                  <th className="px-5 py-3 font-medium">Kompaniya</th>
                  <th className="px-5 py-3 font-medium">Manzil</th>
                  <th className="px-5 py-3 font-medium">Summasi</th>
                  <th className="px-5 py-3 font-medium">Holati</th>
                  <th className="px-5 py-3 font-medium">Sana</th>
                </tr>
              </thead>
              <tbody>
                {list.map((o) => (
                  <tr key={o.id} className="border-b border-border last:border-0">
                    <td className="px-5 py-3 font-semibold text-foreground">{o.orderNumber}</td>
                    <td className="px-5 py-3 text-foreground/70">
                      <div>{o.buyerName}</div>
                      <div className="text-xs text-foreground/40">{o.buyerPhone}</div>
                    </td>
                    <td className="px-5 py-3 text-foreground/70">{o.companyName}</td>
                    <td className="max-w-[220px] truncate px-5 py-3 text-xs text-foreground/55">
                      {o.address}
                    </td>
                    <td className="px-5 py-3 font-semibold text-foreground">
                      {formatCurrency(o.total)}
                    </td>
                    <td className="px-5 py-3">
                      <Badge label={ORDER_STATUS_LABEL[o.status]} tone={STATUS_TONE[o.status]} />
                    </td>
                    <td className="px-5 py-3 text-xs text-foreground/45">
                      {formatDateTime(o.date)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {list.length === 0 && (
            <p className="p-8 text-center text-sm text-foreground/40">Hech qanday buyurtma topilmadi.</p>
          )}
        </div>
      </main>
    </>
  );
}
