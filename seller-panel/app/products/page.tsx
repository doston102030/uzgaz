"use client";

import { FormEvent, Suspense, useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Topbar } from "@/components/Topbar";
import { Badge, CategoryTag } from "@/components/Badge";
import { CategoryPicker } from "@/components/CategoryPicker";
import { ImageFitDialog } from "@/components/ImageFitDialog";
import { ProductThumb } from "@/components/ProductThumb";
import { useShell } from "@/components/Shell";
import { Modal, ModalButton } from "@/components/ui/Modal";
import { errorText, useConfirm, useToast } from "@/components/ui/feedback";
import {
  createCategory,
  deleteCategory,
  deleteSellerProduct,
  fetchCategories,
  fetchSellerProducts,
  fetchSellerStatus,
  insertSellerProduct,
  ProductInput,
  renameCategory,
  setProductAvailability,
  updateSellerProduct,
} from "@/lib/db";
import {
  categoryColor,
  categoryLabel,
  DEFAULT_CATEGORIES,
  ProductCategory,
} from "@/lib/categories";
import { ModerationStatus, SellerProduct } from "@/lib/types";
import { formatCurrency } from "@/lib/format";
import { uploadProductImage } from "@/lib/supabase";
import {
  Eye,
  EyeOff,
  ImagePlus,
  Loader2,
  PackageOpen,
  Pencil,
  Plus,
  Search,
  Trash2,
  WandSparkles,
  X,
} from "lucide-react";
import clsx from "clsx";

const MAX_IMAGES = 3;
/** Ombor 5 MB gacha qabul qiladi; moslangan rasm odatda 100 KB atrofida bo'ladi. */
const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;
/** Asl fayl katta bo'lsa ham bo'ladi — moslash uni kichraytiradi. */
const MAX_SOURCE_BYTES = 30 * 1024 * 1024;

type Tab = ModerationStatus | "all" | "hidden";

const TABS: { key: Tab; label: string }[] = [
  { key: "all", label: "Barchasi" },
  { key: "approved", label: "Faol" },
  { key: "pending", label: "Moderatsiyada" },
  { key: "rejected", label: "Rad etilgan" },
  { key: "hidden", label: "Sotuvda yo'q" },
];

const UNITS = ["dona", "kg", "litr", "m³", "xizmat"];

const STATUS: Record<ModerationStatus, { label: string; tone: "success" | "warning" | "danger" }> = {
  approved: { label: "Faol", tone: "success" },
  pending: { label: "Moderatsiyada", tone: "warning" },
  rejected: { label: "Rad etilgan", tone: "danger" },
};

const INPUT =
  "w-full rounded-xl border bg-surface-muted px-3.5 py-2.5 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light focus:bg-surface";

const EMPTY_FORM = {
  name: "",
  categoryId: "gazBallon",
  price: "",
  oldPrice: "",
  unit: "dona",
  stockQty: "",
  description: "",
};

type FormState = typeof EMPTY_FORM;
type FormErrors = Partial<Record<"name" | "price" | "oldPrice" | "stockQty" | "categoryId", string>>;

