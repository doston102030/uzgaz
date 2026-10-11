"use client";

import { ReactNode, useEffect, useRef, useState } from "react";
import { CheckCircle2, Eraser, Loader2, Scissors, Sparkles, TriangleAlert } from "lucide-react";
import clsx from "clsx";
import { Modal, ModalButton } from "@/components/ui/Modal";
import {
  analyzeImage,
  FitOptions,
  fitProductImage,
  FittedImage,
  ImageAnalysis,
  LoadedImage,
  loadImage,
} from "@/lib/productImage";

const SIDE: Record<FittedImage["cutEdges"][number], string> = {
  top: "yuqori",
  bottom: "pastki",
  left: "chap",
  right: "o'ng",
};

const BACKGROUND_NOTE: Record<ImageAnalysis["background"], { tone: "ok" | "fix" | "info"; text: string }> = {
  transparent: { tone: "ok", text: "Fon shaffof — faqat bo'sh chetlar kesiladi." },
  checker: {
    tone: "fix",
    text: "Shaxmat katakli fon topildi. Bu soxta shaffoflik — katak rasmning o'ziga chizilgan va ilovada ko'rinib qoladi.",
  },
  solid: { tone: "fix", text: "Bir xil rangli fon topildi — olib tashlansa, mahsulot ilova foniga chiroyli qo'shiladi." },
  photo: {
    tone: "info",
    text: "Surat foni murakkab — rasm faqat kichraytiriladi. Eng chiroyli natija uchun oq yoki shaffof fonli rasm yuklang.",
  },
};

/**
 * Yuklashdan oldin mahsulot rasmini ilovaga moslash: bo'sh chetlarni kesish, oq yoki
 * katak fonni olib tashlash. O'ng tomonda — ilovaning mahsulot sahifasidagi ko'rinishi.
 */
