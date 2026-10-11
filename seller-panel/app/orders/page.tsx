"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge, BadgeTone } from "@/components/Badge";
import { useShell } from "@/components/Shell";
import { errorText, useConfirm, useToast } from "@/components/ui/feedback";
import { fetchSellerOrders, updateSellerOrderStatus } from "@/lib/db";
import {
  SELLER_ORDER_FLOW,
  SELLER_ORDER_STATUS_LABEL,
  SellerOrder,
  SellerOrderStatus,
} from "@/lib/types";
import { formatCurrency, formatDateTime, relativeTime } from "@/lib/format";
import {
  AlertTriangle,
  Ban,
  CheckCircle2,
  ClipboardList,
  Loader2,
  MapPin,
  PackageCheck,
  Phone,
  Search,
  Store,
  Truck,
} from "lucide-react";
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

/** Keyingi qadam tugmasi — holat nomi emas, sotuvchi bajaradigan ish. */
function nextAction(order: SellerOrder) {
  switch (order.status) {
    case "yangi":
      return { label: "Qabul qilish", icon: PackageCheck };
    case "tayyorlanmoqda":
      return {
        label: order.deliveryMethod === "delivery" ? "Yetkazishga tayyor" : "Olib ketishga tayyor",
        icon: Truck,
      };
    case "yetkazishga":
      return {
        label: order.deliveryMethod === "delivery" ? "Yetkazildi" : "Topshirildi",
        icon: CheckCircle2,
      };
    default:
      return null;
  }
}

// Yangi buyurtmalar o'zi paydo bo'lishi uchun ro'yxat shu oraliqda qayta o'qiladi.
const REFRESH_MS = 15_000;