/** Sotuvda yo'q: sotuvchi olib qo'ygan yoki ombor tugagan. */
const isHidden = (p: SellerProduct) => !p.isAvailable || p.stockQty <= 0;

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
  const toast = useToast();
  const confirm = useConfirm();
  const { refreshAlerts } = useShell();

  const [products, setProducts] = useState<SellerProduct[]>([]);
  const [categories, setCategories] = useState<ProductCategory[]>(DEFAULT_CATEGORIES);
  const [categoriesReady, setCategoriesReady] = useState(false);
  const [companyName, setCompanyName] = useState("");
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [tab, setTab] = useState<Tab>("all");
  const [query, setQuery] = useState("");

  // Form (modal)
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [errors, setErrors] = useState<FormErrors>({});
  const [submitting, setSubmitting] = useState(false);
  const [imageSlots, setImageSlots] = useState<(string | null)[]>(Array(MAX_IMAGES).fill(null));
  const [uploading, setUploading] = useState<boolean[]>(Array(MAX_IMAGES).fill(false));
  const [uploadErrors, setUploadErrors] = useState<(string | null)[]>(Array(MAX_IMAGES).fill(null));
  /** "Rasmni moslash" oynasi: qaysi katak uchun va qaysi rasm (yangi fayl yoki mavjud URL). */
  const [fitting, setFitting] = useState<{ index: number; source: File | string } | null>(null);

  useEffect(() => {
    let cancelled = false;
    Promise.all([fetchSellerProducts(), fetchSellerStatus()])
      .then(([rows, status]) => {
        if (cancelled) return;
        setProducts(rows);
        setCompanyName(status.company_name);
      })
      .catch((err) => {
        if (!cancelled) setLoadError(errorText(err, "Mahsulotlarni yuklab bo'lmadi."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    fetchCategories()
      .then(({ categories, ready }) => {
        if (cancelled) return;
        setCategories(categories);
        setCategoriesReady(ready);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);

  // Deep links: ?new=1 (bosh sahifa tugmasi), ?tab=rejected (bildirishnoma).
  useEffect(() => {
    const wanted = searchParams.get("tab") as Tab | null;
    const opening = searchParams.get("new") === "1";
    if (!wanted && !opening) return;
    if (wanted && TABS.some((t) => t.key === wanted)) setTab(wanted);
    if (opening) openForm(null);
    router.replace("/products");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams]);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: products.length, hidden: 0 };
    for (const p of products) {
      c[p.moderationStatus] = (c[p.moderationStatus] ?? 0) + 1;
      if (isHidden(p)) c.hidden += 1;
    }
    return c;
  }, [products]);

  const list = useMemo(() => {
    const q = query.trim().toLowerCase();
    return products.filter((p) => {
      if (tab === "hidden" ? !isHidden(p) : tab !== "all" && p.moderationStatus !== tab) return false;
      if (!q) return true;
      return (
        p.name.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q) ||
        categoryLabel(p.categoryId, categories).toLowerCase().includes(q)
      );
    });
  }, [products, tab, query, categories]);

  // ── product actions ──────────────────────────────────────────────

  async function removeProduct(p: SellerProduct) {
    const ok = await confirm({
      title: "Mahsulotni o'chirasizmi?",
      message: (
        <>
          <b className="text-foreground">{p.name}</b> butunlay o&apos;chiriladi va ilovada ko&apos;rinmay
          qoladi. Vaqtincha yashirish uchun &quot;Sotuvdan olish&quot; tugmasidan foydalaning.
        </>
      ),
      confirmLabel: "O'chirish",
      danger: true,
    });
    if (!ok) return;
    setBusyId(p.id);
    try {
      await deleteSellerProduct(p.id);
      setProducts((prev) => prev.filter((x) => x.id !== p.id));
      toast.success("Mahsulot o'chirildi.");
      refreshAlerts();
    } catch (err) {
      toast.error(`O'chirib bo'lmadi: ${errorText(err)}`);
    } finally {
      setBusyId(null);
    }
  }

  async function toggleAvailability(p: SellerProduct) {
    setBusyId(p.id);
    try {
      await setProductAvailability(p.id, !p.isAvailable);
      setProducts((prev) => prev.map((x) => (x.id === p.id ? { ...x, isAvailable: !p.isAvailable } : x)));
      toast.success(p.isAvailable ? "Mahsulot sotuvdan olindi." : "Mahsulot yana sotuvda.");
    } catch (err) {
      toast.error(`Saqlab bo'lmadi: ${errorText(err)}`);
    } finally {
      setBusyId(null);
    }
  }

  // ── form ─────────────────────────────────────────────────────────

  function openForm(p: SellerProduct | null) {
    setEditingId(p?.id ?? null);
    setErrors({});
    setForm(
      p
        ? {
            name: p.name,
            categoryId: p.categoryId,
            price: String(p.price),
            oldPrice: p.oldPrice ? String(p.oldPrice) : "",
            unit: p.unit,
            stockQty: String(p.stockQty),
            description: p.description === "Tavsif kiritilmagan." ? "" : p.description,
          }
        : { ...EMPTY_FORM, categoryId: categories.find((c) => c.isActive)?.id ?? "gazBallon" },
    );
    const existing = p ? (p.images ?? [p.imageUrl]).filter(Boolean) : [];
    setImageSlots(Array.from({ length: MAX_IMAGES }, (_, i) => existing[i] ?? null));
    setUploading(Array(MAX_IMAGES).fill(false));
    setUploadErrors(Array(MAX_IMAGES).fill(null));
    setShowForm(true);
  }

  function closeForm() {
    if (submitting) return;
    setShowForm(false);
  }

  function set<K extends keyof FormState>(key: K, value: FormState[K]) {
    setForm((cur) => ({ ...cur, [key]: value }));
    setErrors((cur) => ({ ...cur, [key]: undefined }));
  }

  function withSlot<T>(arr: T[], index: number, value: T): T[] {
    const next = [...arr];
    next[index] = value;
    return next;
  }

  function clearImageSlot(index: number) {
    setUploadErrors((prev) => withSlot(prev, index, null));
    setImageSlots((prev) => withSlot(prev, index, null));
  }

  /** Tanlangan fayl avval "Rasmni moslash" oynasida ko'rsatiladi. */
  function pickImage(index: number, file: File | undefined) {
    if (!file) return;
    setUploadErrors((prev) => withSlot(prev, index, null));
    if (!file.type.startsWith("image/")) {
      setUploadErrors((prev) => withSlot(prev, index, "Rasm fayli emas"));
      return;
    }
    if (file.size > MAX_SOURCE_BYTES) {
      setUploadErrors((prev) => withSlot(prev, index, "30 MB dan katta"));
      return;
    }
    setFitting({ index, source: file });
  }

  async function uploadToSlot(index: number, file: Blob) {
    setUploadErrors((prev) => withSlot(prev, index, null));
    if (file.size > MAX_UPLOAD_BYTES) {
      setUploadErrors((prev) => withSlot(prev, index, "5 MB dan katta — moslab yuklang"));
      return;
    }
    // Darhol mahalliy ko'rinish, Supabase'ga yuklash fonda.
    const previous = imageSlots[index];
    const localPreview = URL.createObjectURL(file);
    setImageSlots((prev) => withSlot(prev, index, localPreview));
    setUploading((prev) => withSlot(prev, index, true));
    try {
      const publicUrl = await uploadProductImage(file);
      setImageSlots((prev) => withSlot(prev, index, publicUrl));
    } catch (err) {
      // Mavjud rasmni qayta moslash muvaffaqiyatsiz bo'lsa — eskisi qoladi.
      setImageSlots((prev) => withSlot(prev, index, previous));
      setUploadErrors((prev) => withSlot(prev, index, errorText(err, "Yuklanmadi")));
    } finally {
      URL.revokeObjectURL(localPreview);
      setUploading((prev) => withSlot(prev, index, false));
    }
  }

  const isUploadingAny = uploading.some(Boolean);

  function validate(): FormErrors {
    const e: FormErrors = {};
    const price = Number(form.price);
    const oldPrice = form.oldPrice ? Number(form.oldPrice) : null;
    if (!form.name.trim()) e.name = "Mahsulot nomini yozing.";
    if (!form.price || !Number.isFinite(price) || price <= 0) e.price = "Narxni kiriting.";
    if (oldPrice !== null && (!Number.isFinite(oldPrice) || oldPrice <= price)) {
      e.oldPrice = "Eski narx joriy narxdan katta bo'lsin.";
    }
    if (form.stockQty && Number(form.stockQty) < 0) e.stockQty = "Manfiy bo'lmasin.";
    if (!form.categoryId) e.categoryId = "Kategoriyani tanlang.";
    return e;
  }

  async function submitForm(e: FormEvent) {
    e.preventDefault();
    if (isUploadingAny || submitting) return;
    const problems = validate();
    setErrors(problems);
    if (Object.keys(problems).length > 0) return;

    const uploaded = imageSlots.filter((url): url is string => Boolean(url));
    const input: ProductInput = {
      name: form.name.trim(),
      imageUrl: uploaded[0] ?? "",
      images: uploaded.length > 0 ? uploaded : undefined,
      categoryId: form.categoryId,
      description: form.description.trim() || "Tavsif kiritilmagan.",
      price: Number(form.price),
      oldPrice: form.oldPrice ? Number(form.oldPrice) : undefined,
      unit: form.unit,
      stockQty: Number(form.stockQty) || 0,
    };

    setSubmitting(true);
    try {
      if (editingId) {
        const updated = await updateSellerProduct(editingId, input);
        setProducts((prev) => prev.map((p) => (p.id === editingId ? updated : p)));
        toast.success("Saqlandi — mahsulot qayta moderatsiyaga yuborildi.");
      } else {
        const created = await insertSellerProduct(input, companyName);
        setProducts((prev) => [created, ...prev]);
        toast.success("Mahsulot moderatsiyaga yuborildi.");
      }
      setTab("pending");
      setShowForm(false);
      refreshAlerts();
    } catch (err) {
      toast.error(`Saqlab bo'lmadi: ${errorText(err)}`);
    } finally {
      setSubmitting(false);
    }
  }

  // ── categories ───────────────────────────────────────────────────

  async function onCreateCategory(label: string) {
    const created = await createCategory(label);
    setCategories((prev) => [...prev, created]);
    toast.success(`"${created.label}" kategoriyasi qo'shildi.`);
    return created;
  }

  async function onRenameCategory(id: string, label: string) {
    const category = categories.find((c) => c.id === id);
    if (!category) return;
    const renamed = await renameCategory(category, label);
    setCategories((prev) => prev.map((c) => (c.id === id ? renamed : c)));
    toast.success(
      category.sellerId === null
        ? `Umumiy kategoriya endi "${renamed.label}" — hamma sotuvchida yangilandi.`
        : "Kategoriya nomi yangilandi.",
    );
  }

  async function onDeleteCategory(id: string) {
    await deleteCategory(id);
    setCategories((prev) => prev.filter((c) => c.id !== id));
    toast.success("Kategoriya o'chirildi.");
  }

  const editingProduct = editingId ? products.find((p) => p.id === editingId) : undefined;

  return (
    <>
      <Topbar
        title="Mahsulotlarim"
        subtitle={`${products.length} ta mahsulot · ${counts.pending ?? 0} tasi moderatsiyada`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-4 sm:p-6">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <label className="relative flex-1">
            <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-foreground/35" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Mahsulot yoki kategoriya bo'yicha qidirish..."
              className="w-full rounded-xl border border-border bg-surface py-2.5 pl-10 pr-3 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light"
            />
          </label>
          <button
            onClick={() => openForm(null)}
            className="flex items-center justify-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
          >
            <Plus className="h-4 w-4" /> Mahsulot qo&apos;shish
          </button>
        </div>

        <div className="no-scrollbar -mx-4 flex gap-2 overflow-x-auto px-4 sm:mx-0 sm:flex-wrap sm:px-0">
          {TABS.map((t) => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={clsx(
                "flex shrink-0 items-center gap-2 rounded-xl px-3.5 py-2 text-sm font-semibold transition-colors",
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
          <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-border px-6 py-16 text-center">
            <PackageOpen className="h-8 w-8 text-foreground/25" />
            <p className="text-sm text-foreground/45">
              {query
                ? "Qidiruv bo'yicha mahsulot topilmadi."
                : products.length === 0
                  ? "Hali mahsulot yo'q — birinchisini qo'shing, admin tasdiqlagach ilovada chiqadi."
                  : "Bu bo'limda hozircha mahsulot yo'q."}
            </p>
            {products.length === 0 && !query && (
              <button
                onClick={() => openForm(null)}
                className="flex items-center gap-2 rounded-xl bg-brand px-4 py-2 text-sm font-semibold text-white hover:bg-brand-dark"
              >
                <Plus className="h-4 w-4" /> Mahsulot qo&apos;shish
              </button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
            {list.map((p) => {
              const category = categories.find((c) => c.id === p.categoryId);
              const busy = busyId === p.id;
              return (
                <article
                  key={p.id}
                  className="flex flex-col overflow-hidden rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]"
                >
                  <div className="relative">
                    <ProductThumb
                      src={p.imageUrl}
                      alt={p.name}
                      categoryId={p.categoryId}
                      category={category}
                      className="h-40 w-full"
                    />
                    <div className="absolute left-2.5 top-2.5 rounded-full bg-surface/90 backdrop-blur">
                      <CategoryTag
                        label={categoryLabel(p.categoryId, categories)}
                        color={categoryColor(p.categoryId)}
                      />
                    </div>
                    {isHidden(p) && (
                      <span className="absolute right-2.5 top-2.5 rounded-full bg-foreground/75 px-2.5 py-1 text-xs font-semibold text-white">
                        {p.isAvailable ? "Tugagan" : "Sotuvda emas"}
                      </span>
                    )}
                  </div>
                  <div className="flex flex-1 flex-col p-4">
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="line-clamp-2 font-semibold text-foreground">{p.name}</h3>
                      <Badge label={STATUS[p.moderationStatus].label} tone={STATUS[p.moderationStatus].tone} />
                    </div>
                    <p className="mt-2 flex flex-wrap items-baseline gap-x-2 text-sm font-bold text-brand">
                      {formatCurrency(p.price)}
                      <span className="font-medium text-foreground/40">/ {p.unit}</span>
                      {p.oldPrice && (
                        <span className="text-xs font-medium text-foreground/40 line-through">
                          {formatCurrency(p.oldPrice)}
                        </span>
                      )}
                    </p>
                    <p
                      className={clsx(
                        "mt-1 text-xs",
                        p.stockQty <= 0 ? "font-semibold text-danger" : "text-foreground/50",
                      )}
                    >
                      {p.stockQty <= 0 ? "Omborda qolmagan" : `Omborda: ${p.stockQty} ${p.unit}`}
                    </p>
                    <p className="mt-2 line-clamp-2 text-xs text-foreground/55">{p.description}</p>
                    {p.moderationStatus === "rejected" && p.rejectionReason && (
                      <p className="mt-2 rounded-lg bg-danger-tint px-2.5 py-1.5 text-xs text-danger">
                        <b>Rad etish sababi:</b> {p.rejectionReason}
                      </p>
                    )}
                    <div className="mt-auto flex gap-2 pt-4">
                      <button
                        onClick={() => openForm(p)}
                        disabled={busy}
                        className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-border py-2 text-xs font-semibold text-foreground/70 hover:bg-surface-muted disabled:opacity-50"
                      >
                        <Pencil className="h-3.5 w-3.5" /> Tahrirlash
                      </button>
                      <button
                        onClick={() => toggleAvailability(p)}
                        disabled={busy}
                        title={p.isAvailable ? "Sotuvdan olish" : "Sotuvga qaytarish"}
                        aria-label={p.isAvailable ? "Sotuvdan olish" : "Sotuvga qaytarish"}
                        className="flex items-center justify-center rounded-xl border border-border px-3 py-2 text-foreground/60 hover:bg-surface-muted disabled:opacity-50"
                      >
                        {busy ? (
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        ) : p.isAvailable ? (
                          <EyeOff className="h-3.5 w-3.5" />
                        ) : (
                          <Eye className="h-3.5 w-3.5" />
                        )}
                      </button>
                      <button
                        onClick={() => removeProduct(p)}
                        disabled={busy}
                        title="O'chirish"
                        aria-label="O'chirish"
                        className="flex items-center justify-center rounded-xl border border-danger/30 px-3 py-2 text-danger hover:bg-danger-tint disabled:opacity-50"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </main>

      {showForm && (
        <Modal
          size="lg"
          title={editingId ? "Mahsulotni tahrirlash" : "Yangi mahsulot"}
          subtitle={
            editingId
              ? "Saqlangach, mahsulot qayta admin tekshiruvidan o'tadi."
              : "Admin tasdiqlagach, mahsulot ilovada ko'rinadi."
          }
          onClose={closeForm}
          busy={submitting}
          onSubmit={submitForm}
          footer={
            <>
              <ModalButton variant="ghost" onClick={closeForm} disabled={submitting}>
                Bekor qilish
              </ModalButton>
              <ModalButton type="submit" disabled={isUploadingAny || submitting}>
                {(submitting || isUploadingAny) && <Loader2 className="h-4 w-4 animate-spin" />}
                {isUploadingAny
                  ? "Rasm yuklanmoqda..."
                  : submitting
                    ? "Saqlanmoqda..."
                    : editingId
                      ? "Saqlash"
                      : "Moderatsiyaga yuborish"}
              </ModalButton>
            </>
          }
        >
          <div className="space-y-5">
            <div>
              <p className="text-xs font-medium text-foreground/55">Rasmlar (3 tagacha)</p>
              <div className="mt-1.5 grid max-w-sm grid-cols-3 gap-3">
                {imageSlots.map((src, i) => (
                  <div key={i}>
                    <label
                      className={clsx(
                        "relative flex aspect-square items-center justify-center overflow-hidden rounded-xl border border-dashed border-border bg-surface-muted transition-colors hover:border-brand-light",
                        uploading[i] ? "cursor-wait" : "cursor-pointer",
                      )}
                    >
                      {src ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={src} alt={`Rasm ${i + 1}`} className="h-full w-full bg-white object-contain p-1.5" />
                      ) : (
                        <span className="flex flex-col items-center gap-1 text-foreground/35">
                          <ImagePlus className="h-5 w-5" />
                          <span className="text-[10px] font-medium">{i === 0 ? "Asosiy" : "Qo'shimcha"}</span>
                        </span>
                      )}
                      {uploading[i] && (
                        <span className="absolute inset-0 flex items-center justify-center bg-black/35">
                          <Loader2 className="h-5 w-5 animate-spin text-white" />
                        </span>
                      )}
                      <input
                        type="file"
                        accept="image/*"
                        disabled={uploading[i]}
                        className="sr-only"
                        onChange={(e) => {
                          pickImage(i, e.target.files?.[0]);
                          e.target.value = "";
                        }}
                      />
                    </label>
                    {src && !uploading[i] && (
                      <div className="mt-1 flex items-center justify-center gap-0.5">
                        <button
                          type="button"
                          onClick={() => setFitting({ index: i, source: src })}
                          title="Rasmni moslash"
                          className="flex items-center gap-1 rounded-md px-1.5 py-0.5 text-[11px] font-medium text-brand hover:bg-brand-tint"
                        >
                          <WandSparkles className="h-3 w-3" /> Moslash
                        </button>
                        <button
                          type="button"
                          onClick={() => clearImageSlot(i)}
                          title="Olib tashlash"
                          aria-label="Olib tashlash"
                          className="flex items-center rounded-md p-1 text-foreground/40 hover:bg-danger-tint hover:text-danger"
                        >
                          <X className="h-3 w-3" />
                        </button>
                      </div>
                    )}
                    {uploadErrors[i] && (
                      <p className="mt-1 text-center text-[10px] leading-tight text-danger">{uploadErrors[i]}</p>
                    )}
                  </div>
                ))}
              </div>
              <p className="mt-1.5 text-[11px] text-foreground/40">
                Yuklashda rasm avtomatik moslanadi: bo&apos;sh chetlar kesiladi, oq yoki katakli fon olib
                tashlanadi. Eng yaxshisi — oq yoki shaffof fonli, mahsulot to&apos;liq ko&apos;rinadigan surat.
              </p>
            </div>

            <Field label="Mahsulot nomi" error={errors.name}>
              <input
                value={form.name}
                maxLength={80}
                onChange={(e) => set("name", e.target.value)}
                placeholder="Masalan: Gaz ballon 50 litr"
                className={clsx(INPUT, errors.name ? "border-danger" : "border-border")}
              />
            </Field>

            <CategoryPicker
              categories={categories}
              ready={categoriesReady}
              value={form.categoryId}
              onChange={(id) => set("categoryId", id)}
              onCreate={onCreateCategory}
              onRename={onRenameCategory}
              onDelete={onDeleteCategory}
              error={errors.categoryId}
            />

            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <Field label="Narxi (so'm)" error={errors.price}>
                <input
                  type="number"
                  inputMode="numeric"
                  min={0}
                  step={500}
                  value={form.price}
                  onChange={(e) => set("price", e.target.value)}
                  placeholder="250000"
                  className={clsx(INPUT, errors.price ? "border-danger" : "border-border")}
                />
              </Field>
              <Field label="Eski narxi — chegirma uchun (ixtiyoriy)" error={errors.oldPrice}>
                <input
                  type="number"
                  inputMode="numeric"
                  min={0}
                  step={500}
                  value={form.oldPrice}
                  onChange={(e) => set("oldPrice", e.target.value)}
                  placeholder="280000"
                  className={clsx(INPUT, errors.oldPrice ? "border-danger" : "border-border")}
                />
              </Field>
              <Field label="O'lchov birligi">
                <select
                  value={form.unit}
                  onChange={(e) => set("unit", e.target.value)}
                  className={clsx(INPUT, "border-border")}
                >
                  {[...new Set([...UNITS, form.unit])].map((u) => (
                    <option key={u} value={u}>
                      {u}
                    </option>
                  ))}
                </select>
              </Field>
              <Field label={`Omborda (${form.unit})`} error={errors.stockQty}>
                <input
                  type="number"
                  inputMode="numeric"
                  min={0}
                  value={form.stockQty}
                  onChange={(e) => set("stockQty", e.target.value)}
                  placeholder="0"
                  className={clsx(INPUT, errors.stockQty ? "border-danger" : "border-border")}
                />
              </Field>
            </div>

            <Field label="Tavsif" hint={`${form.description.length}/500`}>
              <textarea
                value={form.description}
                maxLength={500}
                onChange={(e) => set("description", e.target.value)}
                rows={3}
                placeholder="Hajmi, ishlab chiqaruvchi, kafolat, yetkazish shartlari..."
                className={clsx(INPUT, "resize-y border-border")}
              />
            </Field>

            {editingProduct?.moderationStatus === "rejected" && editingProduct.rejectionReason && (
              <p className="rounded-xl bg-danger-tint px-3.5 py-2.5 text-xs text-danger">
                <b>Admin izohi:</b> {editingProduct.rejectionReason}
              </p>
            )}
          </div>
        </Modal>
      )}

      {fitting && (
        <ImageFitDialog
          source={fitting.source}
          onClose={() => setFitting(null)}
          onApply={(image) => {
            setFitting(null);
            void uploadToSlot(fitting.index, image.blob);
          }}
          onKeepOriginal={
            fitting.source instanceof File
              ? () => {
                  setFitting(null);
                  void uploadToSlot(fitting.index, fitting.source as File);
                }
              : undefined
          }
        />
      )}
    </>
  );
}

function Field({
  label,
  error,
  hint,
  children,
}: {
  label: string;
  error?: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="flex justify-between gap-2 text-xs font-medium text-foreground/55">
        {label}
        {hint && <span className="text-foreground/35">{hint}</span>}
      </span>
      <div className="mt-1.5">{children}</div>
      {error && <span className="mt-1 block text-xs text-danger">{error}</span>}
    </label>
  );
}
