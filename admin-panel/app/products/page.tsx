"use client";

import { FormEvent, useEffect, useMemo, useRef, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge, CategoryTag } from "@/components/Badge";
import { ImageFitDialog } from "@/components/ImageFitDialog";
import { ProductThumb } from "@/components/ProductThumb";
import { useShell } from "@/components/Shell";
import { Modal, ModalButton } from "@/components/ui/Modal";
import { errorText, useConfirm, useToast } from "@/components/ui/feedback";
import {
  deleteProduct,
  fetchCategories,
  fetchProducts,
  updateProductImages,
  updateProductModeration,
} from "@/lib/db";
import { uploadProductImage } from "@/lib/supabase";
import { categoryColor, categoryLabel, DEFAULT_CATEGORIES, ProductCategory } from "@/lib/categories";
import { ModerationStatus, Product } from "@/lib/types";
import { formatCurrency, formatDateTime } from "@/lib/format";
import {
  Check,
  Clock,
  Eye,
  EyeOff,
  Loader2,
  RotateCcw,
  Search,
  Trash2,
  WandSparkles,
  X,
} from "lucide-react";
import clsx from "clsx";

const TABS: { key: ModerationStatus; label: string }[] = [
  { key: "pending", label: "Kutilmoqda" },
  { key: "approved", label: "Faol" },
  { key: "rejected", label: "Rad etilgan" },
];

const QUICK_REASONS = [
  "Rasm sifatsiz yoki mahsulotga mos emas",
  "Narx noto'g'ri ko'rsatilgan",
  "Tavsif to'liq emas",
  "Kategoriya noto'g'ri tanlangan",
  "Platforma qoidalariga zid",
];

/** Sellers' new products appear without reloading the page. */
const REFRESH_MS = 30_000;