export function ImageFitDialog({
  source,
  onClose,
  onApply,
  onKeepOriginal,
}: {
  source: File | string;
  onClose: () => void;
  onApply: (image: FittedImage) => void;
  /** Yangi fayl uchun: moslamasdan, asl holicha yuklash. */
  onKeepOriginal?: () => void;
}) {
  const [fileUrl, setFileUrl] = useState<string | null>(null);
  const [loaded, setLoaded] = useState<{ image: LoadedImage; analysis: ImageAnalysis } | null>(null);
  const [opts, setOpts] = useState<FitOptions>({ trim: true, removeBackground: false });
  /** `opts` — qaysi sozlama bilan chiqqani; joriy sozlamadan farq qilsa, hali ishlanmoqda. */
  const [result, setResult] = useState<{ image: FittedImage; url: string; opts: FitOptions } | null>(null);
  const resultUrl = useRef<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    const url = typeof source === "string" ? null : URL.createObjectURL(source);
    loadImage(source)
      .then((image) => {
        if (cancelled) return;
        const analysis = analyzeImage(image);
        setFileUrl(url);
        setLoaded({ image, analysis });
        setOpts({ trim: analysis.background !== "photo", removeBackground: analysis.suggestRemoval });
      })
      .catch((err: unknown) => {
        if (cancelled) return;
        setFileUrl(url);
        setError(err instanceof Error ? err.message : "Rasmni ochib bo'lmadi.");
      });
    return () => {
      cancelled = true;
      if (url) URL.revokeObjectURL(url);
    };
  }, [source]);

  useEffect(() => {
    if (!loaded) return;
    let cancelled = false;
    fitProductImage(loaded.image, loaded.analysis, opts)
      .then((image) => {
        if (cancelled) return;
        const url = URL.createObjectURL(image.blob);
        if (resultUrl.current) URL.revokeObjectURL(resultUrl.current);
        resultUrl.current = url;
        setResult({ image, url, opts });
      })
      .catch((err: unknown) => {
        if (!cancelled) setError(err instanceof Error ? err.message : "Rasmni moslab bo'lmadi.");
      });
    return () => {
      cancelled = true;
    };
  }, [loaded, opts]);

  // Oxirgi natija URL'i oyna yopilganda bo'shatiladi.
  useEffect(
    () => () => {
      if (resultUrl.current) URL.revokeObjectURL(resultUrl.current);
    },
    [],
  );

  const originalUrl = typeof source === "string" ? source : fileUrl;
  const working = !error && (!result || result.opts !== opts);
  const analysis = loaded?.analysis;
  const fitted = result?.image;
  const note = analysis ? BACKGROUND_NOTE[analysis.background] : null;
  const canRemove = analysis?.background === "solid" || analysis?.background === "checker";
  const longSide = fitted ? Math.max(fitted.width, fitted.height) : 0;

  return (
    <Modal
      size="lg"
      title="Rasmni moslash"
      subtitle="Ilovada mahsulot katta va toza ko'rinishi uchun"
      onClose={onClose}
      footer={
        <>
          <ModalButton variant="ghost" onClick={onClose}>
            Bekor qilish
          </ModalButton>
          {onKeepOriginal && (
            <ModalButton variant="ghost" onClick={onKeepOriginal}>
              Asl holicha
            </ModalButton>
          )}
          <ModalButton onClick={() => fitted && onApply(fitted)} disabled={!fitted || working || !!error}>
            {working && <Loader2 className="h-4 w-4 animate-spin" />}
            Moslab qo&apos;yish
          </ModalButton>
        </>
      }
    >
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-[1fr_1.25fr] sm:gap-4">
          <Figure
            label="Asl rasm"
            caption={
              loaded
                ? `${loaded.image.naturalWidth}×${loaded.image.naturalHeight}${
                    loaded.image.bytes ? ` · ${formatBytes(loaded.image.bytes)}` : ""
                  }`
                : "…"
            }
          >
            <div className="flex aspect-[4/5] items-center justify-center overflow-hidden rounded-xl border border-border bg-surface-muted p-2">
              {originalUrl && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={originalUrl} alt="Asl rasm" className="max-h-full max-w-full object-contain" />
              )}
            </div>
          </Figure>

          <Figure
            label="Ilovada shunday ko'rinadi"
            caption={
              fitted
                ? `${fitted.width}×${fitted.height} · ${fitted.blob.type.replace("image/", "").toUpperCase()} · ${formatBytes(fitted.blob.size)}`
                : "…"
            }
          >
            <AppHeroPreview src={result?.url} working={working} error={error} />
          </Figure>
        </div>

        {note && (
          <p
            className={clsx(
              "flex items-start gap-2 rounded-xl px-3.5 py-2.5 text-xs leading-relaxed",
              note.tone === "ok" && "bg-success-tint text-success",
              note.tone === "fix" && "bg-brand-tint text-brand-deep",
              note.tone === "info" && "bg-surface-muted text-foreground/60",
            )}
          >
            {note.tone === "ok" ? (
              <CheckCircle2 className="mt-px h-4 w-4 shrink-0" />
            ) : (
              <Sparkles className="mt-px h-4 w-4 shrink-0" />
            )}
            {note.text}
          </p>
        )}

        {analysis && (
          <div className="divide-y divide-border rounded-xl border border-border">
            <Toggle
              icon={<Scissors className="h-4 w-4" />}
              title="Bo'sh chetlarni kesish"
              hint="Mahsulot kadrni to'ldiradi — ilovada kichik bo'lib qolmaydi"
              checked={opts.trim}
              disabled={analysis.background === "photo"}
              onChange={(trim) => setOpts((o) => ({ ...o, trim }))}
            />
            {canRemove && (
              <Toggle
                icon={<Eraser className="h-4 w-4" />}
                title="Fonni olib tashlash"
                hint={
                  analysis.background === "checker"
                    ? "Katakli fon o'chiriladi, mahsulotning o'zi qoladi"
                    : "Fon shaffof bo'ladi — natijani o'ngda tekshiring"
                }
                checked={opts.removeBackground}
                onChange={(removeBackground) => setOpts((o) => ({ ...o, removeBackground }))}
              />
            )}
          </div>
        )}

        {fitted && fitted.cutEdges.length > 0 && (
          <Warning>
            Mahsulot rasmning {fitted.cutEdges.map((s) => SIDE[s]).join(", ")} chetiga tegib turibdi — surat kesilgan
            bo&apos;lsa, mahsulot to&apos;liq ko&apos;rinadigan rasmni yuklang.
          </Warning>
        )}
        {fitted && longSide < 700 && (
          <Warning>
            Rasm kichik ({fitted.width}×{fitted.height}) — telefonda xira chiqishi mumkin. Kamida 800 px li rasm
            tavsiya etiladi.
          </Warning>
        )}
      </div>
    </Modal>
  );
}

