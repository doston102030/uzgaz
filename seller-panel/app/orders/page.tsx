"use client";

import { useMemo, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge, BadgeTone } from "@/components/Badge";
import { orders as seedOrders } from "@/lib/mock-data";
import {
  SELLER_ORDER_FLOW,
  SELLER_ORDER_STATUS_LABEL,
  SellerOrder,
  SellerOrderStatus,
} from "@/lib/types";
import { formatCurrency, formatDateTime } from "@/lib/format";
import { ArrowRight, Ban, MapPin, Phone, Store } from "lucide-react";
import clsx from "clsx";

const STATUS_TONE: Record<SellerOrderStatus, BadgeTone> = {
  yangi: "info",
  tayyorlanmoqda: "warning",
  yetkazishga: "brand",
  yopildi: "success",
  bekorQilindi: "danger",
};

const FILTERS: { key: SellerOrderStatus | "all"; label: string }[] = [
  { key: "all", label: "Barchasi" },
  { key: "yangi", label: "Yangi" },
  { key: "tayyorlanmoqda", label: "Tayyorlanmoqda" },
  { key: "yetkazishga", label: "Yetkazishga tayyor" },
  { key: "yopildi", label: "Yopildi" },
  { key: "bekorQilindi", label: "Bekor qilindi" },
];

export default function OrdersPage() {
  const [orders, setOrders] = useState<SellerOrder[]>(seedOrders);
  const [filter, setFilter] = useState<SellerOrderStatus | "all">("all");

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: orders.length };
    for (const o of orders) c[o.status] = (c[o.status] ?? 0) + 1;
    return c;
  }, [orders]);

  const list = (filter === "all" ? orders : orders.filter((o) => o.status === filter))
    .slice()
    .sort((a, b) => new Date(b.placedAt).getTime() - new Date(a.placedAt).getTime());

  function advance(id: string) {
    setOrders((prev) =>
      prev.map((o) => {
        if (o.id !== id) return o;
        const idx = SELLER_ORDER_FLOW.indexOf(o.status);
        if (idx === -1 || idx === SELLER_ORDER_FLOW.length - 1) return o;
        return { ...o, status: SELLER_ORDER_FLOW[idx + 1] };
      }),
    );
  }

  function cancel(id: string) {
    setOrders((prev) => prev.map((o) => (o.id === id ? { ...o, status: "bekorQilindi" } : o)));
  }

  return (
    <>
      <Topbar title="Buyurtmalar" subtitle={`${orders.length} ta buyurtma`} />
      <main className="flex-1 space-y-4 overflow-y-auto p-6">
        <div className="flex flex-wrap gap-2">
          {FILTERS.map((f) => (
            <button
              key={f.key}
              onClick={() => setFilter(f.key)}
              className={clsx(
                "flex items-center gap-2 rounded-xl px-3.5 py-2 text-xs font-semibold transition-colors",
                filter === f.key
                  ? "bg-brand text-white shadow-sm shadow-brand/30"
                  : "bg-surface text-foreground/60 hover:bg-surface-muted",
              )}
            >
              {f.label}
              <span
                className={clsx(
                  "rounded-full px-1.5 py-0.5 text-xs",
                  filter === f.key ? "bg-white/20" : "bg-surface-muted",
                )}
              >
                {counts[f.key] ?? 0}
              </span>
            </button>
          ))}
        </div>

        <div className="space-y-3">
          {list.map((o) => {
            const idx = SELLER_ORDER_FLOW.indexOf(o.status);
            const canAdvance = idx !== -1 && idx < SELLER_ORDER_FLOW.length - 1;
            const nextLabel = canAdvance ? SELLER_ORDER_STATUS_LABEL[SELLER_ORDER_FLOW[idx + 1]] : null;

            return (
              <div
                key={o.id}
                className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="font-bold text-foreground">{o.orderNumber}</p>
                      <Badge label={SELLER_ORDER_STATUS_LABEL[o.status]} tone={STATUS_TONE[o.status]} />
                    </div>
                    <p className="mt-1 text-xs text-foreground/45">{formatDateTime(o.placedAt)}</p>
                  </div>
                  <p className="text-lg font-bold text-brand">{formatCurrency(o.total)}</p>
                </div>

                <div className="mt-3 grid grid-cols-1 gap-x-6 gap-y-1 text-sm text-foreground/70 sm:grid-cols-2">
                  <p className="flex items-center gap-2">
                    <Phone className="h-3.5 w-3.5 text-foreground/35" /> {o.buyerName} · {o.buyerPhone}
                  </p>
                  {o.deliveryMethod === "delivery" ? (
                    <p className="flex items-center gap-2">
                      <MapPin className="h-3.5 w-3.5 text-foreground/35" /> {o.address}
                    </p>
                  ) : (
                    <p className="flex items-center gap-2">
                      <Store className="h-3.5 w-3.5 text-foreground/35" /> O&apos;zi olib ketadi
                    </p>
                  )}
                </div>

                <ul className="mt-3 space-y-1 rounded-xl bg-surface-muted px-3.5 py-2.5 text-xs text-foreground/60">
                  {o.items.map((item, i) => (
                    <li key={i} className="flex justify-between">
                      <span>
                        {item.productName} × {item.quantity}
                      </span>
                      <span className="font-medium text-foreground/70">
                        {formatCurrency(item.price * item.quantity)}
                      </span>
                    </li>
                  ))}
                </ul>

                {o.status !== "yopildi" && o.status !== "bekorQilindi" && (
                  <div className="mt-4 flex gap-2">
                    {canAdvance && (
                      <button
                        onClick={() => advance(o.id)}
                        className="flex items-center gap-1.5 rounded-xl bg-brand px-4 py-2 text-xs font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
                      >
                        {nextLabel} qilish <ArrowRight className="h-3.5 w-3.5" />
                      </button>
                    )}
                    <button
                      onClick={() => cancel(o.id)}
                      className="flex items-center gap-1.5 rounded-xl border border-danger/30 px-4 py-2 text-xs font-semibold text-danger hover:bg-danger-tint"
                    >
                      <Ban className="h-3.5 w-3.5" /> Bekor qilish
                    </button>
                  </div>
                )}
              </div>
            );
          })}
          {list.length === 0 && (
            <p className="rounded-2xl border border-dashed border-border py-16 text-center text-sm text-foreground/40">
              Bu bo&apos;limda hozircha buyurtma yo&apos;q.
            </p>
          )}
        </div>
      </main>
    </>
  );
}
