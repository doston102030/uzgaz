"use client";

import { useEffect, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge, BadgeTone } from "@/components/Badge";
import { errorText, useToast } from "@/components/ui/feedback";
import { fetchSellerProfile, saveSellerProfile, SellerProfileData } from "@/lib/db";
import { CATEGORY_LABEL, ServiceCategory } from "@/lib/types";
import { AlertTriangle, Save, Star } from "lucide-react";

const STATUS: Record<SellerProfileData["status"], { label: string; tone: BadgeTone }> = {
  pending: { label: "Tasdiq kutilmoqda", tone: "warning" },
  approved: { label: "Tasdiqlangan", tone: "success" },
  rejected: { label: "Rad etilgan", tone: "danger" },
  suspended: { label: "To'xtatilgan", tone: "danger" },
};

const INPUT =
  "w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface disabled:opacity-60";

function initials(name: string) {
  const letters = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0]);
  return letters.join("").toUpperCase() || "—";
}

export default function ProfilePage() {
  const toast = useToast();
  const [profile, setProfile] = useState<SellerProfileData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let cancelled = false;
    fetchSellerProfile()
      .then((p) => {
        if (!cancelled) setProfile(p);
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err.message : "Profil yuklanmadi.");
      });
    return () => {
      cancelled = true;
    };
  }, []);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!profile) return;
    if (!profile.companyName.trim() || !profile.ownerName.trim()) {
      toast.error("Kompaniya nomi va egasi bo'sh bo'lmasin.");
      return;
    }
    setSaving(true);
    try {
      await saveSellerProfile({
        ...profile,
        companyName: profile.companyName.trim(),
        ownerName: profile.ownerName.trim(),
      });
      toast.success("Profil saqlandi — o'zgarishlar ilovada ham ko'rinadi.");
    } catch (err) {
      toast.error(`Saqlanmadi: ${errorText(err)}`);
    } finally {
      setSaving(false);
    }
  }

  const set = (patch: Partial<SellerProfileData>) =>
    setProfile((p) => (p ? { ...p, ...patch } : p));

  return (
    <>
      <Topbar title="Profil" subtitle="Kompaniya ma'lumotlari va sozlamalar" />
      <main className="flex-1 space-y-6 overflow-y-auto p-4 sm:p-6">
        {error && (
          <p className="flex max-w-2xl items-start gap-2 rounded-xl border border-warning/30 bg-warning-tint px-4 py-3 text-sm text-foreground/75">
            <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-warning" />
            {error}
          </p>
        )}

        {!profile ? (
          !error && <p className="text-sm text-foreground/45">Yuklanmoqda…</p>
        ) : (
          <>
            <div className="flex flex-wrap items-center gap-4 rounded-2xl border border-border bg-surface p-6 shadow-sm shadow-black/[0.02]">
              <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-brand-light to-brand text-xl font-bold text-white">
                {initials(profile.companyName)}
              </div>
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <p className="text-lg font-bold text-foreground">{profile.companyName}</p>
                  <Badge label={STATUS[profile.status].label} tone={STATUS[profile.status].tone} />
                </div>
                <p className="flex items-center gap-1 text-sm text-foreground/50">
                  <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                  {profile.reviewCount > 0
                    ? `${profile.rating.toFixed(1)} · ${profile.reviewCount} sharh`
                    : "Hali sharh yo'q"}{" "}
                  · {CATEGORY_LABEL[profile.category as ServiceCategory] ?? profile.category} ·{" "}
                  {profile.district}
                </p>
              </div>
            </div>

            <form
              onSubmit={onSubmit}
              className="max-w-2xl space-y-4 rounded-2xl border border-border bg-surface p-6 shadow-sm shadow-black/[0.02]"
            >
              <h2 className="text-sm font-bold text-foreground">Kompaniya ma&apos;lumotlari</h2>
              <Field label="Kompaniya nomi">
                <input
                  value={profile.companyName}
                  onChange={(e) => set({ companyName: e.target.value })}
                  className={INPUT}
                />
              </Field>
              <Field label="Egasi">
                <input
                  value={profile.ownerName}
                  onChange={(e) => set({ ownerName: e.target.value })}
                  className={INPUT}
                />
              </Field>
              <Field label="Manzil">
                <input
                  value={profile.address}
                  onChange={(e) => set({ address: e.target.value })}
                  className={INPUT}
                />
              </Field>
              <Field label="Telefon">
                <input
                  value={profile.phone}
                  onChange={(e) => set({ phone: e.target.value })}
                  className={INPUT}
                />
              </Field>

              <h2 className="pt-2 text-sm font-bold text-foreground">Xaridorlar ko&apos;radigan shartlar</h2>
              {!profile.hasStorefront && (
                <p className="text-xs text-foreground/50">
                  Bu shartlar ilovada ko&apos;rinishi uchun administrator
                  supabase/marketplace_setup.sql faylini ishga tushirishi kerak.
                </p>
              )}
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                <Field label="Ish vaqti">
                  <input
                    value={profile.workingHours}
                    onChange={(e) => set({ workingHours: e.target.value })}
                    placeholder="09:00 - 21:00"
                    disabled={!profile.hasStorefront}
                    className={INPUT}
                  />
                </Field>
                <Field label="Yetkazish narxi (so'm)">
                  <input
                    type="number"
                    min={0}
                    step={1000}
                    value={profile.deliveryFee}
                    onChange={(e) => set({ deliveryFee: Math.max(0, Number(e.target.value) || 0) })}
                    disabled={!profile.hasStorefront}
                    className={INPUT}
                  />
                </Field>
                <Field label="Yetkazish muddati (daqiqa)">
                  <input
                    type="number"
                    min={5}
                    step={5}
                    value={profile.etaMinutes}
                    onChange={(e) => set({ etaMinutes: Math.max(0, Number(e.target.value) || 0) })}
                    disabled={!profile.hasStorefront}
                    className={INPUT}
                  />
                </Field>
              </div>
              <p className="text-xs text-foreground/45">
                0 so&apos;m yozsangiz, ilovada &quot;Bepul yetkazish&quot; deb ko&apos;rinadi.
              </p>

              <button
                type="submit"
                disabled={saving}
                className="flex items-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark disabled:opacity-60"
              >
                <Save className="h-4 w-4" /> {saving ? "Saqlanmoqda…" : "Saqlash"}
              </button>
            </form>
          </>
        )}
      </main>
    </>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="text-xs font-medium text-foreground/55">{label}</span>
      <div className="mt-1.5">{children}</div>
    </label>
  );
}
