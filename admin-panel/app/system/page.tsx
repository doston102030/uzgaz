"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Modal, ModalButton } from "@/components/ui/Modal";
import { errorText, useToast } from "@/components/ui/feedback";
import { checkSetup, fetchOrders, fetchProducts, fetchSellers, SetupCheck } from "@/lib/db";
import {
  Check,
  CheckCircle2,
  CircleHelp,
  ClipboardList,
  Copy,
  ExternalLink,
  Loader2,
  PackageSearch,
  Play,
  RefreshCw,
  Users,
  XCircle,
} from "lucide-react";
import clsx from "clsx";

// https://<ref>.supabase.co → the project's SQL Editor in the Supabase dashboard.
const projectRef = process.env.NEXT_PUBLIC_SUPABASE_URL?.match(/^https:\/\/([a-z0-9]+)\.supabase\.co/)?.[1];
const SQL_EDITOR = projectRef ? `https://supabase.com/dashboard/project/${projectRef}/sql/new` : null;

interface Totals {
  sellers: number;
  approved: number;
  products: number;
  live: number;
  orders: number | null;
}

export default function SystemPage() {
  const toast = useToast();
  const [checks, setChecks] = useState<SetupCheck[] | null>(null);
  const [totals, setTotals] = useState<Totals | null>(null);
  const [checking, setChecking] = useState(false);
  const [guide, setGuide] = useState<SetupCheck | null>(null);

  const run = useCallback(async (): Promise<SetupCheck[] | null> => {
    setChecking(true);
    try {
      const [setup, sellers, products, orders] = await Promise.all([
        checkSetup(),
        fetchSellers().catch(() => []),
        fetchProducts().catch(() => []),
        fetchOrders().catch(() => null),
      ]);
      setChecks(setup);
      setTotals({
        sellers: sellers.length,
        approved: sellers.filter((s) => s.status === "approved").length,
        products: products.length,
        live: products.filter((p) => p.moderationStatus === "approved" && p.isAvailable).length,
        orders: orders?.length ?? null,
      });
      return setup;
    } catch (err) {
      toast.error(errorText(err, "Tekshirib bo'lmadi."));
      return null;
    } finally {
      setChecking(false);
    }
  }, [toast]);

  useEffect(() => {
    let cancelled = false;
    // Deferred one tick: run() sets state, which an effect must not do synchronously.
    void Promise.resolve().then(() => {
      if (!cancelled) void run();
    });
    return () => {
      cancelled = true;
    };
  }, [run]);

  const pending = checks?.filter((c) => c.ok === false) ?? [];

  return (
    <>
      <Topbar title="Tizim" subtitle="Ma'lumotlar bazasi holati va platforma ko'rsatkichlari" />
      <main className="flex-1 space-y-6 overflow-y-auto p-4 sm:p-6">
        <section className="rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border px-4 py-4 sm:px-5">
            <div>
              <h2 className="text-sm font-bold text-foreground">Ma&apos;lumotlar bazasi sozlamalari</h2>
              <p className="text-xs text-foreground/45">
                Har bir fayl Supabase SQL Editor&apos;da bir marta ishga tushiriladi (qayta ishga tushirish xavfsiz)
              </p>
            </div>
            <div className="flex gap-2">
              {SQL_EDITOR && (
                <a
                  href={SQL_EDITOR}
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-xs font-semibold text-foreground/70 hover:bg-surface-muted"
                >
                  <ExternalLink className="h-3.5 w-3.5" /> SQL Editor
                </a>
              )}
              <button
                onClick={() => void run()}
                disabled={checking}
                className="flex items-center gap-1.5 rounded-xl bg-brand px-3 py-2 text-xs font-semibold text-white hover:bg-brand-dark disabled:opacity-60"
              >
                <RefreshCw className={clsx("h-3.5 w-3.5", checking && "animate-spin")} /> Qayta tekshirish
              </button>
            </div>
          </div>

          {pending.length > 0 && (
            <p className="mx-4 mt-4 rounded-xl bg-warning-tint px-4 py-3 text-sm text-foreground/75 sm:mx-5">
              {pending.length} ta fayl hali ishga tushirilmagan — shu sababli ba&apos;zi bo&apos;limlar (buyurtmalar,
              kategoriyalar, sotuvchining mahsulot qo&apos;shishi) ishlamaydi.
            </p>
          )}

          {checks === null ? (
            <div className="flex items-center justify-center gap-2 py-12 text-sm text-foreground/40">
              <Loader2 className="h-4 w-4 animate-spin" /> Tekshirilmoqda...
            </div>
          ) : (
            <ul className="divide-y divide-border">
              {checks.map((c) => (
                <li key={c.file} className="flex flex-wrap items-center gap-3 px-4 py-4 sm:flex-nowrap sm:px-5">
                  {c.ok === true ? (
                    <CheckCircle2 className="h-5 w-5 shrink-0 text-success" />
                  ) : c.ok === false ? (
                    <XCircle className="h-5 w-5 shrink-0 text-danger" />
                  ) : (
                    <CircleHelp className="h-5 w-5 shrink-0 text-foreground/35" />
                  )}
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold text-foreground">{c.title}</p>
                    <p className="text-xs text-foreground/50">
                      <span className="font-mono">supabase/{c.file}</span> — {c.detail}
                    </p>
                  </div>
                  <span
                    className={clsx(
                      "rounded-full px-2.5 py-1 text-xs font-semibold",
                      c.ok === true && "bg-success-tint text-success",
                      c.ok === false && "bg-danger-tint text-danger",
                      c.ok === null && "bg-surface-muted text-foreground/50",
                    )}
                  >
                    {c.ok === true ? "O'rnatilgan" : c.ok === false ? "Ishga tushirilmagan" : "Noma'lum"}
                  </span>
                  {c.ok === false && (
                    <button
                      onClick={() => setGuide(c)}
                      className="flex items-center gap-1.5 rounded-xl bg-brand px-3 py-2 text-xs font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
                    >
                      <Play className="h-3.5 w-3.5" /> O&apos;rnatish
                    </button>
                  )}
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          {[
            {
              icon: Users,
              label: "Sotuvchilar",
              value: totals ? `${totals.approved} / ${totals.sellers}` : "…",
              hint: "faol / jami",
            },
            {
              icon: PackageSearch,
              label: "Mahsulotlar",
              value: totals ? `${totals.live} / ${totals.products}` : "…",
              hint: "ilovada ko'rinadi / jami",
            },
            {
              icon: ClipboardList,
              label: "Buyurtmalar",
              value: totals ? (totals.orders === null ? "—" : String(totals.orders)) : "…",
              hint: totals?.orders === null ? "jadval hali yo'q" : "jami",
            },
          ].map(({ icon: Icon, label, value, hint }) => (
            <div key={label} className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
              <div className="flex items-center gap-2 text-xs font-medium text-foreground/50">
                <Icon className="h-4 w-4" /> {label}
              </div>
              <p className="mt-2 text-2xl font-bold text-foreground">{value}</p>
              <p className="text-xs text-foreground/40">{hint}</p>
            </div>
          ))}
        </section>

        <section className="rounded-2xl border border-dashed border-border bg-surface-muted p-5 text-xs leading-relaxed text-foreground/55">
          <p className="font-semibold text-foreground/70">Xavfsizlik eslatmasi</p>
          <p className="mt-1">
            Hozircha admin panelga kirish paroli yo&apos;q va jadvallar umumiy kalit bilan yoziladi — bu sinov
            bosqichi uchun qabul qilingan. Haqiqiy foydalanuvchilar kelishidan oldin Supabase Auth va jadval
            darajasidagi ruxsatlar (RLS) qo&apos;shilishi kerak.
          </p>
        </section>
      </main>

      {guide && (
        <SetupGuide
          check={guide}
          onClose={() => setGuide(null)}
          onRecheck={async () => {
            const result = await run();
            return result?.find((c) => c.file === guide.file)?.ok === true;
          }}
        />
      )}
    </>
  );
}

/**
 * Step by step: copy the file's full SQL, open the SQL Editor, paste + Run,
 * come back and re-check. (The panel only has the public key, so it cannot
 * run the SQL itself.)
 */
function SetupGuide({
  check,
  onClose,
  onRecheck,
}: {
  check: SetupCheck;
  onClose: () => void;
  onRecheck: () => Promise<boolean>;
}) {
  const toast = useToast();
  const [sql, setSql] = useState<string | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [showSql, setShowSql] = useState(false);
  const [checking, setChecking] = useState(false);
  const area = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    let cancelled = false;
    fetch(`/api/setup-sql?file=${encodeURIComponent(check.file)}`)
      .then(async (r) => {
        const text = await r.text();
        if (!r.ok) throw new Error(text);
        if (!cancelled) setSql(text);
      })
      .catch((err) => !cancelled && setLoadError(errorText(err, "SQL faylni o'qib bo'lmadi.")));
    return () => {
      cancelled = true;
    };
  }, [check.file]);

  async function copy() {
    if (!sql) return;
    try {
      await navigator.clipboard.writeText(sql);
      setCopied(true);
      toast.success("SQL nusxalandi — endi SQL Editor'ga qo'ying (Ctrl+V).");
    } catch {
      // Clipboard blocked — show the text selected so Ctrl+C works.
      setShowSql(true);
      setTimeout(() => area.current?.select(), 50);
      toast.error("Avtomatik nusxa olinmadi — belgilangan matnni Ctrl+C bilan nusxalang.");
    }
  }

  async function recheck() {
    setChecking(true);
    const ok = await onRecheck();
    setChecking(false);
    if (ok) {
      toast.success(`${check.title} — o'rnatildi!`);
      onClose();
    } else {
      toast.error("Hali o'rnatilmagan. Run bosilganmi? Pastda qizil xato chiqqan bo'lsa — skrinshot yuboring.");
    }
  }

  const lines = sql ? sql.split("\n").length : 0;
  const step = "flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-bold";

  return (
    <Modal
      size="lg"
      title={`${check.title} — o'rnatish`}
      subtitle={`supabase/${check.file}`}
      onClose={onClose}
      busy={checking}
      footer={
        <>
          <ModalButton variant="ghost" onClick={onClose} disabled={checking}>
            Yopish
          </ModalButton>
          <ModalButton onClick={recheck} disabled={checking}>
            {checking ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
            Run bosdim — tekshirish
          </ModalButton>
        </>
      }
    >
      <ol className="space-y-4">
        <li className="flex gap-3">
          <span className={clsx(step, copied ? "bg-success text-white" : "bg-brand-tint text-brand")}>
            {copied ? <Check className="h-4 w-4" /> : 1}
          </span>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-foreground">SQL matnini nusxalang</p>
            <p className="text-xs text-foreground/50">Faylning hammasi — {lines || "…"} qator.</p>
            {loadError ? (
              <p className="mt-2 rounded-lg bg-danger-tint px-3 py-2 text-xs text-danger">{loadError}</p>
            ) : (
              <div className="mt-2 flex flex-wrap gap-2">
                <button
                  onClick={copy}
                  disabled={!sql}
                  className={clsx(
                    "flex items-center gap-1.5 rounded-xl px-3.5 py-2 text-sm font-semibold disabled:opacity-50",
                    copied ? "bg-success-tint text-success" : "bg-brand text-white hover:bg-brand-dark",
                  )}
                >
                  {!sql ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : copied ? (
                    <Check className="h-4 w-4" />
                  ) : (
                    <Copy className="h-4 w-4" />
                  )}
                  {copied ? "Nusxalandi" : "SQL'ni nusxalash"}
                </button>
                <button
                  onClick={() => setShowSql((v) => !v)}
                  disabled={!sql}
                  className="rounded-xl border border-border px-3.5 py-2 text-sm font-semibold text-foreground/65 hover:bg-surface-muted disabled:opacity-50"
                >
                  {showSql ? "Matnni yashirish" : "Matnni ko'rish"}
                </button>
              </div>
            )}
            {showSql && sql && (
              <textarea
                ref={area}
                readOnly
                value={sql}
                onFocus={(e) => e.currentTarget.select()}
                className="mt-2 h-56 w-full resize-y rounded-xl border border-border bg-surface-muted p-3 font-mono text-[11px] leading-relaxed text-foreground/75 outline-none"
              />
            )}
          </div>
        </li>
        <li className="flex gap-3">
          <span className={clsx(step, "bg-brand-tint text-brand")}>2</span>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-foreground">Supabase SQL Editor&apos;ni oching</p>
            <p className="text-xs text-foreground/50">Yangi tabda bo&apos;sh so&apos;rov oynasi ochiladi.</p>
            {SQL_EDITOR && (
              <a
                href={SQL_EDITOR}
                target="_blank"
                rel="noreferrer"
                className="mt-2 inline-flex items-center gap-1.5 rounded-xl border border-border px-3.5 py-2 text-sm font-semibold text-foreground/70 hover:bg-surface-muted"
              >
                <ExternalLink className="h-4 w-4" /> SQL Editor&apos;ni ochish
              </a>
            )}
          </div>
        </li>
        <li className="flex gap-3">
          <span className={clsx(step, "bg-brand-tint text-brand")}>3</span>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-foreground">Joylang va Run bosing</p>
            <p className="text-xs leading-relaxed text-foreground/50">
              Oynani bosib <b>Ctrl+V</b>, keyin o&apos;ng pastdagi yashil <b>Run</b> (yoki Ctrl+Enter). Pastda{" "}
              <b>&quot;Success. No rows returned&quot;</b> chiqsa — tayyor. Supabase &quot;destructive operation&quot; deb
              so&apos;rasa — tasdiqlang (faqat c1–c6 demo kompaniyalari o&apos;chiriladi).
            </p>
          </div>
        </li>
        <li className="flex gap-3">
          <span className={clsx(step, "bg-brand-tint text-brand")}>4</span>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-foreground">Shu yerga qaytib tekshiring</p>
            <p className="text-xs text-foreground/50">Pastdagi &quot;Run bosdim — tekshirish&quot; tugmasi.</p>
          </div>
        </li>
      </ol>
    </Modal>
  );
}