/** Ilovadagi mahsulot sahifasi tepasi: yumshoq ko'k nur, mahsulot soya ustida "turadi" (pastga tekislangan). */
function AppHeroPreview({ src, working, error }: { src?: string; working: boolean; error: string | null }) {
  return (
    <div
      className="relative aspect-[4/5] overflow-hidden rounded-xl border border-border"
      style={{
        background:
          "radial-gradient(70% 55% at 50% 42%, color-mix(in srgb, var(--color-brand) 14%, transparent), transparent 70%), linear-gradient(180deg, color-mix(in srgb, var(--color-brand) 16%, var(--background)), var(--background))",
      }}
    >
      <div className="absolute inset-x-0 bottom-[7%] mx-auto h-[5%] w-1/2 rounded-[50%] bg-foreground/10 blur-md" />
      {src && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={src}
          alt="Ilovadagi ko'rinish"
          className="absolute inset-0 h-full w-full object-contain object-bottom px-[8%] pb-[9%] pt-[14%]"
        />
      )}
      <span className="absolute left-2.5 top-2.5 h-6 w-6 rounded-full bg-surface/90 shadow-sm" />
      <span className="absolute right-2.5 top-2.5 h-6 w-6 rounded-full bg-surface/90 shadow-sm" />
      {(working || error) && (
        <span className="absolute inset-0 flex items-center justify-center bg-surface/40 p-4 text-center">
          {error ? (
            <span className="rounded-lg bg-danger-tint px-3 py-2 text-xs text-danger">{error}</span>
          ) : (
            <Loader2 className="h-6 w-6 animate-spin text-brand" />
          )}
        </span>
      )}
    </div>
  );
}

function Figure({ label, caption, children }: { label: string; caption: string; children: ReactNode }) {
  return (
    <figure className="min-w-0">
      <p className="mb-1.5 text-xs font-medium text-foreground/55">{label}</p>
      {children}
      <figcaption className="mt-1.5 truncate text-[11px] tabular-nums text-foreground/40">{caption}</figcaption>
    </figure>
  );
}

function Toggle({
  icon,
  title,
  hint,
  checked,
  disabled,
  onChange,
}: {
  icon: ReactNode;
  title: string;
  hint: string;
  checked: boolean;
  disabled?: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <label
      className={clsx(
        "flex items-center gap-3 px-3.5 py-3",
        disabled ? "cursor-not-allowed opacity-50" : "cursor-pointer hover:bg-surface-muted/60",
      )}
    >
      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-brand-tint text-brand">
        {icon}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-sm font-semibold text-foreground">{title}</span>
        <span className="block text-xs text-foreground/50">{hint}</span>
      </span>
      <input
        type="checkbox"
        role="switch"
        className="peer sr-only"
        checked={checked}
        disabled={disabled}
        onChange={(e) => onChange(e.target.checked)}
      />
      <span
        aria-hidden
        className={clsx(
          "relative h-6 w-10 shrink-0 rounded-full transition-colors peer-focus-visible:ring-2 peer-focus-visible:ring-brand-light",
          checked ? "bg-brand" : "bg-foreground/15",
        )}
      >
        <span
          className={clsx(
            "absolute top-0.5 h-5 w-5 rounded-full bg-white shadow-sm transition-transform",
            checked ? "translate-x-[18px]" : "translate-x-0.5",
          )}
        />
      </span>
    </label>
  );
}

function Warning({ children }: { children: ReactNode }) {
  return (
    <p className="flex items-start gap-2 rounded-xl bg-warning-tint px-3.5 py-2.5 text-xs leading-relaxed text-warning">
      <TriangleAlert className="mt-px h-4 w-4 shrink-0" />
      <span>{children}</span>
    </p>
  );
}

function formatBytes(bytes: number): string {
  if (bytes < 1024 * 1024) return `${Math.max(1, Math.round(bytes / 1024))} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}
