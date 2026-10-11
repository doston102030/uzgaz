"use client";

import { useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  PackageSearch,
  ClipboardList,
  Store,
  BarChart3,
  Flame,
  X,
} from "lucide-react";
import clsx from "clsx";
import { useSeller } from "@/components/AuthGate";
import { useShell } from "@/components/Shell";
import { SellerSession } from "@/lib/auth";

const STATUS_TEXT: Record<SellerSession["status"], string> = {
  approved: "Hisobingiz tasdiqlangan va faol — buyurtmalar qabul qilishingiz mumkin.",
  pending: "Hisobingiz hali admin tomonidan tekshirilmoqda — biroz kuting.",
  rejected: "Hisobingiz rad etilgan. Batafsil uchun admin bilan bog'laning.",
  suspended: "Hisobingiz vaqtincha to'xtatilgan — buyurtma qabul qilolmaysiz.",
};

const STATUS_DOT: Record<SellerSession["status"], string> = {
  approved: "bg-success",
  pending: "bg-warning",
  rejected: "bg-danger",
  suspended: "bg-danger",
};

const NAV = [
  { href: "/", label: "Bosh sahifa", icon: LayoutDashboard },
  { href: "/products", label: "Mahsulotlarim", icon: PackageSearch },
  { href: "/orders", label: "Buyurtmalar", icon: ClipboardList },
  { href: "/reports", label: "Hisobotlar", icon: BarChart3 },
  { href: "/profile", label: "Profil", icon: Store },
] as const;

function SidebarContent({ onClose }: { onClose?: () => void }) {
  const pathname = usePathname();
  const { seller } = useSeller();
  const { alerts } = useShell();
  const badge: Partial<Record<(typeof NAV)[number]["href"], number>> = {
    "/orders": alerts.newOrders,
    "/products": alerts.rejectedProducts,
  };

  return (
    <>
      <div className="flex items-center gap-2.5 px-6 py-6">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-brand-light to-brand-dark shadow-sm shadow-brand/30">
          <Flame className="h-5 w-5 text-white" strokeWidth={2.4} />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-bold leading-tight text-foreground">Gaz &amp; Energiya</p>
          <p className="text-xs leading-tight text-foreground/50">Sotuvchi panel</p>
        </div>
        {onClose && (
          <button
            type="button"
            onClick={onClose}
            aria-label="Menyuni yopish"
            className="-mr-2 flex h-9 w-9 items-center justify-center rounded-xl text-foreground/50 hover:bg-surface-muted"
          >
            <X className="h-5 w-5" />
          </button>
        )}
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto px-3">
        {NAV.map(({ href, label, icon: Icon }) => {
          const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
          const count = badge[href] ?? 0;
          return (
            <Link
              key={href}
              href={href}
              aria-current={active ? "page" : undefined}
              className={clsx(
                "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
                active
                  ? "bg-brand-tint text-brand"
                  : "text-foreground/60 hover:bg-surface-muted hover:text-foreground",
              )}
            >
              <Icon className="h-[18px] w-[18px]" strokeWidth={2.2} />
              <span className="flex-1">{label}</span>
              {count > 0 && (
                <span
                  className={clsx(
                    "min-w-5 rounded-full px-1.5 py-0.5 text-center text-[11px] font-bold",
                    href === "/orders" ? "bg-brand text-white" : "bg-danger-tint text-danger",
                  )}
                >
                  {count > 99 ? "99+" : count}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      <div className="m-3 rounded-2xl border border-border bg-surface-muted p-4">
        <p className="flex items-center gap-2 text-xs font-semibold text-foreground/70">
          <span className={clsx("h-2 w-2 shrink-0 rounded-full", STATUS_DOT[seller.status])} />
          <span className="truncate">{seller.companyName}</span>
        </p>
        <p className="mt-1 text-xs text-foreground/50">{STATUS_TEXT[seller.status]}</p>
      </div>
    </>
  );
}

export function Sidebar() {
  const { navOpen, setNavOpen } = useShell();

  useEffect(() => {
    if (!navOpen) return;
    const { overflow } = document.body.style;
    document.body.style.overflow = "hidden";
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setNavOpen(false);
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = overflow;
      window.removeEventListener("keydown", onKey);
    };
  }, [navOpen, setNavOpen]);

  return (
    <>
      <aside className="sticky top-0 hidden h-dvh w-64 shrink-0 flex-col border-r border-border bg-surface lg:flex">
        <SidebarContent />
      </aside>

      {navOpen && (
        <div
          className="fixed inset-0 z-40 bg-foreground/45 backdrop-blur-[2px] animate-fade-in lg:hidden"
          onMouseDown={(e) => e.target === e.currentTarget && setNavOpen(false)}
        >
          <aside
            role="dialog"
            aria-modal="true"
            aria-label="Menyu"
            className="flex h-full w-[min(18rem,85vw)] flex-col bg-surface shadow-2xl animate-drawer-in"
          >
            <SidebarContent onClose={() => setNavOpen(false)} />
          </aside>
        </div>
      )}
    </>
  );
}
