"use client";

import { createContext, ReactNode, useCallback, useContext, useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { fetchSellerAlerts, SellerAlerts } from "@/lib/db";

interface ShellValue {
  /** Telefon/planshetda yon menyu (drawer) ochiqmi. */
  navOpen: boolean;
  setNavOpen: (open: boolean) => void;
  alerts: SellerAlerts;
  /** Amaldan keyin (buyurtma holati, mahsulot) qo'ng'iroqchani darhol yangilash. */
  refreshAlerts: () => void;
}

const EMPTY: SellerAlerts = { newOrders: 0, rejectedProducts: 0, pendingProducts: 0 };
const ShellContext = createContext<ShellValue | null>(null);

export function ShellProvider({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const [navOpen, setNavOpen] = useState(false);
  const [openedAt, setOpenedAt] = useState(pathname);
  const [alerts, setAlerts] = useState<SellerAlerts>(EMPTY);
  const [tick, setTick] = useState(0);

  // Sahifa almashsa drawer yopiladi (render paytida — effektsiz).
  if (openedAt !== pathname) {
    setOpenedAt(pathname);
    if (navOpen) setNavOpen(false);
  }

  useEffect(() => {
    let cancelled = false;
    const load = () =>
      fetchSellerAlerts()
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
    <ShellContext.Provider value={{ navOpen, setNavOpen, alerts, refreshAlerts }}>
      {children}
    </ShellContext.Provider>
  );
}

export function useShell(): ShellValue {
  const value = useContext(ShellContext);
  if (!value) throw new Error("useShell() ShellProvider ichida chaqirilishi kerak.");
  return value;
}
