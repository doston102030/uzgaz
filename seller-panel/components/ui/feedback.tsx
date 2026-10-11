"use client";

import { createContext, ReactNode, useCallback, useContext, useRef, useState } from "react";
import { AlertTriangle, CheckCircle2, Info, X, XCircle } from "lucide-react";
import clsx from "clsx";
import { Modal, ModalButton } from "./Modal";

// ── Toasts ───────────────────────────────────────────────────────────

type ToastTone = "success" | "error" | "info";
interface ToastItem {
  id: number;
  tone: ToastTone;
  message: string;
}

interface ToastApi {
  success: (message: string) => void;
  error: (message: string) => void;
  info: (message: string) => void;
}

// ── Confirm ──────────────────────────────────────────────────────────

export interface ConfirmOptions {
  title: string;
  message?: ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  /** Red confirm button — deleting, cancelling, suspending. */
  danger?: boolean;
}

const ToastContext = createContext<ToastApi | null>(null);
const ConfirmContext = createContext<((o: ConfirmOptions) => Promise<boolean>) | null>(null);

const TONE = {
  success: { icon: CheckCircle2, className: "text-success" },
  error: { icon: XCircle, className: "text-danger" },
  info: { icon: Info, className: "text-brand" },
} as const;

/** Toasts + a promise-based confirm dialog, replacing alert()/confirm(). */
export function UiProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const nextId = useRef(1);

  const dismiss = useCallback((id: number) => {
    setToasts((cur) => cur.filter((t) => t.id !== id));
  }, []);

  const push = useCallback(
    (tone: ToastTone, message: string) => {
      const id = nextId.current++;
      setToasts((cur) => [...cur.slice(-2), { id, tone, message }]);
      setTimeout(() => dismiss(id), tone === "error" ? 6000 : 3500);
    },
    [dismiss],
  );

  const [toastApi] = useState<ToastApi>(() => ({
    success: (m) => push("success", m),
    error: (m) => push("error", m),
    info: (m) => push("info", m),
  }));

  const [pending, setPending] = useState<
    (ConfirmOptions & { resolve: (ok: boolean) => void }) | null
  >(null);

  const confirm = useCallback(
    (options: ConfirmOptions) =>
      new Promise<boolean>((resolve) => setPending({ ...options, resolve })),
    [],
  );

  function settle(ok: boolean) {
    pending?.resolve(ok);
    setPending(null);
  }

  return (
    <ToastContext.Provider value={toastApi}>
      <ConfirmContext.Provider value={confirm}>
        {children}

        {pending && (
          <Modal
            size="sm"
            title={
              <span className="flex items-center gap-2">
                {pending.danger && <AlertTriangle className="h-5 w-5 shrink-0 text-danger" />}
                {pending.title}
              </span>
            }
            onClose={() => settle(false)}
            footer={
              <>
                <ModalButton variant="ghost" onClick={() => settle(false)}>
                  {pending.cancelLabel ?? "Bekor qilish"}
                </ModalButton>
                <ModalButton variant={pending.danger ? "danger" : "primary"} onClick={() => settle(true)}>
                  {pending.confirmLabel ?? "Tasdiqlash"}
                </ModalButton>
              </>
            }
          >
            {pending.message && (
              <div className="text-sm leading-relaxed text-foreground/65">{pending.message}</div>
            )}
          </Modal>
        )}

        <div
          aria-live="polite"
          className="pointer-events-none fixed inset-x-0 bottom-0 z-[60] flex flex-col items-center gap-2 p-4 pb-[max(1rem,env(safe-area-inset-bottom))] sm:items-end sm:p-6"
        >
          {toasts.map((t) => {
            const { icon: Icon, className } = TONE[t.tone];
            return (
              <div
                key={t.id}
                role={t.tone === "error" ? "alert" : "status"}
                className="pointer-events-auto flex w-full max-w-sm items-start gap-3 rounded-2xl border border-border bg-surface px-4 py-3 shadow-lg shadow-black/10 animate-sheet-in"
              >
                <Icon className={clsx("mt-0.5 h-5 w-5 shrink-0", className)} />
                <p className="min-w-0 flex-1 text-sm text-foreground/80">{t.message}</p>
                <button
                  type="button"
                  onClick={() => dismiss(t.id)}
                  aria-label="Yopish"
                  className="-mr-1 flex h-6 w-6 shrink-0 items-center justify-center rounded-lg text-foreground/40 hover:bg-surface-muted"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            );
          })}
        </div>
      </ConfirmContext.Provider>
    </ToastContext.Provider>
  );
}

export function useToast(): ToastApi {
  const api = useContext(ToastContext);
  if (!api) throw new Error("useToast() UiProvider ichida chaqirilishi kerak.");
  return api;
}

export function useConfirm() {
  const confirm = useContext(ConfirmContext);
  if (!confirm) throw new Error("useConfirm() UiProvider ichida chaqirilishi kerak.");
  return confirm;
}

/** Turns any thrown value into a short Uzbek message for a toast. */
export function errorText(err: unknown, fallback = "Noma'lum xatolik yuz berdi."): string {
  if (err instanceof Error && err.message) return err.message;
  if (err && typeof err === "object" && "message" in err && typeof err.message === "string") {
    return err.message;
  }
  return fallback;
}
