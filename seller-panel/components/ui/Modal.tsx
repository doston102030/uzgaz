"use client";

import { FormEvent, ReactNode, useEffect, useId, useRef } from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";
import clsx from "clsx";

// Open dialogs, innermost last: only the top one reacts to Esc, and the page
// scroll is locked while any is open (a confirm can sit on top of a form).
const openStack: symbol[] = [];
let pageOverflow = "";

const WIDTH = {
  sm: "sm:max-w-md",
  md: "sm:max-w-lg",
  lg: "sm:max-w-2xl",
} as const;

/**
 * Responsive dialog — a bottom sheet on phones, a centred card from `sm`.
 * Header and footer stay put and only the body scrolls, so a tall form
 * never pushes its title or buttons off screen. Pass `onSubmit` to make
 * the whole dialog a `<form>` (submit buttons can then live in `footer`).
 */
export function Modal({
  title,
  subtitle,
  onClose,
  children,
  footer,
  onSubmit,
  size = "md",
  busy = false,
}: {
  title: ReactNode;
  subtitle?: ReactNode;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
  onSubmit?: (e: FormEvent<HTMLFormElement>) => void;
  size?: keyof typeof WIDTH;
  /** While true, Esc / backdrop / × do nothing (a save is in flight). */
  busy?: boolean;
}) {
  const titleId = useId();
  const panel = useRef<HTMLElement>(null);
  // Read inside listeners only, so a parent re-render never re-runs the effect.
  const latest = useRef({ onClose, busy });
  useEffect(() => {
    latest.current = { onClose, busy };
  });

  useEffect(() => {
    const me = Symbol("modal");
    const previous = document.activeElement as HTMLElement | null;
    if (openStack.length === 0) {
      pageOverflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
    }
    openStack.push(me);
    // Focus the first field unless something inside asked for autoFocus.
    if (!panel.current?.contains(document.activeElement)) {
      panel.current
        ?.querySelector<HTMLElement>("input:not([type=hidden]):not([disabled]), select, textarea")
        ?.focus({ preventScroll: true });
    }
    function onKey(e: KeyboardEvent) {
      if (e.key !== "Escape" || openStack[openStack.length - 1] !== me) return;
      if (!latest.current.busy) latest.current.onClose();
    }
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("keydown", onKey);
      openStack.splice(openStack.indexOf(me), 1);
      if (openStack.length === 0) document.body.style.overflow = pageOverflow;
      previous?.focus?.({ preventScroll: true });
    };
  }, []);

  const panelProps = {
    role: "dialog",
    "aria-modal": true,
    "aria-labelledby": titleId,
    className: clsx(
      "flex max-h-[92dvh] w-full flex-col rounded-t-3xl border border-border bg-surface shadow-2xl shadow-black/15 animate-sheet-in",
      "sm:max-h-[calc(100dvh-2rem)] sm:rounded-2xl sm:animate-pop-in",
      WIDTH[size],
    ),
  } as const;

  const content = (
    <>
      <div className="mx-auto mt-2.5 h-1 w-10 shrink-0 rounded-full bg-border sm:hidden" />
      <div className="flex shrink-0 items-start justify-between gap-3 border-b border-border px-5 pb-4 pt-3 sm:px-6 sm:pt-5">
        <div className="min-w-0">
          <h2 id={titleId} className="text-base font-bold text-foreground sm:text-lg">
            {title}
          </h2>
          {subtitle && <p className="mt-0.5 text-sm text-foreground/50">{subtitle}</p>}
        </div>
        <button
          type="button"
          onClick={onClose}
          disabled={busy}
          aria-label="Yopish"
          className="-mr-1.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-foreground/50 hover:bg-surface-muted hover:text-foreground disabled:opacity-40"
        >
          <X className="h-5 w-5" />
        </button>
      </div>
      <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-5 py-5 sm:px-6">{children}</div>
      {footer && (
        <div className="flex shrink-0 flex-col-reverse gap-2 border-t border-border px-5 pb-[max(1rem,env(safe-area-inset-bottom))] pt-4 sm:flex-row sm:items-center sm:justify-end sm:px-6 sm:pb-4">
          {footer}
        </div>
      )}
    </>
  );

  return createPortal(
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-foreground/45 backdrop-blur-[2px] animate-fade-in sm:items-center sm:p-4"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget && !busy) onClose();
      }}
    >
      {onSubmit ? (
        <form ref={panel as React.RefObject<HTMLFormElement>} onSubmit={onSubmit} noValidate {...panelProps}>
          {content}
        </form>
      ) : (
        <div ref={panel as React.RefObject<HTMLDivElement>} {...panelProps}>
          {content}
        </div>
      )}
    </div>,
    document.body,
  );
}

/** Footer buttons in the panels' two styles. */
export function ModalButton({
  children,
  variant = "primary",
  type = "button",
  onClick,
  disabled,
}: {
  children: ReactNode;
  variant?: "primary" | "ghost" | "danger";
  type?: "button" | "submit";
  onClick?: () => void;
  disabled?: boolean;
}) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={clsx(
        "flex items-center justify-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-60",
        variant === "primary" && "bg-brand text-white shadow-sm shadow-brand/30 hover:bg-brand-dark",
        variant === "danger" && "bg-danger text-white shadow-sm shadow-danger/30 hover:brightness-95",
        variant === "ghost" && "text-foreground/60 hover:bg-surface-muted",
      )}
    >
      {children}
    </button>
  );
}
