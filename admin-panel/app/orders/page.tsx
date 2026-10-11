"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Topbar } from "@/components/Topbar";
import { Badge, BadgeTone } from "@/components/Badge";
import { useShell } from "@/components/Shell";
import { Modal, ModalButton } from "@/components/ui/Modal";
import { errorText, useConfirm, useToast } from "@/components/ui/feedback";
import { fetchOrders, updateOrderStatus } from "@/lib/db";
import { ORDER_STATUS_LABEL, Order, OrderStatus } from "@/lib/types";
import { formatCurrency, formatDateTime, relativeTime } from "@/lib/format";
import { Ban, ClipboardList, Loader2, MapPin, Phone, Search, Store } from "lucide-react";
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

const isOpen = (o: Order) => o.status !== "yetkazildi" && o.status !== "bekorQilindi";

export default function OrdersPage() {
  return (
    <Suspense fallback={null}>
      <OrdersPageContent />
    </Suspense>
  );
}

function OrdersPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const toast = useToast();
  const confirm = useConfirm();
  const { refreshAlerts } = useShell();
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<OrderStatus | "all">("all");
  const [query, setQuery] = useState("");
  const [viewing, setViewing] = useState<Order | null>(null);
  const [cancelling, setCancelling] = useState(false);

  // Bell link ?status=qabulQilindi: pick the filter once, then clean the URL.
  const statusParam = searchParams.get("status");
  const [seenStatusParam, setSeenStatusParam] = useState<string | null>(null);
  if (statusParam !== seenStatusParam) {
    setSeenStatusParam(statusParam);
    const wanted = FILTERS.find((f) => f.key === statusParam);
    if (wanted) setFilter(wanted.key);
  }
  useEffect(() => {
    if (statusParam) router.replace("/orders");
  }, [statusParam, router]);

  useEffect(() => {
    let cancelled = false;
    const load = () =>
      fetchOrders()
        .then((rows) => {
          if (cancelled) return;
          setOrders(rows);
          setError(null);
        })
        .catch((err) => {
          if (!cancelled) setError(errorText(err, "Buyurtmalar yuklanmadi."));
        })
        .finally(() => {
          if (!cancelled) setLoading(false);
        });
    void load();
    // Sotuvchilar holatni o'zgartirganda ro'yxat o'zi yangilanadi.
    const timer = setInterval(() => {
      if (!document.hidden) void load();
    }, 15_000);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, []);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: orders.length };
    for (const o of orders) c[o.status] = (c[o.status] ?? 0) + 1;
    return c;
  }, [orders]);

  const list = useMemo(() => {
    let out = filter === "all" ? orders : orders.filter((o) => o.status === filter);
    const q = query.trim().toLowerCase();
    const digits = q.replace(/\D/g, "");
    if (q) {
      out = out.filter(
        (o) =>
          o.orderNumber.toLowerCase().includes(q) ||
          o.buyerName.toLowerCase().includes(q) ||
          (digits.length >= 3 && o.buyerPhone.replace(/\D/g, "").includes(digits)) ||
          o.companyName.toLowerCase().includes(q),
      );
    }
    return [...out].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }, [orders, filter, query]);

  const totalSum = list.filter((o) => o.status !== "bekorQilindi").reduce((s, o) => s + o.total, 0);

  async function cancelOrder(order: Order) {
    const ok = await confirm({
      title: `${order.orderNumber} ni bekor qilasizmi?`,
      message: "Administrator qarori: xaridor va sotuvchi buyurtma bekor qilinganini ko'radi.",
      confirmLabel: "Bekor qilish",
      cancelLabel: "Ortga",
      danger: true,
    });
    if (!ok) return;
    setCancelling(true);
    try {
      await updateOrderStatus(order.id, "bekorQilindi");
      const updated = { ...order, status: "bekorQilindi" as const };
      setOrders((cur) => cur.map((o) => (o.id === order.id ? updated : o)));
      setViewing(updated);
      toast.success(`${order.orderNumber} bekor qilindi.`);
      refreshAlerts();
    } catch (err) {
      toast.error(`Bekor qilib bo'lmadi: ${errorText(err)}`);
    } finally {
      setCancelling(false);
    }
  }

  return (
    <>
      <Topbar
        title="Buyurtmalar"
        subtitle={`${list.length} ta buyurtma · jami ${formatCurrency(totalSum)}`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-4 sm:p-6">
        {error && (
          <p className="rounded-xl border border-warning/30 bg-warning-tint px-4 py-3 text-sm text-foreground/75">
            {error}
          </p>
        )}

        <label className="relative block">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-foreground/35" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Buyurtma raqami, xaridor, telefon yoki kompaniya..."
            className="w-full rounded-xl border border-border bg-surface py-2.5 pl-10 pr-3 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light"
          />
        </label>

        <div className="no-scrollbar -mx-4 flex gap-2 overflow-x-auto px-4 sm:mx-0 sm:flex-wrap sm:px-0">
          {FILTERS.map((f) => (
            <button
              key={f.key}
              onClick={() => setFilter(f.key)}
              className={clsx(
                "flex shrink-0 items-center gap-2 rounded-xl px-3.5 py-2 text-xs font-semibold transition-colors",
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

        {list.length === 0 ? (
          <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-border px-6 py-16 text-center">
            {loading ? (
              <Loader2 className="h-6 w-6 animate-spin text-foreground/30" />
            ) : (
              <ClipboardList className="h-8 w-8 text-foreground/25" />
            )}
            <p className="text-sm text-foreground/45">
              {loading ? "Yuklanmoqda…" : query ? "Qidiruv bo'yicha buyurtma topilmadi." : "Hech qanday buyurtma topilmadi."}
            </p>
          </div>
        ) : (
          <>
            {/* Desktop: table */}
            <div className="hidden overflow-hidden rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02] lg:block">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-border text-xs uppercase tracking-wide text-foreground/40">
                    <th className="px-5 py-3 font-medium">Buyurtma</th>
                    <th className="px-5 py-3 font-medium">Xaridor</th>
                    <th className="px-5 py-3 font-medium">Kompaniya</th>
                    <th className="px-5 py-3 font-medium">Manzil</th>
                    <th className="px-5 py-3 font-medium">Summasi</th>
                    <th className="px-5 py-3 font-medium">Holati</th>
                  </tr>
                </thead>
                <tbody>
                  {list.map((o) => (
                    <tr
                      key={o.id}
                      onClick={() => setViewing(o)}
                      className="cursor-pointer border-b border-border last:border-0 hover:bg-surface-muted/60"
                    >
                      <td className="px-5 py-3">
                        <p className="font-semibold text-foreground">{o.orderNumber}</p>
                        <p className="text-xs text-foreground/45">{formatDateTime(o.date)}</p>
                      </td>
                      <td className="px-5 py-3 text-foreground/70">
                        <div>{o.buyerName}</div>
                        <div className="text-xs text-foreground/40">{o.buyerPhone}</div>
                      </td>
                      <td className="px-5 py-3 text-foreground/70">{o.companyName}</td>
                      <td className="max-w-[220px] truncate px-5 py-3 text-xs text-foreground/55">{o.address}</td>
                      <td className="px-5 py-3 font-semibold text-foreground">{formatCurrency(o.total)}</td>
                      <td className="px-5 py-3">
                        <Badge label={ORDER_STATUS_LABEL[o.status]} tone={STATUS_TONE[o.status]} dot />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Phone/tablet: cards */}
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:hidden">
              {list.map((o) => (
                <button
                  key={o.id}
                  onClick={() => setViewing(o)}
                  className="rounded-2xl border border-border bg-surface p-4 text-left shadow-sm shadow-black/[0.02] hover:border-brand-light/60"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-bold text-foreground">{o.orderNumber}</p>
                      <p className="text-xs text-foreground/45">{relativeTime(o.date)}</p>
                    </div>
                    <Badge label={ORDER_STATUS_LABEL[o.status]} tone={STATUS_TONE[o.status]} dot />
                  </div>
                  <p className="mt-2 text-sm text-foreground/70">
                    {o.buyerName} → <span className="font-medium">{o.companyName}</span>
                  </p>
                  <p className="mt-2 text-base font-bold text-brand">{formatCurrency(o.total)}</p>
                </button>
              ))}
            </div>
          </>
        )}
      </main>

      {viewing && (
        <Modal
          title={viewing.orderNumber}
          subtitle={`${formatDateTime(viewing.date)} · ${viewing.companyName}`}
          onClose={() => setViewing(null)}
          busy={cancelling}
          footer={
            <>
              <ModalButton variant="ghost" onClick={() => setViewing(null)} disabled={cancelling}>
                Yopish
              </ModalButton>
              {isOpen(viewing) && (
                <ModalButton variant="danger" onClick={() => cancelOrder(viewing)} disabled={cancelling}>
                  {cancelling ? <Loader2 className="h-4 w-4 animate-spin" /> : <Ban className="h-4 w-4" />}
                  Bekor qilish
                </ModalButton>
              )}
            </>
          }
        >
          <div className="space-y-4">
            <Badge label={ORDER_STATUS_LABEL[viewing.status]} tone={STATUS_TONE[viewing.status]} dot />
            <div className="space-y-2 rounded-xl border border-border p-3.5 text-sm text-foreground/70">
              <p className="flex items-center gap-2">
                <Phone className="h-4 w-4 shrink-0 text-foreground/35" />
                {viewing.buyerName}
                {viewing.buyerPhone && (
                  <a href={`tel:${viewing.buyerPhone}`} className="font-medium text-brand hover:underline">
                    {viewing.buyerPhone}
                  </a>
                )}
              </p>
              <p className="flex items-start gap-2">
                {viewing.address === "O'zi olib ketadi" ? (
                  <Store className="mt-0.5 h-4 w-4 shrink-0 text-foreground/35" />
                ) : (
                  <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-foreground/35" />
                )}
                {viewing.address || "Manzil ko'rsatilmagan"}
              </p>
            </div>
            <ul className="divide-y divide-border rounded-xl bg-surface-muted text-sm">
              {viewing.items.map((item, i) => (
                <li key={i} className="flex justify-between gap-3 px-3.5 py-2.5">
                  <span className="min-w-0 text-foreground/70">
                    {item.productName} <span className="text-foreground/40">× {item.quantity}</span>
                  </span>
                  <span className="shrink-0 font-medium text-foreground">{formatCurrency(item.price * item.quantity)}</span>
                </li>
              ))}
              <li className="flex justify-between px-3.5 py-2.5 text-foreground/55">
                <span>Yetkazish</span>
                <span>{viewing.deliveryFee ? formatCurrency(viewing.deliveryFee) : "Bepul"}</span>
              </li>
              <li className="flex justify-between px-3.5 py-3 font-bold text-foreground">
                <span>Jami</span>
                <span className="text-brand">{formatCurrency(viewing.total)}</span>
              </li>
            </ul>
          </div>
        </Modal>
      )}
    </>
  );
}
