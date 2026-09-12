"use client";

import { useState } from "react";
import { Topbar } from "@/components/Topbar";
import { profile as seedProfile } from "@/lib/mock-data";
import { CATEGORY_LABEL } from "@/lib/types";
import { Save, Star, ShieldCheck } from "lucide-react";

export default function ProfilePage() {
  const [profile, setProfile] = useState(seedProfile);
  const [saved, setSaved] = useState(false);

  return (
    <>
      <Topbar title="Profil" subtitle="Kompaniya ma'lumotlari va sozlamalar" />
      <main className="flex-1 space-y-6 overflow-y-auto p-6">
        <div className="flex flex-wrap items-center gap-4 rounded-2xl border border-border bg-surface p-6 shadow-sm shadow-black/[0.02]">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-brand-light to-brand text-xl font-bold text-white">
            AG
          </div>
          <div>
            <div className="flex items-center gap-2">
              <p className="text-lg font-bold text-foreground">{profile.companyName}</p>
              <ShieldCheck className="h-4 w-4 text-success" />
            </div>
            <p className="flex items-center gap-1 text-sm text-foreground/50">
              <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
              {profile.rating} · {profile.reviewCount} sharh · {CATEGORY_LABEL[profile.category]}
            </p>
          </div>
        </div>

        <form
          onSubmit={(e) => {
            e.preventDefault();
            setSaved(true);
            setTimeout(() => setSaved(false), 2000);
          }}
          className="max-w-2xl space-y-4 rounded-2xl border border-border bg-surface p-6 shadow-sm shadow-black/[0.02]"
        >
          <h2 className="text-sm font-bold text-foreground">Kompaniya ma&apos;lumotlari</h2>
          <Field label="Kompaniya nomi">
            <input
              value={profile.companyName}
              onChange={(e) => setProfile({ ...profile, companyName: e.target.value })}
              className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
            />
          </Field>
          <Field label="Egasi">
            <input
              value={profile.ownerName}
              onChange={(e) => setProfile({ ...profile, ownerName: e.target.value })}
              className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
            />
          </Field>
          <Field label="Manzil">
            <input
              value={profile.address}
              onChange={(e) => setProfile({ ...profile, address: e.target.value })}
              className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
            />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Telefon">
              <input
                value={profile.phone}
                onChange={(e) => setProfile({ ...profile, phone: e.target.value })}
                className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
              />
            </Field>
            <Field label="Ish vaqti">
              <input
                value={profile.workingHours}
                onChange={(e) => setProfile({ ...profile, workingHours: e.target.value })}
                className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
              />
            </Field>
          </div>
          <Field label="Yetkazish narxi (so'm)">
            <input
              type="number"
              value={profile.deliveryFee}
              onChange={(e) => setProfile({ ...profile, deliveryFee: Number(e.target.value) })}
              className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
            />
          </Field>
          <Field label="Tavsif">
            <textarea
              value={profile.description}
              onChange={(e) => setProfile({ ...profile, description: e.target.value })}
              rows={3}
              className="w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
            />
          </Field>
          <button
            type="submit"
            className="flex items-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
          >
            <Save className="h-4 w-4" /> {saved ? "Saqlandi ✓" : "Saqlash"}
          </button>
        </form>
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