export default function OrdersPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const { refreshAlerts } = useShell();
  const [orders, setOrders] = useState<SellerOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [filter, setFilter] = useState<SellerOrderStatus | "all">("all");
  const [query, setQuery] = useState("");
  // A background refresh must not overwrite a status change still on its way.
  const saving = useRef(false);

  useEffect(() => {
    let cancelled = false;
    const load = () =>
      fetchSellerOrders()
        .then((rows) => {
          if (cancelled || saving.current) return;
          setOrders(rows);
          setError(null);
        })
        .catch((err) => {
          if (!cancelled) setError(errorText(err, "Buyurtmalarni yuklab bo'lmadi."));
        })
        .finally(() => {
          if (!cancelled) setLoading(false);
        });
    void load();
    const timer = setInterval(() => {
      if (!document.hidden && !saving.current) void load();
    }, REFRESH_MS);
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
    const q = query.trim().toLowerCase();
    const digits = q.replace(/\D/g, "");
    return orders
      .filter((o) => filter === "all" || o.status === filter)
      .filter(
        (o) =>
          !q ||
          o.orderNumber.toLowerCase().includes(q) ||
          o.buyerName.toLowerCase().includes(q) ||
          (digits.length >= 3 && o.buyerPhone.replace(/\D/g, "").includes(digits)) ||
          o.items.some((i) => i.productName.toLowerCase().includes(q)),
      )
      .sort((a, b) => new Date(b.placedAt).getTime() - new Date(a.placedAt).getTime());
  }, [orders, filter, query]);

  async function move(order: SellerOrder, to: SellerOrderStatus) {
    saving.current = true;
    setBusyId(order.id);
    try {
      const saved = await updateSellerOrderStatus(order.id, order.status, to);
      setOrders((prev) => prev.map((o) => (o.id === saved.id ? saved : o)));
      if (saved.status !== to) {
        toast.info(
          `${saved.orderNumber}: holati allaqachon "${SELLER_ORDER_STATUS_LABEL[saved.status]}" — ro'yxat yangilandi.`,
        );
      } else {
        toast.success(`${saved.orderNumber} — ${SELLER_ORDER_STATUS_LABEL[to].toLowerCase()}.`);
      }
      refreshAlerts();
    } catch (err) {
      toast.error(`Holat saqlanmadi: ${errorText(err)}`);
    } finally {
      saving.current = false;
      setBusyId(null);
    }
  }

  function advance(order: SellerOrder) {
    const idx = SELLER_ORDER_FLOW.indexOf(order.status);
    if (idx === -1 || idx === SELLER_ORDER_FLOW.length - 1) return;
    void move(order, SELLER_ORDER_FLOW[idx + 1]);
  }

  async function cancel(order: SellerOrder) {
    const ok = await confirm({
      title: `${order.orderNumber} ni bekor qilasizmi?`,
      message: "Xaridor ilovada buyurtma bekor qilinganini ko'radi. Iloji bo'lsa, avval unga qo'ng'iroq qiling.",
      confirmLabel: "Bekor qilish",
      cancelLabel: "Ortga",
      danger: true,
    });
    if (ok) void move(order, "bekorQilindi");
  }

  return (
    <>
      <Topbar
        title="Buyurtmalar"
        subtitle={`${orders.length} ta buyurtma · ${counts.yangi ?? 0} tasi yangi`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-4 sm:p-6">
        {error && (
          <p className="flex items-start gap-2 rounded-xl border border-warning/30 bg-warning-tint px-4 py-3 text-sm text-foreground/75">
            <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-warning" />
            {error}
          </p>
        )}

        <label className="relative block">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-foreground/35" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Raqam, xaridor, telefon yoki mahsulot bo'yicha qidirish..."
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

        <div className="space-y-3">
          {list.map((o) => {
            const action = nextAction(o);
            const busy = busyId === o.id;
            const step = SELLER_ORDER_FLOW.indexOf(o.status);
            return (
              <article
                key={o.id}
                className={clsx(
                  "rounded-2xl border bg-surface p-4 shadow-sm shadow-black/[0.02] sm:p-5",
                  o.status === "yangi" ? "border-info/40" : "border-border",
                )}
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="font-bold text-foreground">{o.orderNumber}</p>
                      <Badge label={SELLER_ORDER_STATUS_LABEL[o.status]} tone={STATUS_TONE[o.status]} dot />
                    </div>
                    <p className="mt-1 text-xs text-foreground/45" title={formatDateTime(o.placedAt)}>
                      {relativeTime(o.placedAt)} · {formatDateTime(o.placedAt)}
                    </p>
                  </div>
                  <p className="text-lg font-bold text-brand">{formatCurrency(o.total)}</p>
                </div>

                {step >= 0 && (
                  <div className="mt-3 flex gap-1" aria-hidden>
                    {SELLER_ORDER_FLOW.map((s, i) => (
                      <span
                        key={s}
                        className={clsx("h-1 flex-1 rounded-full", i <= step ? "bg-brand" : "bg-surface-muted")}
                      />
                    ))}
                  </div>
                )}

                <div className="mt-3 grid grid-cols-1 gap-x-6 gap-y-1.5 text-sm text-foreground/70 sm:grid-cols-2">
                  <p className="flex min-w-0 items-center gap-2">
                    <Phone className="h-3.5 w-3.5 shrink-0 text-foreground/35" />
                    <span className="truncate">{o.buyerName}</span>
                    {o.buyerPhone && (
                      <a href={`tel:${o.buyerPhone}`} className="shrink-0 font-medium text-brand hover:underline">
                        {o.buyerPhone}
                      </a>
                    )}
                  </p>
                  {o.deliveryMethod === "delivery" ? (
                    <p className="flex min-w-0 items-start gap-2">
                      <MapPin className="mt-0.5 h-3.5 w-3.5 shrink-0 text-foreground/35" />
                      <span>{o.address || "Manzil ko'rsatilmagan"}</span>
                    </p>
                  ) : (
                    <p className="flex items-center gap-2">
                      <Store className="h-3.5 w-3.5 text-foreground/35" /> O&apos;zi olib ketadi
                    </p>
                  )}
                </div>

                <ul className="mt-3 space-y-1 rounded-xl bg-surface-muted px-3.5 py-2.5 text-xs text-foreground/60">
                  {o.items.map((item, i) => (
                    <li key={i} className="flex justify-between gap-3">
                      <span className="min-w-0">
                        {item.productName} × {item.quantity}
                      </span>
                      <span className="shrink-0 font-medium text-foreground/70">
                        {formatCurrency(item.price * item.quantity)}
                      </span>
                    </li>
                  ))}
                </ul>

                {action && (
                  <div className="mt-4 flex flex-col gap-2 sm:flex-row">
                    <button
                      onClick={() => advance(o)}
                      disabled={busy}
                      className="flex items-center justify-center gap-1.5 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark disabled:opacity-60 sm:py-2 sm:text-xs"
                    >
                      {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <action.icon className="h-4 w-4" />}
                      {action.label}
                    </button>
                    <button
                      onClick={() => cancel(o)}
                      disabled={busy}
                      className="flex items-center justify-center gap-1.5 rounded-xl border border-danger/30 px-4 py-2.5 text-sm font-semibold text-danger hover:bg-danger-tint disabled:opacity-60 sm:py-2 sm:text-xs"
                    >
                      <Ban className="h-3.5 w-3.5" /> Bekor qilish
                    </button>
                  </div>
                )}
              </article>
            );
          })}
          {list.length === 0 && (
            <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-border px-6 py-16 text-center">
              {loading ? (
                <Loader2 className="h-6 w-6 animate-spin text-foreground/30" />
              ) : (
                <ClipboardList className="h-8 w-8 text-foreground/25" />
              )}
              <p className="text-sm text-foreground/45">
                {loading
                  ? "Yuklanmoqda…"
                  : query
                    ? "Qidiruv bo'yicha buyurtma topilmadi."
                    : "Bu bo'limda hozircha buyurtma yo'q."}
              </p>
            </div>
          )}
        </div>
      </main>
    </>
  );
}
