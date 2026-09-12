"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Building2,
  PackageSearch,
  Users,
  ClipboardList,
  Settings,
  Flame,
} from "lucide-react";
import clsx from "clsx";

const NAV = [
  { href: "/", label: "Bosh sahifa", icon: LayoutDashboard },
  { href: "/companies", label: "Kompaniyalar", icon: Building2 },
  { href: "/products", label: "Mahsulotlar", icon: PackageSearch },
  { href: "/sellers", label: "Sotuvchilar", icon: Users },
  { href: "/orders", label: "Buyurtmalar", icon: ClipboardList },
  { href: "/settings", label: "Sozlamalar", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden w-64 shrink-0 flex-col border-r border-border bg-surface md:flex">
      <div className="flex items-center gap-2.5 px-6 py-6">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-brand-light to-brand-dark shadow-sm shadow-brand/30">
          <Flame className="h-5 w-5 text-white" strokeWidth={2.4} />
        </div>
        <div>
          <p className="text-sm font-bold leading-tight text-foreground">Gaz &amp; Energiya</p>
          <p className="text-xs leading-tight text-foreground/50">Admin panel</p>
        </div>
      </div>

      <nav className="flex-1 space-y-1 px-3">
        {NAV.map(({ href, label, icon: Icon }) => {
          const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className={clsx(
                "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
                active
                  ? "bg-brand-tint text-brand"
                  : "text-foreground/60 hover:bg-surface-muted hover:text-foreground",
              )}
            >
              <Icon className="h-[18px] w-[18px]" strokeWidth={2.2} />
              {label}
            </Link>
          );
        })}
      </nav>

      <div className="m-3 rounded-2xl border border-border bg-surface-muted p-4">
        <p className="text-xs font-semibold text-foreground/70">Andijon viloyati</p>
        <p className="mt-1 text-xs text-foreground/50">
          Barcha kompaniya va mahsulotlar Andijon shahri va tumanlari bo&apos;yicha boshqariladi.
        </p>
      </div>
    </aside>
  );
}
