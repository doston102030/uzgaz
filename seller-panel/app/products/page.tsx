"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Topbar } from "@/components/Topbar";
import { Badge, CategoryTag } from "@/components/Badge";
import {
  deleteSellerProduct,
  fetchSellerProducts,
  fetchSellerStatus,
  insertSellerProduct,
  updateSellerProduct,
} from "@/lib/db";
import {
  CATEGORY_COLOR,
  CATEGORY_LABEL,
  ModerationStatus,
  SellerProduct,
  ServiceCategory,
} from "@/lib/types";
import { formatCurrency } from "@/lib/format";
import { uploadProductImage } from "@/lib/supabase";
import { Plus, Pencil, Trash2, X, ImagePlus, Loader2 } from "lucide-react";
import clsx from "clsx";

const MAX_IMAGES = 3;

const CATALOG =
  "https://xasjpasaatswhxmgvvsg.supabase.co/storage/v1/object/public/product-images/catalog";

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
  return (
    <Suspense fallback={null}>
      <ProductsPageContent />
    </Suspense>
  );
}

function ProductsPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [products, setProducts] = useState<SellerProduct[]>([]);
  const [companyName, setCompanyName] = useState("");
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [tab, setTab] = useState<ModerationStatus | "all">("all");
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [imageSlots, setImageSlots] = useState<(string | null)[]>(
    Array(MAX_IMAGES).fill(null),
  );
  const [uploading, setUploading] = useState<boolean[]>(Array(MAX_IMAGES).fill(false));
  const [uploadErrors, setUploadErrors] = useState<(string | null)[]>(
    Array(MAX_IMAGES).fill(null),
  );

  useEffect(() => {
    let cancelled = false;
    Promise.all([fetchSellerProducts(), fetchSellerStatus()])
      .then(([rows, status]) => {
        if (cancelled) return;
        setProducts(rows);
        setCompanyName(status.company_name);
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

  // Hero banner's "Mahsulot qo'shish" quick action deep-links here with
  // ?new=1 so it opens straight into the add form instead of just the list.
  useEffect(() => {
    if (searchParams.get("new") === "1") {
      openAddForm();
      router.replace("/products");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams]);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: products.length };
    for (const p of products) c[p.moderationStatus] = (c[p.moderationStatus] ?? 0) + 1;
    return c;
  }, [products]);

  const list = tab === "all" ? products : products.filter((p) => p.moderationStatus === tab);

  async function removeProduct(id: string) {
    setDeletingId(id);
    try {
      await deleteSellerProduct(id);
      setProducts((prev) => prev.filter((p) => p.id !== id));
    } catch (err) {
      alert(`Mahsulotni o'chirib bo'lmadi: ${err instanceof Error ? err.message : "noma'lum xatolik"}`);
    } finally {
      setDeletingId(null);
    }
  }

  function openAddForm() {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setImageSlots(Array(MAX_IMAGES).fill(null));
    setUploading(Array(MAX_IMAGES).fill(false));
    setUploadErrors(Array(MAX_IMAGES).fill(null));
    setShowForm(true);
  }

  function openEditForm(p: SellerProduct) {
    setEditingId(p.id);
    setForm({
      name: p.name,
      categoryId: p.categoryId,
      price: String(p.price),
      unit: p.unit,
      stockQty: String(p.stockQty),
      description: p.description,
    });
    const existing = p.images && p.images.length > 0 ? p.images : [p.imageUrl];
    setImageSlots(Array.from({ length: MAX_IMAGES }, (_, i) => existing[i] ?? null));
    setUploading(Array(MAX_IMAGES).fill(false));
    setUploadErrors(Array(MAX_IMAGES).fill(null));
    setShowForm(true);
  }

  function closeForm() {
    setShowForm(false);
    setEditingId(null);
    setForm(EMPTY_FORM);
    setImageSlots(Array(MAX_IMAGES).fill(null));
    setUploading(Array(MAX_IMAGES).fill(false));
    setUploadErrors(Array(MAX_IMAGES).fill(null));
  }

  function withSlot<T>(arr: T[], index: number, value: T): T[] {
    const next = [...arr];
    next[index] = value;
    return next;
  }

  async function setImageSlot(index: number, file: File | null) {
    setUploadErrors((prev) => withSlot(prev, index, null));

    if (!file) {
      setImageSlots((prev) => withSlot(prev, index, null));
      return;
    }

    // Fayl tanlangan zahoti mahalliy oldindan ko'rish (preview) ko'rsatiladi,
    // Supabase'ga yuklash paralel ravishda fonda ketadi.
    const localPreview = URL.createObjectURL(file);
    setImageSlots((prev) => withSlot(prev, index, localPreview));
    setUploading((prev) => withSlot(prev, index, true));

    try {
      const publicUrl = await uploadProductImage(file);
      URL.revokeObjectURL(localPreview);
      setImageSlots((prev) => withSlot(prev, index, publicUrl));
    } catch (err) {
      URL.revokeObjectURL(localPreview);
      setImageSlots((prev) => withSlot(prev, index, null));
      setUploadErrors((prev) =>
        withSlot(prev, index, err instanceof Error ? err.message : "Rasm yuklashda xatolik yuz berdi."),
      );
    } finally {
      setUploading((prev) => withSlot(prev, index, false));
    }
  }

  const isUploadingAny = uploading.some(Boolean);

  async function submitForm(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name.trim() || !form.price || isUploadingAny || submitting) return;

    const uploaded = imageSlots.filter((url): url is string => Boolean(url));
    const images = uploaded.length > 0 ? uploaded : undefined;
    const imageUrl = uploaded[0] ?? `${CATALOG}/${form.categoryId}.jpg`;

    const input = {
      name: form.name.trim(),
      imageUrl,
      images,
      categoryId: form.categoryId,
      description: form.description.trim() || "Tavsif kiritilmagan.",
      price: Number(form.price),
      unit: form.unit,
      stockQty: Number(form.stockQty) || 0,
    };

    setSubmitting(true);
    try {
      if (editingId) {
        const updated = await updateSellerProduct(editingId, input);
        setProducts((prev) => prev.map((p) => (p.id === editingId ? updated : p)));
      } else {
        const created = await insertSellerProduct(input, companyName);
        setProducts((prev) => [created, ...prev]);
      }
      setTab("pending");
      setShowForm(false);
      setEditingId(null);
      setForm(EMPTY_FORM);
      setImageSlots(Array(MAX_IMAGES).fill(null));
    } catch (err) {
      alert(`Saqlab bo'lmadi: ${err instanceof Error ? err.message : "noma'lum xatolik"}`);
    } finally {
      setSubmitting(false);
    }
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
            onClick={openAddForm}
            className="flex items-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
          >
            <Plus className="h-4 w-4" /> Mahsulot qo&apos;shish
          </button>
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
                  <button
                    onClick={() => openEditForm(p)}
                    disabled={deletingId === p.id}
                    className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-border py-2 text-xs font-semibold text-foreground/70 hover:bg-surface-muted disabled:opacity-50"
                  >
                    <Pencil className="h-3.5 w-3.5" /> Tahrirlash
                  </button>
                  <button
                    onClick={() => removeProduct(p.id)}
                    disabled={deletingId === p.id}
                    className="flex items-center justify-center gap-1.5 rounded-xl border border-danger/30 px-3 py-2 text-xs font-semibold text-danger hover:bg-danger-tint disabled:opacity-50"
                  >
                    {deletingId === p.id ? (
                      <Loader2 className="h-3.5 w-3.5 animate-spin" />
                    ) : (
                      <Trash2 className="h-3.5 w-3.5" />
                    )}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
        )}

        {!loading && list.length === 0 && (
          <p className="rounded-2xl border border-dashed border-border py-16 text-center text-sm text-foreground/40">
            Bu bo&apos;limda hozircha mahsulot yo&apos;q.
          </p>
        )}
      </main>

      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-surface p-6 shadow-xl">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-bold text-foreground">
                {editingId ? "Mahsulotni tahrirlash" : "Yangi mahsulot qo'shish"}
              </h2>
              <button
                onClick={closeForm}
                className="flex h-8 w-8 items-center justify-center rounded-lg text-foreground/50 hover:bg-surface-muted"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
            <form onSubmit={submitForm} className="mt-4 space-y-3">
              <Field label="Rasmlar (3 tagacha)">
                <div className="flex gap-3">
                  {imageSlots.map((src, i) => (
                    <div key={i} className="flex flex-col items-center gap-1">
                      <label
                        className={clsx(
                          "relative flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-dashed border-border bg-surface-muted hover:border-brand-light",
                          uploading[i] ? "cursor-wait opacity-70" : "cursor-pointer",
                        )}
                      >
                        {src ? (
                          <>
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img src={src} alt={`Rasm ${i + 1}`} className="h-full w-full object-cover" />
                            {!uploading[i] && (
                              <button
                                type="button"
                                onClick={(e) => {
                                  e.preventDefault();
                                  setImageSlot(i, null);
                                }}
                                className="absolute right-1 top-1 flex h-5 w-5 items-center justify-center rounded-full bg-black/60 text-white hover:bg-black/80"
                              >
                                <X className="h-3 w-3" />
                              </button>
                            )}
                          </>
                        ) : (
                          <ImagePlus className="h-5 w-5 text-foreground/30" />
                        )}
                        {uploading[i] && (
                          <div className="absolute inset-0 flex items-center justify-center bg-black/30">
                            <Loader2 className="h-5 w-5 animate-spin text-white" />
                          </div>
                        )}
                        <input
                          type="file"
                          accept="image/*"
                          disabled={uploading[i]}
                          className="hidden"
                          onChange={(e) => setImageSlot(i, e.target.files?.[0] ?? null)}
                        />
                      </label>
                      {uploadErrors[i] && (
                        <p className="w-20 text-center text-[10px] leading-tight text-danger">
                          {uploadErrors[i]}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
                <p className="mt-1.5 text-[11px] text-foreground/40">
                  Rasm tanlanmasa, kategoriya bo&apos;yicha standart rasm ishlatiladi. Yuklangan
                  rasmlar Supabase omboriga saqlanadi.
                </p>
              </Field>
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
                {editingId
                  ? "O'zgartirishlar saqlangach, mahsulot qayta admin tomonidan tekshiriladi."
                  : "Yangi mahsulot qo‘shilgach, u admin tomonidan tekshirilgunga qadar “Moderatsiyada” holatida turadi."}
              </p>
              <button
                type="submit"
                disabled={isUploadingAny || submitting}
                className="w-full rounded-xl bg-brand py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-60"
              >
                {isUploadingAny
                  ? "Rasm yuklanmoqda..."
                  : submitting
                    ? "Saqlanmoqda..."
                    : editingId
                      ? "Saqlash"
                      : "Yuborish"}
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
