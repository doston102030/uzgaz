"use client";

import { Suspense, useEffect, useMemo, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Topbar } from "@/components/Topbar";
import { Badge, BadgeTone, CategoryTag } from "@/components/Badge";
import { SellerDialog } from "@/components/SellerDialog";
import { SellerLoginDialog } from "@/components/SellerLoginDialog";
import { useShell } from "@/components/Shell";
import { errorText, useConfirm, useToast } from "@/components/ui/feedback";
import { deleteSeller, fetchProducts, fetchSellerLogins, fetchSellers, updateSellerStatus } from "@/lib/db";
import { Seller, SellerStatus, CATEGORY_COLOR, CATEGORY_LABEL } from "@/lib/types";
import { formatDate } from "@/lib/format";
import {
  Ban,
  Check,
  KeyRound,
  Loader2,
  MapPin,
  Package,
  Pencil,
  Phone,
  Plus,
  RotateCcw,
  Search,
  Trash2,
  Users,
  X,
} from "lucide-react";
import clsx from "clsx";

const STATUS_LABEL: Record<SellerStatus, string> = {
  pending: "Yangi ariza",
  approved: "Tasdiqlangan",
  rejected: "Rad etilgan",
  suspended: "To'xtatilgan",
};

const STATUS_TONE: Record<SellerStatus, BadgeTone> = {
  pending: "warning",
  approved: "success",
  rejected: "danger",
  suspended: "neutral",
};

/** New applications from the app show up without reloading the page. */
const REFRESH_EVERY_MS = 15_000;

const TABS: { key: SellerStatus | "all"; label: string }[] = [
  { key: "all", label: "Barchasi" },
  { key: "pending", label: "Yangi arizalar" },
  { key: "approved", label: "Tasdiqlangan" },
  { key: "suspended", label: "To'xtatilgan" },
  { key: "rejected", label: "Rad etilgan" },
];

function initials(name: string) {
  return (
    name
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((w) => w[0])
      .join("")
      .toUpperCase() || "—"
  );
}

export default function SellersPage() {
  return (
    <Suspense fallback={null}>
      <SellersPageContent />
    </Suspense>
  );
}

function SellersPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const toast = useToast();
  const confirm = useConfirm();
  const { refreshAlerts } = useShell();
  const [sellers, setSellers] = useState<Seller[]>([]);
  const [productCounts, setProductCounts] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [tab, setTab] = useState<SellerStatus | "all">("all");
  const [query, setQuery] = useState("");
  const [savingId, setSavingId] = useState<string | null>(null);
  const [dialog, setDialog] = useState<{ kind: "add" } | { kind: "edit"; seller: Seller } | null>(null);
  // Seller id → login; empty until supabase/seller_login_setup.sql has been run.
  const [logins, setLogins] = useState<Record<string, string>>({});
  const [loginFor, setLoginFor] = useState<Seller | null>(null);
  // A background refresh must not overwrite a status change still on its way.
  const saving = useRef(false);

  // Bell link ?tab=pending: pick the tab once (during render), then clean the URL.
  const tabParam = searchParams.get("tab");
  const [seenTabParam, setSeenTabParam] = useState<string | null>(null);
  if (tabParam !== seenTabParam) {
    setSeenTabParam(tabParam);
    const wanted = TABS.find((t) => t.key === tabParam);
    if (wanted) setTab(wanted.key);
  }
  useEffect(() => {
    if (tabParam) router.replace("/sellers");
  }, [tabParam, router]);

  useEffect(() => {
    let cancelled = false;
    fetchSellers()
      .then((rows) => {
        if (!cancelled) setSellers(rows);
      })
      .catch((err) => {
        if (!cancelled) setLoadError(errorText(err, "Sotuvchilarni yuklab bo'lmadi."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    const loadExtras = () => {
      fetchSellerLogins()
        .then((map) => !cancelled && setLogins(map))
        .catch(() => {});
      fetchProducts()
        .then((rows) => {
          if (cancelled) return;
          const counts: Record<string, number> = {};
          for (const p of rows) if (p.companyId) counts[p.companyId] = (counts[p.companyId] ?? 0) + 1;
          setProductCounts(counts);
        })
        .catch(() => {});
    };
    loadExtras();
    const timer = setInterval(() => {
      if (document.hidden || saving.current) return;
      fetchSellers()
        .then((rows) => {
          if (!cancelled && !saving.current) {
            setSellers(rows);
            setLoadError(null);
          }
        })
        .catch(() => {});
      loadExtras();
    }, REFRESH_EVERY_MS);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, []);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: sellers.length };
    for (const s of sellers) c[s.status] = (c[s.status] ?? 0) + 1;
    return c;
  }, [sellers]);

  const list = useMemo(() => {
    const q = query.trim().toLowerCase();
    const digits = q.replace(/\D/g, "");
    return sellers.filter(
      (s) =>
        (tab === "all" || s.status === tab) &&
        (!q ||
          s.companyName.toLowerCase().includes(q) ||
          s.ownerName.toLowerCase().includes(q) ||
          s.district.toLowerCase().includes(q) ||
          (digits.length >= 3 && s.phone.replace(/\D/g, "").includes(digits))),
    );
  }, [sellers, tab, query]);

  const CONFIRM: Partial<Record<SellerStatus, { title: string; message: string; label: string }>> = {
    suspended: {
      title: "Sotuvchini to'xtatasizmi?",
      message: "Uning kompaniyasi va mahsulotlari ilovada ko'rinmay qoladi. Istalgan payt qayta tiklash mumkin.",
      label: "To'xtatish",
    },
    rejected: {
      title: "Arizani rad etasizmi?",
      message: "Sotuvchi seller panelda arizasi rad etilganini ko'radi.",
      label: "Rad etish",
    },
  };

  async function setStatus(seller: Seller, status: SellerStatus) {
    const ask = CONFIRM[status];
    if (
      ask &&
      !(await confirm({
        title: ask.title,
        message: (
          <>
            <b className="text-foreground">{seller.companyName}</b> — {ask.message}
          </>
        ),
        confirmLabel: ask.label,
        danger: true,
      }))
    ) {
      return;
    }
    const prev = sellers;
    setSavingId(seller.id);
    saving.current = true;
    setSellers((cur) => cur.map((s) => (s.id === seller.id ? { ...s, status } : s)));
    try {
      await updateSellerStatus(seller.id, status);
      toast.success(`${seller.companyName} — ${STATUS_LABEL[status].toLowerCase()}.`);
      refreshAlerts();
    } catch (err) {
      setSellers(prev);
      toast.error(`Holatni yangilab bo'lmadi: ${errorText(err)}`);
    } finally {
      saving.current = false;
      setSavingId(null);
    }
  }

  async function remove(seller: Seller) {
    const products = productCounts[seller.id] ?? 0;
    const ok = await confirm({
      title: "Sotuvchini o'chirasizmi?",
      message: (
        <>
          <b className="text-foreground">{seller.companyName}</b> butunlay o&apos;chiriladi
          {products > 0 && <> — {products} ta mahsuloti bilan birga</>}. Logini ham bekor bo&apos;ladi,
          o&apos;tgan buyurtmalar tarixda qoladi. Vaqtincha to&apos;xtatish uchun &quot;To&apos;xtatish&quot;
          tugmasidan foydalaning.
        </>
      ),
      confirmLabel: "O'chirish",
      danger: true,
    });
    if (!ok) return;
    setSavingId(seller.id);
    saving.current = true;
    try {
      await deleteSeller(seller.id);
      setSellers((cur) => cur.filter((s) => s.id !== seller.id));
      toast.success(`${seller.companyName} o'chirildi.`);
      refreshAlerts();
    } catch (err) {
      toast.error(`O'chirib bo'lmadi: ${errorText(err)}`);
    } finally {
      saving.current = false;
      setSavingId(null);
    }
  }

  function onSaved(seller: Seller) {
    const added = dialog?.kind === "add";
    setDialog(null);
    setSellers((cur) =>
      added ? [seller, ...cur.filter((s) => s.id !== seller.id)] : cur.map((s) => (s.id === seller.id ? seller : s)),
    );
    if (added) setTab("all");
    toast.success(added ? `${seller.companyName} qo'shildi — endi unga login bering.` : "Ma'lumotlar saqlandi.");
    if (added) setLoginFor(seller);
    refreshAlerts();
  }

  function statusActions(s: Seller, compact = false) {
    if (savingId === s.id) {
      return (
        <div className="flex h-9 w-9 items-center justify-center">
          <Loader2 className="h-4 w-4 animate-spin text-foreground/40" />
        </div>
      );
    }
    const btn = "flex h-9 items-center justify-center gap-1.5 rounded-lg text-xs font-semibold hover:brightness-95";
    const iconOnly = compact ? "w-9" : "px-3";
    return (
      <div className="flex flex-wrap gap-1.5">
        {s.status === "pending" && (
          <>
            <button onClick={() => setStatus(s, "approved")} title="Tasdiqlash" className={clsx(btn, iconOnly, "bg-success-tint text-success")}>
              <Check className="h-4 w-4" />
              {!compact && "Tasdiqlash"}
            </button>
            <button onClick={() => setStatus(s, "rejected")} title="Rad etish" className={clsx(btn, iconOnly, "bg-danger-tint text-danger")}>
              <X className="h-4 w-4" />
              {!compact && "Rad etish"}
            </button>
          </>
        )}
        {s.status === "approved" && (
          <button
            onClick={() => setStatus(s, "suspended")}
            title="To'xtatish"
            className={clsx(btn, iconOnly, "bg-surface-muted text-foreground/60 hover:bg-warning-tint hover:text-warning")}
          >
            <Ban className="h-4 w-4" />
            {!compact && "To'xtatish"}
          </button>
        )}
        {(s.status === "suspended" || s.status === "rejected") && (
          <button onClick={() => setStatus(s, "approved")} title="Qayta tiklash" className={clsx(btn, iconOnly, "bg-success-tint text-success")}>
            <RotateCcw className="h-4 w-4" />
            {!compact && "Qayta tiklash"}
          </button>
        )}
        <button
          onClick={() => setDialog({ kind: "edit", seller: s })}
          title="Tahrirlash"
          aria-label="Tahrirlash"
          className={clsx(btn, "w-9 bg-surface-muted text-foreground/60 hover:bg-brand-tint hover:text-brand")}
        >
          <Pencil className="h-4 w-4" />
        </button>
        <button
          onClick={() => remove(s)}
          title="O'chirish"
          aria-label="O'chirish"
          className={clsx(btn, "w-9 bg-surface-muted text-foreground/50 hover:bg-danger-tint hover:text-danger")}
        >
          <Trash2 className="h-4 w-4" />
        </button>
      </div>
    );
  }

  function loginCell(s: Seller) {
    return logins[s.id] ? (
      <button
        onClick={() => setLoginFor(s)}
        title="Login va parolni yangilash"
        className="-mx-2 flex items-center gap-1.5 rounded-lg px-2 py-1 font-mono text-xs text-foreground/70 hover:bg-surface-muted"
      >
        <KeyRound className="h-3.5 w-3.5 text-success" />
        {logins[s.id]}
      </button>
    ) : (
      <button
        onClick={() => setLoginFor(s)}
        className="flex items-center gap-1.5 whitespace-nowrap rounded-lg bg-brand-tint px-2.5 py-1.5 text-xs font-semibold text-brand hover:brightness-95"
      >
        <KeyRound className="h-3.5 w-3.5" /> Login berish
      </button>
    );
  }

  return (
    <>
      <Topbar
        title="Sotuvchilar"
        subtitle={`${sellers.length} ta sotuvchi · ${counts.pending ?? 0} ta yangi ariza`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-4 sm:p-6">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <label className="relative flex-1">
            <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-foreground/35" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Kompaniya, egasi, tuman yoki telefon..."
              className="w-full rounded-xl border border-border bg-surface py-2.5 pl-10 pr-3 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light"
            />
          </label>
          <button
            onClick={() => setDialog({ kind: "add" })}
            className="flex items-center justify-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
          >
            <Plus className="h-4 w-4" /> Yangi sotuvchi
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
            Sotuvchilarni yuklab bo&apos;lmadi: {loadError}
          </p>
        )}

        {loading ? (
          <div className="flex items-center justify-center gap-2 rounded-2xl border border-border bg-surface py-16 text-sm text-foreground/40">
            <Loader2 className="h-4 w-4 animate-spin" /> Yuklanmoqda...
          </div>
        ) : list.length === 0 ? (
          <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-border px-6 py-16 text-center">
            <Users className="h-8 w-8 text-foreground/25" />
            <p className="text-sm text-foreground/45">
              {query ? "Qidiruv bo'yicha sotuvchi topilmadi." : "Bu bo'limda hozircha sotuvchi yo'q."}
            </p>
          </div>
        ) : (
          <>
            {/* Desktop: table */}
            <div className="hidden overflow-hidden rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02] xl:block">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-border text-xs uppercase tracking-wide text-foreground/40">
                    <th className="px-5 py-3 font-medium">Kompaniya</th>
                    <th className="px-5 py-3 font-medium">Faoliyat</th>
                    <th className="px-5 py-3 font-medium">Hudud / aloqa</th>
                    <th className="px-5 py-3 font-medium">Holati</th>
                    <th className="px-5 py-3 font-medium">Kirish</th>
                    <th className="px-5 py-3 font-medium">Amallar</th>
                  </tr>
                </thead>
                <tbody>
                  {list.map((s) => (
                    <tr key={s.id} className="border-b border-border last:border-0">
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-3">
                          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-brand-light to-brand text-xs font-bold text-white">
                            {initials(s.companyName)}
                          </div>
                          <div className="min-w-0">
                            <p className="font-semibold text-foreground">{s.companyName}</p>
                            <p className="text-xs text-foreground/45">
                              {s.ownerName} · {productCounts[s.id] ?? 0} ta mahsulot · {formatDate(s.createdAt)}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-3">
                        <CategoryTag label={CATEGORY_LABEL[s.category]} color={CATEGORY_COLOR[s.category]} />
                      </td>
                      <td className="px-5 py-3 text-xs text-foreground/55">
                        <div className="flex items-center gap-1.5">
                          <MapPin className="h-3 w-3" /> {s.district}
                          {s.address && <span className="text-foreground/40">· {s.address}</span>}
                        </div>
                        <a href={`tel:${s.phone}`} className="mt-1 flex items-center gap-1.5 hover:text-brand">
                          <Phone className="h-3 w-3" /> {s.phone}
                        </a>
                      </td>
                      <td className="px-5 py-3">
                        <Badge label={STATUS_LABEL[s.status]} tone={STATUS_TONE[s.status]} dot />
                      </td>
                      <td className="px-5 py-3">
                        {loginCell(s)}
                      </td>
                      <td className="px-5 py-3">
                        {statusActions(s, true)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Phone/tablet: cards */}
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:hidden">
              {list.map((s) => (
                <article key={s.id} className="rounded-2xl border border-border bg-surface p-4 shadow-sm shadow-black/[0.02]">
                  <div className="flex items-start gap-3">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-brand-light to-brand text-xs font-bold text-white">
                      {initials(s.companyName)}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <p className="font-semibold text-foreground">{s.companyName}</p>
                        <Badge label={STATUS_LABEL[s.status]} tone={STATUS_TONE[s.status]} dot />
                      </div>
                      <p className="mt-0.5 text-xs text-foreground/50">
                        {s.ownerName} · {formatDate(s.createdAt)}
                      </p>
                    </div>
                  </div>
                  <div className="mt-3 space-y-1.5 text-xs text-foreground/60">
                    <p className="flex items-center gap-1.5">
                      <MapPin className="h-3.5 w-3.5 shrink-0" /> {s.district}
                      {s.address && <span className="truncate text-foreground/40">· {s.address}</span>}
                    </p>
                    <a href={`tel:${s.phone}`} className="flex items-center gap-1.5 hover:text-brand">
                      <Phone className="h-3.5 w-3.5" /> {s.phone}
                    </a>
                    <p className="flex items-center gap-1.5">
                      <Package className="h-3.5 w-3.5" /> {productCounts[s.id] ?? 0} ta mahsulot ·{" "}
                      {CATEGORY_LABEL[s.category]}
                    </p>
                  </div>
                  <div className="mt-3 flex items-center justify-between gap-2 border-t border-border pt-3">
                    {loginCell(s)}
                  </div>
                  <div className="mt-3">
                    {statusActions(s)}
                  </div>
                </article>
              ))}
            </div>
          </>
        )}
      </main>
      {dialog && (
        <SellerDialog
          seller={dialog.kind === "edit" ? dialog.seller : undefined}
          onClose={() => setDialog(null)}
          onSaved={onSaved}
        />
      )}
      {loginFor && (
        <SellerLoginDialog
          seller={loginFor}
          currentLogin={logins[loginFor.id]}
          onClose={() => setLoginFor(null)}
          onSaved={(id, login) => setLogins((cur) => ({ ...cur, [id]: login }))}
        />
      )}
    </>
  );
}
