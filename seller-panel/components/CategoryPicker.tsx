"use client";

import { KeyboardEvent, useState } from "react";
import { Check, Database, Loader2, Pencil, Plus, Trash2, X } from "lucide-react";
import clsx from "clsx";
import { CategoryIcon } from "@/components/CategoryIcon";
import {
  categoryColor,
  cleanLabel,
  ProductCategory,
  sameLabel,
} from "@/lib/categories";
import { errorText, useConfirm } from "@/components/ui/feedback";

const INPUT =
  "min-w-0 flex-1 rounded-xl border border-border bg-surface px-3 py-2 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light";

/**
 * Mahsulot kategoriyasi: umumiy kategoriyalar (hamma sotuvchida bir xil) va
 * sotuvchining o'zinikilari. Qalamcha ikkalasida ham bor: umumiyning nomi
 * hamma uchun o'zgaradi (Doston qarori), o'zinikini o'chirish ham mumkin.
 * Yangi kategoriya darhol saqlanadi va tanlanadi.
 */
export function CategoryPicker({
  categories,
  ready,
  value,
  onChange,
  onCreate,
  onRename,
  onDelete,
  error,
}: {
  categories: ProductCategory[];
  /** false — `product_categories` jadvali hali yo'q: tanlash mumkin, qo'shish/tahrir — yo'q. */
  ready: boolean;
  value: string;
  onChange: (id: string) => void;
  onCreate: (label: string) => Promise<ProductCategory>;
  onRename: (id: string, label: string) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
  error?: string | null;
}) {
  const confirm = useConfirm();
  const [mode, setMode] = useState<
    { kind: "idle" } | { kind: "add" } | { kind: "edit"; id: string } | { kind: "setup" }
  >({ kind: "idle" });
  const [draft, setDraft] = useState("");
  const [busy, setBusy] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const platform = categories.filter((c) => c.sellerId === null && (c.isActive || c.id === value));
  const own = categories.filter((c) => c.sellerId !== null);
  // Eski erkin matnli kategoriya (ro'yxatda yo'q) — tanlangan bo'lsa ko'rinib tursin.
  const legacy = value && !categories.some((c) => c.id === value) ? value : null;

  function start(next: typeof mode, text = "") {
    // Jadval yo'q — kiritish o'rniga nima qilish kerakligini ko'rsatamiz.
    if (!ready && (next.kind === "add" || next.kind === "edit")) next = { kind: "setup" };
    setMode(next);
    setDraft(text);
    setLocalError(null);
  }

  function validate(label: string, exceptId?: string): string | null {
    if (!label) return "Kategoriya nomini yozing.";
    if (label.length > 40) return "Nom 40 belgidan oshmasin.";
    if (categories.some((c) => c.id !== exceptId && sameLabel(c.label, label))) {
      return "Bu nomli kategoriya allaqachon bor — ro'yxatdan tanlang.";
    }
    return null;
  }

  async function run(action: () => Promise<void>) {
    setBusy(true);
    setLocalError(null);
    try {
      await action();
      start({ kind: "idle" });
    } catch (err) {
      setLocalError(errorText(err));
    } finally {
      setBusy(false);
    }
  }

  function save() {
    const label = cleanLabel(draft);
    if (mode.kind === "add") {
      const problem = validate(label);
      if (problem) return setLocalError(problem);
      void run(async () => {
        const created = await onCreate(label);
        onChange(created.id);
      });
    } else if (mode.kind === "edit") {
      const problem = validate(label, mode.id);
      if (problem) return setLocalError(problem);
      const id = mode.id;
      void run(() => onRename(id, label));
    }
  }

  async function remove(category: ProductCategory) {
    const ok = await confirm({
      title: "Kategoriyani o'chirasizmi?",
      message: `"${category.label}" ro'yxatdan olib tashlanadi.`,
      confirmLabel: "O'chirish",
      danger: true,
    });
    if (!ok) return;
    void run(async () => {
      await onDelete(category.id);
      if (value === category.id) onChange(platform[0]?.id ?? "");
    });
  }

  // Forma ichida: Enter mahsulotni emas, kategoriyani saqlasin.
  function onKey(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Enter") {
      e.preventDefault();
      save();
    } else if (e.key === "Escape") {
      e.preventDefault();
      e.stopPropagation();
      start({ kind: "idle" });
    }
  }

  function chip(category: ProductCategory, editable: boolean) {
    const selected = value === category.id;
    const color = categoryColor(category.id);
    return (
      <div
        key={category.id}
        className={clsx(
          "inline-flex items-stretch overflow-hidden rounded-xl border text-sm font-medium transition-colors",
          selected
            ? "border-brand bg-brand-tint text-brand"
            : "border-border bg-surface-muted text-foreground/70 hover:border-foreground/20",
        )}
      >
        <button
          type="button"
          aria-pressed={selected}
          onClick={() => onChange(category.id)}
          className="inline-flex items-center gap-1.5 py-2 pl-3 pr-3"
        >
          <CategoryIcon icon={category.icon} className="h-4 w-4 shrink-0" style={selected ? undefined : { color }} />
          {category.label}
        </button>
        {editable && (
          <button
            type="button"
            title="Nomini o'zgartirish"
            aria-label={`${category.label} — tahrirlash`}
            onClick={() => start({ kind: "edit", id: category.id }, category.label)}
            className={clsx(
              "flex items-center border-l px-2.5 transition-colors",
              selected ? "border-brand/25 hover:bg-brand/10" : "border-border hover:bg-surface",
            )}
          >
            <Pencil className="h-3.5 w-3.5" />
          </button>
        )}
      </div>
    );
  }

  const editing = mode.kind === "edit" ? categories.find((c) => c.id === mode.id) : undefined;
  const editingShared = editing?.sellerId === null;

  return (
    <fieldset>
      <legend className="text-xs font-medium text-foreground/55">Kategoriya</legend>
      <div className="mt-1.5 flex flex-wrap gap-2">
        {platform.map((c) => chip(c, true))}
        {legacy && (
          <div className="inline-flex items-center gap-1.5 rounded-xl border border-brand bg-brand-tint px-3 py-2 text-sm font-medium text-brand">
            {legacy}
          </div>
        )}
      </div>

      {own.length > 0 && (
        <>
          <p className="mt-3 text-[11px] font-semibold uppercase tracking-wide text-foreground/40">
            Mening kategoriyalarim
          </p>
          <div className="mt-1.5 flex flex-wrap gap-2">{own.map((c) => chip(c, true))}</div>
        </>
      )}

      {mode.kind === "idle" ? (
        <button
          type="button"
          onClick={() => start({ kind: "add" })}
          className="mt-2 inline-flex items-center gap-1.5 rounded-xl border border-dashed border-foreground/20 px-3 py-2 text-sm font-medium text-foreground/55 transition-colors hover:border-brand-light hover:text-brand"
        >
          <Plus className="h-4 w-4" />
          Yangi kategoriya
        </button>
      ) : mode.kind === "setup" ? (
        <div className="mt-2 flex items-start gap-3 rounded-xl border border-warning/30 bg-warning-tint p-3">
          <Database className="mt-0.5 h-4 w-4 shrink-0 text-warning" />
          <div className="min-w-0 flex-1 text-xs leading-relaxed text-foreground/75">
            <p className="font-semibold text-foreground">Kategoriyalar bazada hali yoqilmagan</p>
            <p className="mt-0.5">
              Qo&apos;shish va nomini o&apos;zgartirish uchun Supabase → SQL Editor&apos;da{" "}
              <b>supabase/marketplace_setup.sql</b> faylini bir marta ishga tushirish kerak (admin panel →
              Tizim sahifasida havola bor). Shungacha tayyor kategoriyalardan tanlang.
            </p>
          </div>
          <button
            type="button"
            onClick={() => start({ kind: "idle" })}
            aria-label="Yopish"
            className="-m-1 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg text-foreground/45 hover:bg-surface"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      ) : (
        <div className="mt-2 rounded-xl border border-brand-light/50 bg-brand-tint/40 p-2.5">
          <p className="mb-2 text-xs font-medium text-foreground/60">
            {mode.kind === "add" ? "Yangi kategoriya" : `"${editing?.label ?? ""}" — yangi nom`}
          </p>
          <div className="flex flex-wrap items-center gap-2">
            <input
              autoFocus
              value={draft}
              maxLength={40}
              disabled={busy}
              onChange={(e) => {
                setDraft(e.target.value);
                setLocalError(null);
              }}
              onKeyDown={onKey}
              placeholder="Masalan: Gaz plita o'rnatish"
              className={clsx(INPUT, "basis-full sm:basis-0")}
            />
            <div className="flex gap-1.5 max-sm:w-full">
              <button
                type="button"
                onClick={save}
                disabled={busy}
                title="Saqlash"
                className="flex h-9 items-center justify-center gap-1.5 rounded-xl bg-brand px-3 text-sm font-semibold text-white hover:bg-brand-dark disabled:opacity-60 max-sm:flex-1"
              >
                {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
                {mode.kind === "add" ? "Qo'shish" : "Saqlash"}
              </button>
              {editing && !editingShared && (
                <button
                  type="button"
                  onClick={() => remove(editing)}
                  disabled={busy}
                  title="O'chirish"
                  aria-label="Kategoriyani o'chirish"
                  className="flex h-9 w-9 items-center justify-center rounded-xl border border-danger/30 bg-surface text-danger hover:bg-danger-tint disabled:opacity-60"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              )}
              <button
                type="button"
                onClick={() => start({ kind: "idle" })}
                disabled={busy}
                title="Bekor qilish"
                aria-label="Bekor qilish"
                className="flex h-9 w-9 items-center justify-center rounded-xl border border-border bg-surface text-foreground/55 hover:bg-surface-muted disabled:opacity-60"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>
          {editingShared && (
            <p className="mt-2 text-[11px] text-foreground/50">
              Bu umumiy kategoriya — yangi nom barcha sotuvchilarda va admin panelda ko&apos;rinadi.
            </p>
          )}
        </div>
      )}

      {(localError || error) && <p className="mt-1.5 text-xs text-danger">{localError ?? error}</p>}
    </fieldset>
  );
}
