"use client";

import { useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Save, Database } from "lucide-react";

export default function SettingsPage() {
  const [saved, setSaved] = useState(false);

  return (
    <>
      <Topbar title="Sozlamalar" subtitle="Platforma bo'yicha umumiy sozlamalar" />
      <main className="flex-1 space-y-6 overflow-y-auto p-6">
        <div className="max-w-2xl rounded-2xl border border-border bg-surface p-6 shadow-sm shadow-black/[0.02]">
          <h2 className="text-sm font-bold text-foreground">Platforma</h2>
          <div className="mt-4 space-y-4">
            <Field label="Platforma nomi" defaultValue="Gaz & Energiya" />
            <Field label="Qo'llab-quvvatlash telefoni" defaultValue="+998 74 225 00 00" />
            <Field label="Standart yetkazish narxi (so'm)" defaultValue="15000" />
            <Field label="Platforma komissiyasi (%)" defaultValue="5" />
          </div>
          <button
            onClick={() => {
              setSaved(true);
              setTimeout(() => setSaved(false), 2000);
            }}
            className="mt-6 flex items-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-brand/30 hover:bg-brand-dark"
          >
            <Save className="h-4 w-4" /> {saved ? "Saqlandi ✓" : "Saqlash"}
          </button>
        </div>

        <div className="max-w-2xl rounded-2xl border border-dashed border-border bg-surface-muted p-6">
          <div className="flex items-center gap-2 text-sm font-bold text-foreground">
            <Database className="h-4 w-4 text-brand" /> Ma&apos;lumotlar bazasi ulanishi
          </div>
          <p className="mt-2 text-xs leading-relaxed text-foreground/55">
            Bu panel hozircha namunaviy (mock) ma&apos;lumotlar bilan ishlaydi. Supabase
            bazasiga ulanganda (companies/products/sellers/orders jadvallariga yozish
            huquqi bilan) barcha amallar — tasdiqlash, rad etish, sozlamalarni saqlash —
            haqiqiy ma&apos;lumotlarni o&apos;zgartira boshlaydi.
          </p>
        </div>
      </main>
    </>
  );
}

function Field({ label, defaultValue }: { label: string; defaultValue: string }) {
  return (
    <label className="block">
      <span className="text-xs font-medium text-foreground/55">{label}</span>
      <input
        defaultValue={defaultValue}
        className="mt-1.5 w-full rounded-xl border border-border bg-surface-muted px-3.5 py-2.5 text-sm outline-none focus:border-brand-light focus:bg-surface"
      />
    </label>
  );
}
