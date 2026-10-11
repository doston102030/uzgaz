"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { AlertTriangle, Loader2 } from "lucide-react";
import { ShellProvider } from "@/components/Shell";
import { Sidebar } from "@/components/Sidebar";
import { restoreSession, SellerSession, signOut as clearSession } from "@/lib/auth";

interface SessionContextValue {
  seller: SellerSession;
  signOut: () => void;
}

const SessionContext = createContext<SessionContextValue | null>(null);

/** Kirgan sotuvchi. Faqat AuthGate ichida (login sahifasidan tashqari) ishlatiladi. */
export function useSeller(): SessionContextValue {
  const value = useContext(SessionContext);
  if (!value) throw new Error("useSeller() AuthGate ichida chaqirilishi kerak.");
  return value;
}

/** Login sahifasi `onSignedIn` bilan sessiyani shu yerga uzatadi. */
const SignInContext = createContext<(seller: SellerSession) => void>(() => {});

export function useSignedIn() {
  return useContext(SignInContext);
}

type GateState =
  | { kind: "checking" }
  | { kind: "signedOut" }
  | { kind: "signedIn"; seller: SellerSession }
  | { kind: "error"; message: string };

const LOGIN_PATH = "/login";

// Faqat tasdiqlangan sotuvchi xaridorlarga ko'rinadi (marketplace_setup.sql).
const STATUS_NOTICE: Partial<Record<SellerSession["status"], string>> = {
  pending:
    "Hisobingiz administrator tasdig'ini kutmoqda — tasdiqlangach, mahsulotlaringiz ilovada ko'rinadi.",
  suspended:
    "Hisobingiz vaqtincha to'xtatilgan — mahsulotlaringiz xaridorlarga ko'rinmaydi. Administrator bilan bog'laning.",
  rejected:
    "Arizangiz rad etilgan — mahsulotlaringiz xaridorlarga ko'rinmaydi. Administrator bilan bog'laning.",
};

/**
 * Panelga faqat admin bergan login/parol bilan kiriladi: sessiya yo'q bo'lsa
 * har qanday sahifa /login ga, kirgan sotuvchi esa /login dan bosh sahifaga
 * yo'naltiriladi.
 */
export function AuthGate({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [state, setState] = useState<GateState>({ kind: "checking" });
  const onLoginPage = pathname === LOGIN_PATH;

  // Bumped by "Qayta urinish" to run the check again.
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let cancelled = false;
    const check = (quiet: boolean) =>
      restoreSession()
        .then((seller) => {
          if (!cancelled) setState(seller ? { kind: "signedIn", seller } : { kind: "signedOut" });
        })
        .catch((err) => {
          // Fonda tekshirishda tarmoq uzilsa, ochiq sahifani buzmaymiz.
          if (!cancelled && !quiet) {
            setState({
              kind: "error",
              message: err instanceof Error ? err.message : "Serverga ulanib bo'lmadi.",
            });
          }
        });
    check(false);
    // Admin parolni yangilasa yoki holatni o'zgartirsa — oynaga qaytganda bilinadi.
    function onVisible() {
      if (document.visibilityState === "visible") check(true);
    }
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      cancelled = true;
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, [attempt]);

  useEffect(() => {
    if (state.kind === "signedOut" && !onLoginPage) router.replace(LOGIN_PATH);
    if (state.kind === "signedIn" && onLoginPage) router.replace("/");
  }, [state.kind, onLoginPage, router]);

  const signOut = useCallback(() => {
    clearSession();
    setState({ kind: "signedOut" });
  }, []);

  const onSignedIn = useCallback((seller: SellerSession) => {
    setState({ kind: "signedIn", seller });
  }, []);

  if (state.kind === "error") {
    return (
      <div className="flex flex-1 items-center justify-center p-6">
        <div className="max-w-sm rounded-2xl border border-border bg-surface p-6 text-center">
          <p className="text-sm font-semibold text-foreground">Serverga ulanib bo&apos;lmadi</p>
          <p className="mt-1 text-xs text-foreground/50">{state.message}</p>
          <button
            onClick={() => {
              setState({ kind: "checking" });
              setAttempt((n) => n + 1);
            }}
            className="mt-4 rounded-xl bg-brand px-4 py-2 text-sm font-semibold text-white hover:bg-brand-dark"
          >
            Qayta urinish
          </button>
        </div>
      </div>
    );
  }

  if (onLoginPage && state.kind === "signedOut") {
    return (
      <SignInContext.Provider value={onSignedIn}>
        <div className="flex min-w-0 flex-1 flex-col">{children}</div>
      </SignInContext.Provider>
    );
  }

  if (state.kind !== "signedIn" || onLoginPage) {
    return (
      <div className="flex flex-1 items-center justify-center text-foreground/40">
        <Loader2 className="h-5 w-5 animate-spin" />
      </div>
    );
  }

  const notice = STATUS_NOTICE[state.seller.status];
  return (
    <SessionContext.Provider value={{ seller: state.seller, signOut }}>
      <ShellProvider>
        <Sidebar />
        <div className="flex min-w-0 flex-1 flex-col">
          {notice && (
            <p className="flex items-start gap-2 border-b border-warning/30 bg-warning-tint px-4 py-2.5 text-xs font-medium text-foreground/75 sm:px-6">
              <AlertTriangle className="mt-px h-3.5 w-3.5 shrink-0 text-warning" />
              {notice}
            </p>
          )}
          {children}
        </div>
      </ShellProvider>
    </SessionContext.Provider>
  );
}
