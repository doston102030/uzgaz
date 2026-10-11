"use client";

import { FormEvent, useState } from "react";
import { Check, Copy, Dices, Eye, EyeOff, KeyRound, Loader2 } from "lucide-react";
import { Modal, ModalButton } from "@/components/ui/Modal";
import { setSellerLogin } from "@/lib/db";
import { Seller } from "@/lib/types";

const inputClass =
  "w-full rounded-xl border border-border bg-surface-muted px-3 py-2.5 text-sm text-foreground outline-none placeholder:text-foreground/35 focus:border-brand-light focus:bg-surface";

const LOGIN_PATTERN = /^[a-z0-9._-]{3,32}$/;

/** "ShrinGaz" → "shringaz", "UzGaz Servis" → "uzgaz.servis"; Cyrillic etc. drops out. */
function suggestLogin(companyName: string): string {
  const slug = companyName
    .toLowerCase()
    .replace(/['‘’ʻʼ`]/g, "")
    .replace(/\s+/g, ".")
    .replace(/[^a-z0-9._-]/g, "")
    .replace(/\.{2,}/g, ".")
    .replace(/^[.]+|[.]+$/g, "")
    .slice(0, 32);
  return slug.length >= 3 ? slug : "";
}

/** 8 characters without look-alikes (0/o, 1/l/i) — easy to read out over the phone. */
function generatePassword(): string {
  const alphabet = "abcdefghjkmnpqrstuvwxyz23456789";
  const bytes = new Uint8Array(8);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => alphabet[b % alphabet.length]).join("");
}

/** Admin gives a seller a login + password for the Seller panel, or replaces them. */
export function SellerLoginDialog({
  seller,
  currentLogin,
  onClose,
  onSaved,
}: {
  seller: Seller;
  currentLogin?: string;
  onClose: () => void;
  onSaved: (sellerId: string, login: string) => void;
}) {
  // Fixed at open: onSaved updates the parent's map, which must not flip the title mid-dialog.
  const [hadLogin] = useState(Boolean(currentLogin));
  const [login, setLogin] = useState(currentLogin ?? suggestLogin(seller.companyName));
  const [password, setPassword] = useState(generatePassword);
  const [showPassword, setShowPassword] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState<{ login: string; password: string } | null>(null);
  const [copied, setCopied] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    const cleanLogin = login.trim().toLowerCase();
    if (!LOGIN_PATTERN.test(cleanLogin)) {
      setError("Login 3–32 belgi bo'lsin: lotin harflari, raqam, nuqta, chiziqcha.");
      return;
    }
    if (password.length < 6) {
      setError("Parol kamida 6 belgidan iborat bo'lsin.");
      return;
    }
    setError(null);
    setSaving(true);
    try {
      await setSellerLogin(seller.id, cleanLogin, password);
      onSaved(seller.id, cleanLogin);
      setSaved({ login: cleanLogin, password });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Saqlab bo'lmadi.");
    } finally {
      setSaving(false);
    }
  }

  async function copy() {
    if (!saved) return;
    const text = `Gaz & Energiya — sotuvchi paneli\nLogin: ${saved.login}\nParol: ${saved.password}`;
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      setError("Nusxa olib bo'lmadi — login va parolni qo'lda yozib oling.");
    }
  }

  return (
    <Modal
      size="sm"
      busy={saving}
      onClose={onClose}
      onSubmit={submit}
      title={
        <span className="flex items-center gap-2.5">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-brand-tint text-brand">
            <KeyRound className="h-4.5 w-4.5" />
          </span>
          {hadLogin ? "Login va parolni yangilash" : "Login va parol berish"}
        </span>
      }
      subtitle={seller.companyName}
      footer={
        saved ? (
          <>
            <ModalButton variant="ghost" onClick={onClose}>
              Yopish
            </ModalButton>
            <ModalButton onClick={copy}>
              {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
              {copied ? "Nusxa olindi" : "Nusxa olish"}
            </ModalButton>
          </>
        ) : (
          <>
            <ModalButton variant="ghost" onClick={onClose} disabled={saving}>
              Bekor qilish
            </ModalButton>
            <ModalButton type="submit" disabled={saving}>
              {saving && <Loader2 className="h-4 w-4 animate-spin" />}
              Saqlash
            </ModalButton>
          </>
        )
      }
    >
      {saved ? (
        <div className="space-y-4">
          <div className="flex items-center gap-2 text-sm font-semibold text-success">
            <Check className="h-4 w-4" /> Saqlandi — sotuvchiga yuboring
          </div>
          <dl className="divide-y divide-border rounded-xl border border-border bg-surface-muted text-sm">
            <div className="flex items-center justify-between px-4 py-3">
              <dt className="text-foreground/50">Login</dt>
              <dd className="font-mono font-semibold text-foreground">{saved.login}</dd>
            </div>
            <div className="flex items-center justify-between px-4 py-3">
              <dt className="text-foreground/50">Parol</dt>
              <dd className="font-mono font-semibold text-foreground">{saved.password}</dd>
            </div>
          </dl>
          <p className="text-xs text-foreground/50">
            Parol keyin hech qayerda ko&apos;rinmaydi — hozir nusxa oling. Unutilsa, yangisini
            berasiz.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          <label className="block space-y-1.5">
            <span className="text-xs font-semibold text-foreground/60">Login</span>
            <input
              autoFocus
              value={login}
              onChange={(e) => setLogin(e.target.value.toLowerCase().replace(/\s/g, ""))}
              placeholder="masalan: shringaz"
              autoComplete="off"
              spellCheck={false}
              className={`${inputClass} font-mono`}
            />
          </label>
          <label className="block space-y-1.5">
            <span className="text-xs font-semibold text-foreground/60">
              {hadLogin ? "Yangi parol" : "Parol"}
            </span>
            <div className="flex gap-2">
              <div className="flex flex-1 items-center rounded-xl border border-border bg-surface-muted focus-within:border-brand-light focus-within:bg-surface">
                <input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="new-password"
                  spellCheck={false}
                  className="w-full bg-transparent px-3 py-2.5 font-mono text-sm text-foreground outline-none"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  title={showPassword ? "Yashirish" : "Ko'rsatish"}
                  className="px-3 text-foreground/40 hover:text-foreground/70"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              <button
                type="button"
                onClick={() => {
                  setPassword(generatePassword());
                  setShowPassword(true);
                }}
                title="Yangi parol yaratish"
                className="flex h-[42px] w-[42px] shrink-0 items-center justify-center rounded-xl border border-border bg-surface text-foreground/60 hover:bg-surface-muted"
              >
                <Dices className="h-4 w-4" />
              </button>
            </div>
          </label>
          <p className="text-xs text-foreground/50">
            Sotuvchi shu login va parol bilan sotuvchi paneliga kiradi.
            {hadLogin && " Yangi parol saqlansa, eski parol bilan kirganlar chiqib ketadi."}
          </p>
        </div>
      )}

      {error && (
        <p className="mt-4 rounded-xl border border-danger/30 bg-danger-tint px-3 py-2 text-sm text-danger">
          {error}
        </p>
      )}
    </Modal>
  );
}
