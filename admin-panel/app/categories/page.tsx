"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Topbar } from "@/components/Topbar";
import { CategoryIcon } from "@/components/CategoryIcon";
import { Modal, ModalButton } from "@/components/ui/Modal";
import { errorText, useConfirm, useToast } from "@/components/ui/feedback";
import {
  createCategory,
  deleteCategory,
  fetchCategories,
  fetchProducts,
  fetchSellers,
  updateCategory,
} from "@/lib/db";
import { CATEGORY_ICONS, categoryColor, cleanLabel, ProductCategory, sameLabel } from "@/lib/categories";
import {
  ArrowDown,
  ArrowUp,
  Database,
  Eye,
  EyeOff,
  Globe,
  Loader2,
  Pencil,
  Plus,
  Tags,
  Trash2,
} from "lucide-react";
import clsx from "clsx";

const ICON_LABEL: Record<string, string> = {
  cylinder: "Ballon",
  fuel: "Yoqilg'i",
  wrench: "Ta'mir",
  flame: "Olov",
  zap: "Elektr",
  truck: "Yetkazish",
  package: "Mahsulot",
  tag: "Teg",
};

export default function CategoriesPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const [categories, setCategories] = useState<ProductCategory[]>([]);
  const [ready, setReady] = useState(true);
  const [loading, setLoading] = useState(true);
  const [usage, setUsage] = useState<Record<string, number>>({});
  const [sellerNames, setSellerNames] = useState<Record<string, string>>({});
  const [busyId, setBusyId] = useState<string | null>(null);
  const [dialog, setDialog] = useState<{ category?: ProductCategory } | null>(null);

  useEffect(() => {
    let cancelled = false;
    Promise.all([fetchCategories(), fetchProducts().catch(() => []), fetchSellers().catch(() => [])])
      .then(([{ categories, ready }, products, sellers]) => {
        if (cancelled) return;
        setCategories(categories);
        setReady(ready);
        const counts: Record<string, number> = {};
        for (const p of products) counts[p.categoryId] = (counts[p.categoryId] ?? 0) + 1;
        setUsage(counts);
        setSellerNames(Object.fromEntries(sellers.map((s) => [s.id, s.companyName])));
      })
      .catch((err) => !cancelled && toast.error(errorText(err, "Kategoriyalar yuklanmadi.")))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [toast]);

  const platform = useMemo(
    () => categories.filter((c) => c.sellerId === null).sort((a, b) => a.sortOrder - b.sortOrder),
    [categories],
  );
  const own = useMemo(() => categories.filter((c) => c.sellerId !== null), [categories]);

  function replace(updated: ProductCategory) {
    setCategories((cur) => cur.map((c) => (c.id === updated.id ? updated : c)));
  }

  async function run(id: string, action: () => Promise<void>) {
    setBusyId(id);
    try {
      await action();
    } catch (err) {
      toast.error(errorText(err));
    } finally {
      setBusyId(null);
    }
  }

  function toggle(c: ProductCategory) {
    void run(c.id, async () => {
      replace(await updateCategory(c.id, { isActive: !c.isActive }));
      toast.success(c.isActive ? `"${c.label}" yashirildi — yangi mahsulotlarda tanlanmaydi.` : `"${c.label}" yana faol.`);
    });
  }

  function move(index: number, delta: -1 | 1) {
    const a = platform[index];
    const b = platform[index + delta];
    if (!a || !b) return;
    // Equal sort orders (e.g. both 100) would not swap — fall back to positions.
    const orderA = a.sortOrder === b.sortOrder ? index + 1 : a.sortOrder;
    const orderB = a.sortOrder === b.sortOrder ? index + 1 + delta : b.sortOrder;
    void run(a.id, async () => {
      const [na, nb] = await Promise.all([
        updateCategory(a.id, { sortOrder: orderB }),
        updateCategory(b.id, { sortOrder: orderA }),
      ]);
      replace(na);
      replace(nb);
    });
  }

  async function remove(c: ProductCategory) {
    const ok = await confirm({
      title: "Kategoriyani o'chirasizmi?",
      message: `"${c.label}" ro'yxatdan butunlay olib tashlanadi.`,
      confirmLabel: "O'chirish",
      danger: true,
    });
    if (!ok) return;
    void run(c.id, async () => {
      await deleteCategory(c.id);
      setCategories((cur) => cur.filter((x) => x.id !== c.id));
      toast.success("Kategoriya o'chirildi.");
    });
  }

  async function promote(c: ProductCategory) {
    if (platform.some((p) => sameLabel(p.label, c.label))) {
      toast.error(`Umumiy ro'yxatda "${c.label}" allaqachon bor.`);
      return;
    }
    const ok = await confirm({
      title: "Umumiy kategoriyaga aylantirasizmi?",
      message: `"${c.label}" barcha sotuvchilarning formasida chiqadi. Mavjud mahsulotlar shu kategoriyada qoladi.`,
      confirmLabel: "Aylantirish",
    });
    if (!ok) return;
    void run(c.id, async () => {
      replace(await updateCategory(c.id, { sellerId: null, sortOrder: (platform.at(-1)?.sortOrder ?? 0) + 1 }));
      toast.success(`"${c.label}" endi umumiy kategoriya.`);
    });
  }

  function row(c: ProductCategory, index: number, isPlatform: boolean) {
    const count = usage[c.id] ?? 0;
    const busy = busyId === c.id;
    const color = categoryColor(c.id);
    const iconBtn =
      "flex h-9 w-9 items-center justify-center rounded-lg text-foreground/50 hover:bg-surface-muted disabled:opacity-30";
    return (
      <li key={c.id} className={clsx("flex flex-wrap items-center gap-3 px-4 py-3 sm:flex-nowrap sm:px-5", !c.isActive && "opacity-60")}>
        <span
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl"
          style={{ background: `color-mix(in srgb, ${color} 14%, transparent)`, color }}
        >
          <CategoryIcon icon={c.icon} className="h-5 w-5" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate font-semibold text-foreground">
            {c.label}
            {!c.isActive && <span className="ml-2 text-xs font-medium text-foreground/45">yashirilgan</span>}
          </p>
          <p className="text-xs text-foreground/45">
            {count} ta mahsulot
            {!isPlatform && c.sellerId && <> · {sellerNames[c.sellerId] ?? "Sotuvchi"}</>}
            {isPlatform && <> · id: {c.id}</>}
          </p>
        </div>
        <div className="ml-auto flex items-center gap-0.5">
          {busy && <Loader2 className="mr-1 h-4 w-4 animate-spin text-foreground/40" />}
          {isPlatform && (
            <>
              <button onClick={() => move(index, -1)} disabled={busy || index === 0} title="Yuqoriga" aria-label="Yuqoriga" className={iconBtn}>
                <ArrowUp className="h-4 w-4" />
              </button>
              <button
                onClick={() => move(index, 1)}
                disabled={busy || index === platform.length - 1}
                title="Pastga"
                aria-label="Pastga"
                className={iconBtn}
              >
                <ArrowDown className="h-4 w-4" />
              </button>
              <button
                onClick={() => toggle(c)}
                disabled={busy}
                title={c.isActive ? "Yashirish" : "Faollashtirish"}
                aria-label={c.isActive ? "Yashirish" : "Faollashtirish"}
                className={iconBtn}
              >
                {c.isActive ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </>
          )}
          {!isPlatform && (
            <button onClick={() => promote(c)} disabled={busy} title="Umumiyga aylantirish" aria-label="Umumiyga aylantirish" className={iconBtn}>
              <Globe className="h-4 w-4" />
            </button>
          )}
          <button
            onClick={() => setDialog({ category: c })}
            disabled={busy}
            title="Tahrirlash"
            aria-label="Tahrirlash"
            className={clsx(iconBtn, "hover:text-brand")}
          >
            <Pencil className="h-4 w-4" />
          </button>
          <button
            onClick={() => remove(c)}
            disabled={busy || count > 0}
            title={count > 0 ? "Mahsulotlari bor — o'chirib bo'lmaydi, yashiring" : "O'chirish"}
            aria-label="O'chirish"
            className={clsx(iconBtn, "hover:text-danger")}
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      </li>
    );
  }

  return (
    <>
      <Topbar
        title="Kategoriyalar"
        subtitle={`${platform.length} ta umumiy · ${own.length} ta sotuvchilarniki`}
      />
      <main className="flex-1 space-y-6 overflow-y-auto p-4 sm:p-6">
        {!ready && (
          <div className="flex flex-col gap-3 rounded-2xl border border-warning/30 bg-warning-tint p-5 sm:flex-row sm:items-center">
            <Database className="h-6 w-6 shrink-0 text-warning" />
            <p className="flex-1 text-sm text-foreground/75">
              Kategoriyalar jadvali hali bazada yo&apos;q. <b>supabase/marketplace_setup.sql</b> faylini Supabase SQL
              Editor&apos;da bir marta ishga tushiring — shundan keyin bu yerda boshqarasiz.
            </p>
            <Link href="/system" className="shrink-0 rounded-xl bg-surface px-4 py-2 text-sm font-semibold text-foreground hover:bg-surface-muted">
              Tizim holati
            </Link>
          </div>
        )}

        <section className="rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border px-4 py-4 sm:px-5">
            <div>
              <h2 className="text-sm font-bold text-foreground">Umumiy kategoriyalar</h2>
              <p className="text-xs text-foreground/45">
                Barcha sotuvchilarning mahsulot formasida shu tartibda chiqadi
              </p>
            </div>
            <button
              onClick={() => setDialog({})}
              disabled={!ready}
              className="flex items-center gap-2 rounded-xl bg-brand px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark disabled:opacity-50"
            >
              <Plus className="h-4 w-4" /> Yangi kategoriya
            </button>
          </div>
          {loading ? (
            <div className="flex items-center justify-center gap-2 py-12 text-sm text-foreground/40">
              <Loader2 className="h-4 w-4 animate-spin" /> Yuklanmoqda...
            </div>
          ) : platform.length === 0 ? (
            <p className="py-12 text-center text-sm text-foreground/45">Hali umumiy kategoriya yo&apos;q.</p>
          ) : (
            <ul className="divide-y divide-border">{platform.map((c, i) => row(c, i, true))}</ul>
          )}
        </section>

        <section className="rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]">
          <div className="border-b border-border px-4 py-4 sm:px-5">
            <h2 className="text-sm font-bold text-foreground">Sotuvchilarning o&apos;z kategoriyalari</h2>
            <p className="text-xs text-foreground/45">
              Sotuvchi faqat o&apos;zi uchun yaratgan. Ko&apos;pchilikka kerak bo&apos;lsa — umumiyga aylantiring.
            </p>
          </div>
          {own.length === 0 ? (
            <div className="flex flex-col items-center gap-2 py-12 text-center text-foreground/40">
              <Tags className="h-6 w-6" />
              <p className="text-sm">Sotuvchilar hali o&apos;z kategoriyasini yaratmagan.</p>
            </div>
          ) : (
            <ul className="divide-y divide-border">{own.map((c, i) => row(c, i, false))}</ul>
          )}
        </section>
      </main>

      {dialog && (
        <CategoryDialog
          category={dialog.category}
          others={categories}
          nextOrder={(platform.at(-1)?.sortOrder ?? 0) + 1}
          onClose={() => setDialog(null)}
          onSaved={(saved, created) => {
            setDialog(null);
            setCategories((cur) => (created ? [...cur, saved] : cur.map((c) => (c.id === saved.id ? saved : c))));
            toast.success(created ? `"${saved.label}" qo'shildi.` : "Kategoriya saqlandi.");
          }}
        />
      )}
    </>
  );
}

function CategoryDialog({
  category,
  others,
  nextOrder,
  onClose,
  onSaved,
}: {
  category?: ProductCategory;
  others: ProductCategory[];
  nextOrder: number;
  onClose: () => void;
  onSaved: (category: ProductCategory, created: boolean) => void;
}) {
  const [label, setLabel] = useState(category?.label ?? "");
  const [icon, setIcon] = useState(category?.icon ?? "tag");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: FormEvent) {
    e.preventDefault();
    const clean = cleanLabel(label);
    if (!clean) return setError("Kategoriya nomini yozing.");
    // Same owner only — a seller may have their own "Gaz plita" next to a platform one.
    const owner = category?.sellerId ?? null;
    if (others.some((c) => c.id !== category?.id && c.sellerId === owner && sameLabel(c.label, clean))) {
      return setError("Bu nomli kategoriya allaqachon bor.");
    }
    setSaving(true);
    setError(null);
    try {
      const saved = category
        ? await updateCategory(category.id, { label: clean, icon })
        : await createCategory({ label: clean, icon, sortOrder: nextOrder });
      onSaved(saved, !category);
    } catch (err) {
      setError(errorText(err));
      setSaving(false);
    }
  }

  return (
    <Modal
      size="sm"
      busy={saving}
      onClose={onClose}
      onSubmit={submit}
      title={category ? "Kategoriyani tahrirlash" : "Yangi kategoriya"}
      subtitle={
        category
          ? "Nom o'zgarsa, mahsulotlar shu kategoriyada qoladi — faqat ko'rinishi yangilanadi"
          : "Barcha sotuvchilarning formasida chiqadi"
      }
      footer={
        <>
          <ModalButton variant="ghost" onClick={onClose} disabled={saving}>
            Bekor qilish
          </ModalButton>
          <ModalButton type="submit" disabled={saving}>
            {saving && <Loader2 className="h-4 w-4 animate-spin" />}
            Saqlash
          </ModalButton>
        </>
      }
    >
      <label className="block">
        <span className="text-xs font-semibold text-foreground/60">Nomi</span>
        <input
          autoFocus
          value={label}
          maxLength={40}
          onChange={(e) => {
            setLabel(e.target.value);
            setError(null);
          }}
          placeholder="Masalan: Gaz plita o'rnatish"
          className="mt-1.5 w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
        />
      </label>
      <fieldset className="mt-4">
        <legend className="text-xs font-semibold text-foreground/60">Belgisi</legend>
        <div className="mt-1.5 grid grid-cols-4 gap-2">
          {Object.keys(CATEGORY_ICONS).map((name) => (
            <button
              key={name}
              type="button"
              aria-pressed={icon === name}
              onClick={() => setIcon(name)}
              className={clsx(
                "flex flex-col items-center gap-1 rounded-xl border px-2 py-2.5 text-[11px] font-medium transition-colors",
                icon === name
                  ? "border-brand bg-brand-tint text-brand"
                  : "border-border text-foreground/55 hover:bg-surface-muted",
              )}
            >
              <CategoryIcon icon={name} className="h-5 w-5" />
              {ICON_LABEL[name] ?? name}
            </button>
          ))}
        </div>
      </fieldset>
      {error && <p className="mt-3 text-xs text-danger">{error}</p>}
    </Modal>
  );
}
