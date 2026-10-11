"use client";

import { createContext, ReactNode, useCallback, useContext, useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { Sidebar } from "@/components/Sidebar";
import { UiProvider } from "@/components/ui/feedback";
import { AdminAlerts, fetchAdminAlerts } from "@/lib/db";

interface ShellValue {
  /** Phone/tablet: the sidebar drawer is open. */
  navOpen: boolean;
  setNavOpen: (open: boolean) => void;
  alerts: AdminAlerts;
  /** Re-read the bell counts right after an action (approve, reject…). */
  refreshAlerts: () => void;
}

const EMPTY: AdminAlerts = { pendingSellers: 0, pendingProducts: 0, newOrders: 0 };
const ShellContext = createContext<ShellValue | null>(null);

/** Page chrome for every admin page: toasts/confirm, sidebar/drawer, bell counts. */
export function AdminShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const [navOpen, setNavOpen] = useState(false);
  const [openedAt, setOpenedAt] = useState(pathname);
  const [alerts, setAlerts] = useState<AdminAlerts>(EMPTY);
  const [tick, setTick] = useState(0);

  // Navigating closes the drawer (during render, no effect needed).
  if (openedAt !== pathname) {
    setOpenedAt(pathname);
    if (navOpen) setNavOpen(false);
  }

  useEffect(() => {
    let cancelled = false;
    const load = () =>
      fetchAdminAlerts()
        .then((a) => !cancelled && setAlerts(a))
        .catch(() => {});
    void load();
    const timer = setInterval(() => {
      if (!document.hidden) void load();
    }, 30_000);
    const onFocus = () => void load();
    window.addEventListener("focus", onFocus);
    return () => {
      cancelled = true;
      clearInterval(timer);
      window.removeEventListener("focus", onFocus);
    };
  }, [tick]);

  const refreshAlerts = useCallback(() => setTick((n) => n + 1), []);

  return (
    <UiProvider>
      <ShellContext.Provider value={{ navOpen, setNavOpen, alerts, refreshAlerts }}>
        <Sidebar />
        <div className="flex min-w-0 flex-1 flex-col">{children}</div>
      </ShellContext.Provider>
    </UiProvider>
  );
}

export function useShell(): ShellValue {
  const value = useContext(ShellContext);
  if (!value) throw new Error("useShell() AdminShell ichida chaqirilishi kerak.");
  return value;
}
