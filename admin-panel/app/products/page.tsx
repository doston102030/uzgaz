"use client";

import { useEffect, useMemo, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge, CategoryTag } from "@/components/Badge";
import { fetchProducts, updateProductModeration } from "@/lib/db";
import { ModerationStatus, Product, CATEGORY_COLOR, CATEGORY_LABEL } from "@/lib/types";
import { formatCurrency } from "@/lib/format";
import { Check, X, Clock, Loader2 } from "lucide-react";
import clsx from "clsx";

const TABS: { key: ModerationStatus; label: string }[] = [
  { key: "pending", label: "Kutilmoqda" },
  { key: "approved", label: "Faol" },
  { key: "rejected", label: "Rad etilgan" },
];

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [tab, setTab] = useState<ModerationStatus>("pending");
  const [savingId, setSavingId] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    fetchProducts()
      .then((rows) => {
        if (!cancelled) setProducts(rows);
      })
      .catch((err) => {
        if (!cancelled) {
          setLoadError(err instanceof Error ? err.message : "Mahsulotlarni yuklab bo'lmadi.");
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const counts = useMemo(
    () => ({
      pending: products.filter((p) => p.moderationStatus === "pending").length,
      approved: products.filter((p) => p.moderationStatus === "approved").length,
      rejected: products.filter((p) => p.moderationStatus === "rejected").length,
    }),
    [products],
  );

  const list = products.filter((p) => p.moderationStatus === tab);

  async function setStatus(id: string, status: ModerationStatus, reason?: string) {
    const prev = products;
    setSavingId(id);
    setProducts((cur) =>
      cur.map((p) => (p.id === id ? { ...p, moderationStatus: status, rejectionReason: reason } : p)),
    );
    try {
      await updateProductModeration(id, status, reason);
    } catch (err) {
      setProducts(prev);
      alert(
        `Holatni yangilab bo'lmadi: ${err instanceof Error ? err.message : "noma'lum xatolik"}`,
      );
    } finally {
      setSavingId(null);
    }
  }

  return (
    <>
      <Topbar
        title="Mahsulotlar moderatsiyasi"
        subtitle={`${products.length} ta mahsulot · ${counts.pending} tasi tekshiruv kutmoqda`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-6">
        <div className="flex gap-2">
          {TABS.map((t) => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={clsx(
                "flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition-colors",
                tab === t.key
                  ? "bg-brand text-white shadow-sm shadow-brand/30"
                  : "bg-surface text-foreground/60 hover:bg-surface-muted",
              )}
            >
              {t.label}
              <span
                className={clsx(
                  "rounded-full px-1.5 py-0.5 text-xs",
                  tab === t.key ? "bg-white/20" : "bg-surface-muted",
                )}
              >
                {counts[t.key]}
              </span>
            </button>
          ))}
        </div>

        {loadError && (
          <p className="rounded-2xl border border-danger/30 bg-danger-tint px-4 py-3 text-sm text-danger">
            Mahsulotlarni yuklab bo&apos;lmadi: {loadError}
          </p>
        )}

        {loading && (
          <div className="flex items-center justify-center gap-2 py-16 text-sm text-foreground/40">
            <Loader2 className="h-4 w-4 animate-spin" /> Yuklanmoqda...
          </div>
        )}

        {!loading && (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
          {list.map((p) => (
            <div
              key={p.id}
              className="overflow-hidden rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]"
            >
              <div className="relative h-36 w-full bg-surface-muted">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={p.imageUrl} alt={p.name} className="h-full w-full object-cover" />
                <div className="absolute left-2 top-2">
                  <CategoryTag
                    label={CATEGORY_LABEL[p.categoryId]}
                    color={CATEGORY_COLOR[p.categoryId]}
                  />
                </div>
              </div>
              <div className="p-4">
                <p className="font-semibold text-foreground">{p.name}</p>
                <p className="mt-0.5 text-xs text-foreground/45">{p.companyName}</p>
                <p className="mt-2 text-sm font-bold text-brand">{formatCurrency(p.price)}</p>
                <p className="mt-2 line-clamp-2 text-xs text-foreground/55">{p.description}</p>

                {p.moderationStatus === "rejected" && p.rejectionReason && (
                  <p className="mt-2 rounded-lg bg-danger-tint px-2.5 py-1.5 text-xs text-danger">
                    {p.rejectionReason}
                  </p>
                )}

                {p.moderationStatus === "pending" && (
                  <div className="mt-4 flex gap-2">
                    {savingId === p.id ? (
                      <div className="flex flex-1 items-center justify-center py-2">
                        <Loader2 className="h-4 w-4 animate-spin text-foreground/40" />
                      </div>
                    ) : (
                      <>
                        <button
                          onClick={() => setStatus(p.id, "approved")}
                          className="flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-success py-2 text-xs font-semibold text-white hover:brightness-95"
                        >
                          <Check className="h-3.5 w-3.5" /> Tasdiqlash
                        </button>
                        <button
                          onClick={() =>
                            setStatus(
                              p.id,
                              "rejected",
                              "Admin tomonidan rad etildi — talablarga javob bermaydi.",
                            )
                          }
                          className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-danger/30 py-2 text-xs font-semibold text-danger hover:bg-danger-tint"
                        >
                          <X className="h-3.5 w-3.5" /> Rad etish
                        </button>
                      </>
                    )}
                  </div>
                )}

                {p.moderationStatus !== "pending" && (
                  <div className="mt-4">
                    <Badge
                      label={p.moderationStatus === "approved" ? "Faol" : "Rad etilgan"}
                      tone={p.moderationStatus === "approved" ? "success" : "danger"}
                    />
                  </div>
                )}
              </div>
            </div>
          ))}
          {list.length === 0 && (
            <div className="col-span-full flex flex-col items-center gap-2 rounded-2xl border border-dashed border-border py-16 text-foreground/40">
              <Clock className="h-6 w-6" />
              <p className="text-sm">Bu bo&apos;limda hozircha mahsulot yo&apos;q.</p>
            </div>
          )}
        </div>
        )}
      </main>
    </>
  );
}
