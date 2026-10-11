"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { Bell, ClipboardList, Menu, PackageSearch, UserPlus, type LucideIcon } from "lucide-react";
import clsx from "clsx";
import { useShell } from "@/components/Shell";

export function Topbar({ title, subtitle }: { title: string; subtitle?: string }) {
  const { setNavOpen } = useShell();
  return (
    <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-border bg-surface/85 px-4 py-3.5 backdrop-blur sm:px-6 sm:py-5">
      <button
        type="button"
        onClick={() => setNavOpen(true)}
        aria-label="Menyu"
        className="-ml-1 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-foreground/70 hover:bg-surface-muted lg:hidden"
      >
        <Menu className="h-5 w-5" />
      </button>
      <div className="min-w-0 flex-1">
        <h1 className="truncate text-lg font-bold text-foreground sm:text-xl">{title}</h1>
        {subtitle && <p className="mt-0.5 truncate text-xs text-foreground/50 sm:text-sm">{subtitle}</p>}
      </div>
      <div className="flex shrink-0 items-center gap-2 sm:gap-3">
        <NotificationBell />
        <div className="flex items-center gap-2.5 rounded-xl border border-border bg-surface p-1 sm:py-1.5 sm:pl-1.5 sm:pr-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-brand-light to-brand text-xs font-bold text-white">
            AD
          </div>
          <div className="hidden leading-tight md:block">
            <p className="text-sm font-semibold text-foreground">Administrator</p>
            <p className="text-xs text-foreground/45">Andijon viloyati</p>
          </div>
        </div>
      </div>
    </header>
  );
}

interface AlertItem {
  icon: LucideIcon;
  tone: string;
  text: string;
  href: string;
}

function NotificationBell() {
  const { alerts } = useShell();
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (!box.current?.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", onDown);
    window.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDown);
      window.removeEventListener("keydown", onKey);
    };
  }, [open]);

  const items: AlertItem[] = [
    alerts.pendingSellers > 0 && {
      icon: UserPlus,
      tone: "bg-warning-tint text-warning",
      text: `${alerts.pendingSellers} ta yangi sotuvchi arizasi tasdiq kutmoqda`,
      href: "/sellers?tab=pending",
    },
    alerts.pendingProducts > 0 && {
      icon: PackageSearch,
      tone: "bg-brand-tint text-brand",
      text: `${alerts.pendingProducts} ta mahsulot moderatsiyani kutmoqda`,
      href: "/products",
    },
    alerts.newOrders > 0 && {
      icon: ClipboardList,
      tone: "bg-info-tint text-info",
      text: `${alerts.newOrders} ta buyurtmani sotuvchilar hali qabul qilmagan`,
      href: "/orders?status=qabulQilindi",
    },
  ].filter(Boolean) as AlertItem[];
  const total = alerts.pendingSellers + alerts.pendingProducts;

  return (
    <div ref={box} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-label="Bildirishnomalar"
        aria-expanded={open}
        className={clsx(
          "relative flex h-10 w-10 items-center justify-center rounded-xl border border-border bg-surface text-foreground/60 hover:bg-surface-muted",
          open && "bg-surface-muted",
        )}
      >
        <Bell className="h-[18px] w-[18px]" />
        {total > 0 && (
          <span className="absolute -right-1 -top-1 min-w-[18px] rounded-full bg-danger px-1 text-center text-[10px] font-bold leading-[18px] text-white ring-2 ring-surface">
            {total > 9 ? "9+" : total}
          </span>
        )}
      </button>
      {open && (
        <div className="fixed inset-x-4 top-16 z-40 rounded-2xl border border-border bg-surface p-2 shadow-xl shadow-black/10 animate-pop-in sm:absolute sm:inset-x-auto sm:right-0 sm:top-12 sm:w-80">
          <p className="px-3 pb-1 pt-2 text-xs font-semibold uppercase tracking-wide text-foreground/40">
            Bildirishnomalar
          </p>
          {items.length === 0 ? (
            <p className="px-3 py-6 text-center text-sm text-foreground/45">Hammasi joyida — kutayotgan ish yo&apos;q.</p>
          ) : (
            items.map(({ icon: Icon, tone, text, href }) => (
              <Link
                key={href}
                href={href}
                onClick={() => setOpen(false)}
                className="flex items-start gap-3 rounded-xl p-3 hover:bg-surface-muted"
              >
                <span className={clsx("flex h-8 w-8 shrink-0 items-center justify-center rounded-lg", tone)}>
                  <Icon className="h-4 w-4" />
                </span>
                <span className="pt-1 text-sm leading-snug text-foreground/75">{text}</span>
              </Link>
            ))
          )}
        </div>
      )}
    </div>
  );
}
