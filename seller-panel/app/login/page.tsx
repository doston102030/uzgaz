"use client";

import { FormEvent, useState } from "react";
import { Eye, EyeOff, Flame, Loader2, LockKeyhole, UserRound } from "lucide-react";
import { useSignedIn } from "@/components/AuthGate";
import { signIn } from "@/lib/auth";

const fieldClass =
  "flex items-center gap-2.5 rounded-xl border border-border bg-surface-muted px-3 focus-within:border-brand-light focus-within:bg-surface";

export default function LoginPage() {
  const onSignedIn = useSignedIn();
  const [login, setLogin] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!login.trim() || !password) {
      setError("Login va parolni kiriting.");
      return;
    }
    setError(null);
    setBusy(true);
    try {
      const seller = await signIn(login, password);
      if (seller) {
        onSignedIn(seller);
        return;
      }
      setError("Login yoki parol noto'g'ri.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Serverga ulanib bo'lmadi.");
    }
    setBusy(false);
  }

  return (
    <main className="flex flex-1 items-center justify-center p-4">
      <div className="w-full max-w-sm">
        <div className="mb-6 flex items-center justify-center gap-2.5">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-brand-light to-brand-dark shadow-sm shadow-brand/30">
            <Flame className="h-5 w-5 text-white" strokeWidth={2.4} />
          </div>
          <div>
            <p className="text-sm font-bold leading-tight text-foreground">Gaz &amp; Energiya</p>
            <p className="text-xs leading-tight text-foreground/50">Sotuvchi panel</p>
          </div>
        </div>

        <form
          onSubmit={submit}
          className="rounded-2xl border border-border bg-surface p-6 shadow-sm shadow-black/[0.03]"
        >
          <h1 className="text-xl font-bold text-foreground">Kabinetga kirish</h1>
          <p className="mt-1 text-sm text-foreground/50">
            Login va parolni administrator beradi.
          </p>

          <div className="mt-5 space-y-3">
            <label className="block space-y-1.5">
              <span className="text-xs font-semibold text-foreground/60">Login</span>
              <div className={fieldClass}>
                <UserRound className="h-4 w-4 shrink-0 text-foreground/35" />
                <input
                  autoFocus
                  value={login}
                  onChange={(e) => setLogin(e.target.value)}
                  autoComplete="username"
                  autoCapitalize="none"
                  spellCheck={false}
                  placeholder="masalan: shringaz"
                  className="w-full bg-transparent py-2.5 text-sm text-foreground outline-none placeholder:text-foreground/35"
                />
              </div>
            </label>
            <label className="block space-y-1.5">
              <span className="text-xs font-semibold text-foreground/60">Parol</span>
              <div className={fieldClass}>
                <LockKeyhole className="h-4 w-4 shrink-0 text-foreground/35" />
                <input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  className="w-full bg-transparent py-2.5 text-sm text-foreground outline-none"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  title={showPassword ? "Yashirish" : "Ko'rsatish"}
                  className="text-foreground/40 hover:text-foreground/70"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </label>
          </div>

          {error && (
            <p className="mt-4 rounded-xl border border-danger/30 bg-danger-tint px-3 py-2 text-sm text-danger">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={busy}
            className="mt-5 flex w-full items-center justify-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark disabled:opacity-60"
          >
            {busy && <Loader2 className="h-4 w-4 animate-spin" />}
            Kirish
          </button>
        </form>
      </div>
    </main>
  );
}