export default function ProductsPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const { refreshAlerts } = useShell();
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<ProductCategory[]>(DEFAULT_CATEGORIES);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [tab, setTab] = useState<ModerationStatus>("pending");
  const [query, setQuery] = useState("");
  const [sellerFilter, setSellerFilter] = useState("all");
  const [savingId, setSavingId] = useState<string | null>(null);
  const [rejecting, setRejecting] = useState<Product | null>(null);
  const [viewing, setViewing] = useState<Product | null>(null);
  /** "Rasmni moslash" oynasi va yuklanayotgan rasm (mahsulot oynasida aylanib turadi). */
  const [fitting, setFitting] = useState<{ product: Product; index: number } | null>(null);
  const [savingImage, setSavingImage] = useState<{ productId: string; index: number } | null>(null);
  const saving = useRef(false);

  useEffect(() => {
    let cancelled = false;
    const load = () =>
      fetchProducts()
        .then((rows) => {
          if (cancelled || saving.current) return;
          setProducts(rows);
          setLoadError(null);
        })
        .catch((err) => {
          if (!cancelled) setLoadError(errorText(err, "Mahsulotlarni yuklab bo'lmadi."));
        })
        .finally(() => {
          if (!cancelled) setLoading(false);
        });
    void load();
    fetchCategories()
      .then(({ categories, ready }) => {
        if (!cancelled && ready) setCategories(categories);
      })
      .catch(() => {});
    const timer = setInterval(() => {
      if (!document.hidden && !saving.current) void load();
    }, REFRESH_MS);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, []);

  const counts = useMemo(() => {
    const c: Record<ModerationStatus, number> = { pending: 0, approved: 0, rejected: 0 };
    for (const p of products) c[p.moderationStatus] += 1;
    return c;
  }, [products]);

  const sellers = useMemo(() => {
    const map = new Map<string, string>();
    for (const p of products) if (p.companyId) map.set(p.companyId, p.companyName);
    return [...map.entries()].sort((a, b) => a[1].localeCompare(b[1]));
  }, [products]);

  const list = useMemo(() => {
    const q = query.trim().toLowerCase();
    return products.filter(
      (p) =>
        p.moderationStatus === tab &&
        (sellerFilter === "all" || p.companyId === sellerFilter) &&
        (!q ||
          p.name.toLowerCase().includes(q) ||
          p.companyName.toLowerCase().includes(q) ||
          categoryLabel(p.categoryId, categories).toLowerCase().includes(q)),
    );
  }, [products, tab, sellerFilter, query, categories]);

  async function setStatus(p: Product, status: ModerationStatus, reason?: string) {
    const prev = products;
    setSavingId(p.id);
    saving.current = true;
    setProducts((cur) =>
      cur.map((x) => (x.id === p.id ? { ...x, moderationStatus: status, rejectionReason: reason } : x)),
    );
    try {
      await updateProductModeration(p.id, status, reason);
      toast.success(
        status === "approved"
          ? `"${p.name}" tasdiqlandi — ilovada ko'rinadi.`
          : `"${p.name}" rad etildi — sotuvchi sababini ko'radi.`,
      );
      refreshAlerts();
      setViewing((cur) => (cur?.id === p.id ? null : cur));
    } catch (err) {
      setProducts(prev);
      toast.error(`Holatni yangilab bo'lmadi: ${errorText(err)}`);
    } finally {
      saving.current = false;
      setSavingId(null);
    }
  }

  /** Moslangan rasmni yuklab, mahsulotdagi shu rasm o'rniga qo'yadi (moderatsiya o'zgarmaydi). */
  async function replaceImage(p: Product, index: number, blob: Blob) {
    setSavingImage({ productId: p.id, index });
    saving.current = true;
    try {
      const url = await uploadProductImage(blob);
      const images = p.images.map((src, i) => (i === index ? url : src));
      await updateProductImages(p.id, images);
      const next = { ...p, images, imageUrl: images[0] };
      setProducts((cur) => cur.map((x) => (x.id === p.id ? next : x)));
      setViewing((cur) => (cur?.id === p.id ? next : cur));
      toast.success("Rasm moslandi — ilovada ham yangilandi.");
    } catch (err) {
      toast.error(`Rasmni saqlab bo'lmadi: ${errorText(err)}`);
    } finally {
      saving.current = false;
      setSavingImage(null);
    }
  }

  async function remove(p: Product) {
    setViewing(null);
    const ok = await confirm({
      title: "Mahsulotni o'chirasizmi?",
      message: (
        <>
          <b className="text-foreground">{p.name}</b> ({p.companyName}) butunlay o&apos;chiriladi. Odatda rad
          etish yetarli — sotuvchi tuzatib qayta yuboradi.
        </>
      ),
      confirmLabel: "O'chirish",
      danger: true,
    });
    if (!ok) return;
    setSavingId(p.id);
    saving.current = true;
    try {
      await deleteProduct(p.id);
      setProducts((cur) => cur.filter((x) => x.id !== p.id));
      setViewing(null);
      toast.success("Mahsulot o'chirildi.");
      refreshAlerts();
    } catch (err) {
      toast.error(`O'chirib bo'lmadi: ${errorText(err)}`);
    } finally {
      saving.current = false;
      setSavingId(null);
    }
  }

  function actions(p: Product, wide = false) {
    if (savingId === p.id) {
      return (
        <div className="flex flex-1 items-center justify-center py-2">
          <Loader2 className="h-4 w-4 animate-spin text-foreground/40" />
        </div>
      );
    }
    const base = "flex items-center justify-center gap-1.5 rounded-xl py-2 text-xs font-semibold";
    return (
      <>
        {p.moderationStatus !== "approved" && (
          <button onClick={() => setStatus(p, "approved")} className={clsx(base, "flex-1 bg-success text-white hover:brightness-95")}>
            {p.moderationStatus === "rejected" ? <RotateCcw className="h-3.5 w-3.5" /> : <Check className="h-3.5 w-3.5" />}
            {p.moderationStatus === "rejected" ? "Qayta tasdiqlash" : "Tasdiqlash"}
          </button>
        )}
        {p.moderationStatus !== "rejected" && (
          <button
            onClick={() => {
              setViewing(null);
              setRejecting(p);
            }}
            className={clsx(base, "flex-1 border border-danger/30 text-danger hover:bg-danger-tint")}
          >
            {p.moderationStatus === "approved" ? <EyeOff className="h-3.5 w-3.5" /> : <X className="h-3.5 w-3.5" />}
            {p.moderationStatus === "approved" ? "Sotuvdan olish" : "Rad etish"}
          </button>
        )}
        <button
          onClick={() => remove(p)}
          title="O'chirish"
          aria-label="O'chirish"
          className={clsx(base, "border border-border px-3 text-foreground/50 hover:bg-danger-tint hover:text-danger", wide && "px-4")}
        >
          <Trash2 className="h-3.5 w-3.5" />
          {wide && "O'chirish"}
        </button>
      </>
    );
  }

  return (
    <>
      <Topbar
        title="Mahsulotlar moderatsiyasi"
        subtitle={`${products.length} ta mahsulot · ${counts.pending} tasi tekshiruv kutmoqda`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-4 sm:p-6">
        <div className="flex flex-col gap-3 md:flex-row md:items-center">
          <label className="relative flex-1">
            <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-foreground/35" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Mahsulot, sotuvchi yoki kategoriya..."
              className="w-full rounded-xl border border-border bg-surface py-2.5 pl-10 pr-3 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light"
            />
          </label>
          <select
            value={sellerFilter}
            onChange={(e) => setSellerFilter(e.target.value)}
            className="rounded-xl border border-border bg-surface px-3 py-2.5 text-sm outline-none focus:border-brand-light md:w-56"
          >
            <option value="all">Barcha sotuvchilar</option>
            {sellers.map(([id, name]) => (
              <option key={id} value={id}>
                {name}
              </option>
            ))}
          </select>
        </div>

        <div className="no-scrollbar -mx-4 flex gap-2 overflow-x-auto px-4 sm:mx-0 sm:px-0">
          {TABS.map((t) => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={clsx(
                "flex shrink-0 items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition-colors",
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

        {loading ? (
          <div className="flex items-center justify-center gap-2 py-16 text-sm text-foreground/40">
            <Loader2 className="h-4 w-4 animate-spin" /> Yuklanmoqda...
          </div>
        ) : list.length === 0 ? (
          <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-border px-6 py-16 text-center text-foreground/40">
            <Clock className="h-6 w-6" />
            <p className="text-sm">
              {query || sellerFilter !== "all"
                ? "Filtr bo'yicha mahsulot topilmadi."
                : tab === "pending"
                  ? "Tekshiruv kutayotgan mahsulot yo'q — hammasi ko'rib chiqilgan."
                  : "Bu bo'limda hozircha mahsulot yo'q."}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
            {list.map((p) => {
              const category = categories.find((c) => c.id === p.categoryId);
              return (
                <article
                  key={p.id}
                  className="flex flex-col overflow-hidden rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]"
                >
                  <button
                    type="button"
                    onClick={() => setViewing(p)}
                    className="group relative block text-left"
                    aria-label={`${p.name} — batafsil`}
                  >
                    <ProductThumb
                      src={p.imageUrl}
                      alt={p.name}
                      categoryId={p.categoryId}
                      category={category}
                      className="h-40 w-full"
                    />
                    <span className="absolute left-2.5 top-2.5 rounded-full bg-surface/90 backdrop-blur">
                      <CategoryTag label={categoryLabel(p.categoryId, categories)} color={categoryColor(p.categoryId)} />
                    </span>
                    {p.images.length > 1 && (
                      <span className="absolute bottom-2.5 right-2.5 rounded-full bg-foreground/70 px-2 py-0.5 text-[11px] font-semibold text-white">
                        {p.images.length} rasm
                      </span>
                    )}
                    <span className="absolute inset-0 flex items-center justify-center bg-foreground/0 opacity-0 transition group-hover:bg-foreground/20 group-hover:opacity-100">
                      <span className="flex items-center gap-1.5 rounded-full bg-surface px-3 py-1.5 text-xs font-semibold text-foreground">
                        <Eye className="h-3.5 w-3.5" /> Batafsil
                      </span>
                    </span>
                  </button>
                  <div className="flex flex-1 flex-col p-4">
                    <p className="line-clamp-2 font-semibold text-foreground">{p.name}</p>
                    <p className="mt-0.5 text-xs text-foreground/45">
                      {p.companyName} · {formatDateTime(p.createdAt)}
                    </p>
                    <p className="mt-2 flex flex-wrap items-baseline gap-x-2 text-sm font-bold text-brand">
                      {formatCurrency(p.price)}
                      <span className="font-medium text-foreground/40">/ {p.unit}</span>
                      {p.oldPrice && (
                        <span className="text-xs font-medium text-foreground/40 line-through">
                          {formatCurrency(p.oldPrice)}
                        </span>
                      )}
                    </p>
                    <p className="mt-2 line-clamp-2 text-xs text-foreground/55">{p.description}</p>
                    {p.moderationStatus === "rejected" && p.rejectionReason && (
                      <p className="mt-2 rounded-lg bg-danger-tint px-2.5 py-1.5 text-xs text-danger">
                        {p.rejectionReason}
                      </p>
                    )}
                    {!p.isAvailable && p.moderationStatus === "approved" && (
                      <div className="mt-2">
                        <Badge label="Sotuvchi sotuvdan olgan" tone="neutral" />
                      </div>
                    )}
                    <div className="mt-auto flex gap-2 pt-4">{actions(p)}</div>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </main>

      {rejecting && (
        <RejectDialog
          product={rejecting}
          onClose={() => setRejecting(null)}
          onConfirm={(reason) => {
            const p = rejecting;
            setRejecting(null);
            void setStatus(p, "rejected", reason);
          }}
        />
      )}

      {viewing && (
        <Modal
          size="lg"
          title={viewing.name}
          subtitle={`${viewing.companyName} · ${formatDateTime(viewing.createdAt)}`}
          onClose={() => setViewing(null)}
          footer={<div className="flex w-full flex-col-reverse gap-2 sm:flex-row sm:justify-end">{actions(viewing, true)}</div>}
        >
          <ProductDetails
            product={viewing}
            categories={categories}
            savingIndex={savingImage?.productId === viewing.id ? savingImage.index : null}
            onFit={(index) => setFitting({ product: viewing, index })}
          />
        </Modal>
      )}

      {fitting && (
        <ImageFitDialog
          source={fitting.product.images[fitting.index]}
          onClose={() => setFitting(null)}
          onApply={(image) => {
            const { product, index } = fitting;
            setFitting(null);
            void replaceImage(product, index, image.blob);
          }}
        />
      )}
    </>
  );
}

function ProductDetails({
  product: p,
  categories,
  savingIndex,
  onFit,
}: {
  product: Product;
  categories: ProductCategory[];
  /** Shu raqamli rasm hozir yuklanmoqda. */
  savingIndex: number | null;
  onFit: (index: number) => void;
}) {
  const [active, setActive] = useState(0);
  const images = p.images;
  const category = categories.find((c) => c.id === p.categoryId);
  return (
    <div className="space-y-4">
      <div className="relative">
        <ProductThumb
          src={images[active]}
          alt={p.name}
          categoryId={p.categoryId}
          category={category}
          className="h-56 w-full rounded-xl border border-border sm:h-72"
          iconClassName="h-14 w-14"
        />
        {images[active] && (
          <button
            type="button"
            onClick={() => onFit(active)}
            disabled={savingIndex !== null}
            title="Bo'sh chetlarni kesish, katak yoki oq fonni olib tashlash"
            className="absolute bottom-2.5 right-2.5 flex items-center gap-1.5 rounded-full bg-surface/95 px-3 py-1.5 text-xs font-semibold text-brand shadow-sm ring-1 ring-border backdrop-blur hover:bg-brand-tint disabled:opacity-60"
          >
            <WandSparkles className="h-3.5 w-3.5" /> Rasmni moslash
          </button>
        )}
        {savingIndex === active && (
          <span className="absolute inset-0 flex items-center justify-center gap-2 rounded-xl bg-surface/60 text-xs font-semibold text-foreground/70">
            <Loader2 className="h-4 w-4 animate-spin" /> Saqlanmoqda...
          </span>
        )}
      </div>
      {images.length > 1 && (
        <div className="flex gap-2">
          {images.map((src, i) => (
            <button
              key={src}
              type="button"
              onClick={() => setActive(i)}
              className={clsx(
                "h-16 w-16 overflow-hidden rounded-lg border-2",
                i === active ? "border-brand" : "border-transparent opacity-70 hover:opacity-100",
              )}
            >
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={src} alt={`${p.name} ${i + 1}`} className="h-full w-full bg-white object-contain p-1" />
            </button>
          ))}
        </div>
      )}
      <dl className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4">
        {[
          ["Narxi", `${formatCurrency(p.price)} / ${p.unit}`],
          ["Eski narx", p.oldPrice ? formatCurrency(p.oldPrice) : "—"],
          ["Omborda", `${p.stockQty} ${p.unit}`],
          ["Kategoriya", categoryLabel(p.categoryId, categories)],
        ].map(([k, v]) => (
          <div key={k} className="rounded-xl bg-surface-muted px-3 py-2.5">
            <dt className="text-xs text-foreground/45">{k}</dt>
            <dd className="mt-0.5 font-semibold text-foreground">{v}</dd>
          </div>
        ))}
      </dl>
      <div>
        <p className="text-xs font-medium text-foreground/45">Tavsif</p>
        <p className="mt-1 whitespace-pre-line text-sm leading-relaxed text-foreground/75">{p.description || "—"}</p>
      </div>
      {p.rejectionReason && p.moderationStatus === "rejected" && (
        <p className="rounded-xl bg-danger-tint px-3.5 py-2.5 text-sm text-danger">
          <b>Rad etish sababi:</b> {p.rejectionReason}
        </p>
      )}
    </div>
  );
}

function RejectDialog({
  product,
  onClose,
  onConfirm,
}: {
  product: Product;
  onClose: () => void;
  onConfirm: (reason: string) => void;
}) {
  const unpublishing = product.moderationStatus === "approved";
  const [reason, setReason] = useState("");
  const [error, setError] = useState<string | null>(null);

  function submit(e: FormEvent) {
    e.preventDefault();
    const text = reason.trim();
    if (text.length < 5) {
      setError("Sotuvchi nimani tuzatishini tushunishi uchun sababni yozing.");
      return;
    }
    onConfirm(text);
  }

  return (
    <Modal
      size="sm"
      onClose={onClose}
      onSubmit={submit}
      title={unpublishing ? "Sotuvdan olish" : "Mahsulotni rad etish"}
      subtitle={`${product.name} · ${product.companyName}`}
      footer={
        <>
          <ModalButton variant="ghost" onClick={onClose}>
            Bekor qilish
          </ModalButton>
          <ModalButton type="submit" variant="danger">
            {unpublishing ? "Sotuvdan olish" : "Rad etish"}
          </ModalButton>
        </>
      }
    >
      <p className="text-xs font-medium text-foreground/55">Tez tanlash</p>
      <div className="mt-1.5 flex flex-wrap gap-1.5">
        {QUICK_REASONS.map((r) => (
          <button
            key={r}
            type="button"
            onClick={() => {
              setReason(r);
              setError(null);
            }}
            className={clsx(
              "rounded-lg border px-2.5 py-1.5 text-xs font-medium transition-colors",
              reason === r ? "border-danger/40 bg-danger-tint text-danger" : "border-border text-foreground/60 hover:bg-surface-muted",
            )}
          >
            {r}
          </button>
        ))}
      </div>
      <label className="mt-4 block">
        <span className="text-xs font-medium text-foreground/55">Sabab — sotuvchi seller panelda ko&apos;radi</span>
        <textarea
          autoFocus
          value={reason}
          maxLength={300}
          rows={3}
          onChange={(e) => {
            setReason(e.target.value);
            setError(null);
          }}
          placeholder="Masalan: rasmda boshqa mahsulot ko'rsatilgan"
          className="mt-1.5 w-full resize-y rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
        />
      </label>
      {error && <p className="mt-1 text-xs text-danger">{error}</p>}
    </Modal>
  );
}
