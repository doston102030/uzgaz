"use client";

import { useMemo, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge, CategoryTag } from "@/components/Badge";
import { products as seedProducts } from "@/lib/mock-data";
import {
  CATEGORY_COLOR,
  CATEGORY_LABEL,
  ModerationStatus,
  SellerProduct,
  ServiceCategory,
} from "@/lib/types";
import { formatCurrency } from "@/lib/format";
import { Plus, Pencil, Trash2, X } from "lucide-react";
import clsx from "clsx";

const CATALOG =
  "https://haurszcvivpqdyenfwbb.supabase.co/storage/v1/object/public/product-images/catalog";

const TABS: { key: ModerationStatus | "all"; label: string }[] = [
  { key: "all", label: "Barchasi" },
  { key: "approved", label: "Faol" },
  { key: "pending", label: "Moderatsiyada" },
  { key: "rejected", label: "Rad etilgan" },
];

const EMPTY_FORM = {
  name: "",
  categoryId: "gazBallon" as ServiceCategory,
  price: "",
  unit: "dona",
  stockQty: "",
  description: "",
};

export default function ProductsPage() {
  const [products, setProducts] = useState<SellerProduct[]>(seedProducts);
  const [tab, setTab] = useState<ModerationStatus | "all">("all");
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: products.length };
    for (const p of products) c[p.moderationStatus] = (c[p.moderationStatus] ?? 0) + 1;
    return c;
  }, [products]);

  const list = tab === "all" ? products : products.filter((p) => p.moderationStatus === tab);

  function removeProduct(id: string) {
    setProducts((prev) => prev.filter((p) => p.id !== id));
  }

  function submitForm(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name.trim() || !form.price) return;
    const newProduct: SellerProduct = {
      id: `sp${Date.now()}`,
      name: form.name.trim(),
      imageUrl: `${CATALOG}/${form.categoryId}.jpg`,
      categoryId: form.categoryId,
      description: form.description.trim() || "Tavsif kiritilmagan.",
      price: Number(form.price),
      unit: form.unit,
      stockQty: Number(form.stockQty) || 0,
      moderationStatus: "pending",
      createdAt: "2025-09-12",
    };
    setProducts((prev) => [newProduct, ...prev]);
    setForm(EMPTY_FORM);
    setShowForm(false);
    setTab("pending");
  }

  return (
    <>
      <Topbar
        title="Mahsulotlarim"
        subtitle={`${products.length} ta mahsulot · ${counts.pending ?? 0} tasi moderatsiyada`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex flex-wrap gap-2">
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
                  {counts[t.key] ?? 0}
                </span>
              </button>
            ))}
          </div>
          <button
            onClick={() => setShowForm(true)}
            className="flex items-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
          >
            <Plus className="h-4 w-4" /> Mahsulot qo&apos;shish
          </button>
        </div>

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
                  <CategoryTag label={CATEGORY_LABEL[p.categoryId]} color={CATEGORY_COLOR[p.categoryId]} />
                </div>
              </div>
              <div className="p-4">
                <div className="flex items-start justify-between gap-2">
                  <p className="font-semibold text-foreground">{p.name}</p>
                  <Badge
                    label={
                      p.moderationStatus === "approved"
                        ? "Faol"
                        : p.moderationStatus === "pending"
                          ? "Moderatsiyada"
                          : "Rad etilgan"
                    }
                    tone={
                      p.moderationStatus === "approved"
                        ? "success"
                        : p.moderationStatus === "pending"
                          ? "warning"
                          : "danger"
                    }
                  />
                </div>
                <p className="mt-2 text-sm font-bold text-brand">
                  {formatCurrency(p.price)} <span className="text-foreground/40">/ {p.unit}</span>
                </p>
                <p className="mt-1 text-xs text-foreground/50">Ombordagi soni: {p.stockQty}</p>
                <p className="mt-2 line-clamp-2 text-xs text-foreground/55">{p.description}</p>
                {p.rejectionReason && (
                  <p className="mt-2 rounded-lg bg-danger-tint px-2.5 py-1.5 text-xs text-danger">
                    {p.rejectionReason}
                  </p>
                )}
                <div className="mt-4 flex gap-2">
                  <button className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-border py-2 text-xs font-semibold text-foreground/70 hover:bg-surface-muted">
                    <Pencil className="h-3.5 w-3.5" /> Tahrirlash
                  </button>
                  <button
                    onClick={() => removeProduct(p.id)}
                    className="flex items-center justify-center gap-1.5 rounded-xl border border-danger/30 px-3 py-2 text-xs font-semibold text-danger hover:bg-danger-tint"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {list.length === 0 && (
          <p className="rounded-2xl border border-dashed border-border py-16 text-center text-sm text-foreground/40">
            Bu bo&apos;limda hozircha mahsulot yo&apos;q.
          </p>
        )}
      </main>

      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-surface p-6 shadow-xl">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-bold text-foreground">Yangi mahsulot qo&apos;shish</h2>
              <button
                onClick={() => setShowForm(false)}
                className="flex h-8 w-8 items-center justify-center rounded-lg text-foreground/50 hover:bg-surface-muted"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
            <form onSubmit={submitForm} className="mt-4 space-y-3">
              <Field label="Mahsulot nomi">
                <input
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  required
                  className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
                />
              </Field>
              <Field label="Kategoriya">
                <select
                  value={form.categoryId}
                  onChange={(e) =>
                    setForm({ ...form, categoryId: e.target.value as ServiceCategory })
                  }
                  className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
                >
                  {Object.entries(CATEGORY_LABEL).map(([key, label]) => (
                    <option key={key} value={key}>
                      {label}
                    </option>
                  ))}
                </select>
              </Field>
              <div className="grid grid-cols-2 gap-3">
                <Field label="Narxi (so'm)">
                  <input
                    type="number"
                    value={form.price}
                    onChange={(e) => setForm({ ...form, price: e.target.value })}
                    required
                    className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
                  />
                </Field>
                <Field label="Miqdori (dona)">
                  <input
                    type="number"
                    value={form.stockQty}
                    onChange={(e) => setForm({ ...form, stockQty: e.target.value })}
                    className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
                  />
                </Field>
              </div>
              <Field label="Tavsif">
                <textarea
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  rows={3}
                  className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
                />
              </Field>
              <p className="text-xs text-foreground/45">
                Yangi mahsulot qo&apos;shilgach, u admin tomonidan tekshirilgunga qadar
                &quot;Moderatsiyada&quot; holatida turadi.
              </p>
              <button
                type="submit"
                className="w-full rounded-xl bg-brand py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
              >
                Yuborish
              </button>
            </form>
          </div>
        </div>
      )}
    </>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="text-xs font-medium text-foreground/55">{label}</span>
      <div className="mt-1.5">{children}</div>
    </label>
  );
}
