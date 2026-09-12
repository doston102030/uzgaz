"use client";

import { useMemo, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge } from "@/components/Badge";
import { companies as seedCompanies } from "@/lib/mock-data";
import { Company } from "@/lib/types";
import { Building2, MapPin, Phone, Star } from "lucide-react";

export default function CompaniesPage() {
  const [companies, setCompanies] = useState<Company[]>(seedCompanies);
  const [query, setQuery] = useState("");

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return companies;
    return companies.filter(
      (c) => c.name.toLowerCase().includes(q) || c.district.toLowerCase().includes(q),
    );
  }, [companies, query]);

  function toggleAvailability(id: string) {
    setCompanies((prev) =>
      prev.map((c) => (c.id === id ? { ...c, isAvailable: !c.isAvailable } : c)),
    );
  }

  return (
    <>
      <Topbar
        title="Kompaniyalar"
        subtitle={`${companies.length} ta ro'yxatdan o'tgan kompaniya · Andijon viloyati`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-6">
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Kompaniya yoki tuman bo'yicha qidirish..."
          className="w-full max-w-md rounded-xl border border-border bg-surface px-4 py-2.5 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light sm:w-80"
        />

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
          {filtered.map((c) => (
            <div
              key={c.id}
              className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-brand-light to-brand text-sm font-bold text-white">
                    {c.name.slice(0, 2).toUpperCase()}
                  </div>
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-foreground">{c.name}</p>
                    <div className="mt-0.5 flex items-center gap-1 text-xs text-foreground/45">
                      <Star className="h-3 w-3 fill-amber-400 text-amber-400" />
                      {c.rating || "—"} · {c.reviewCount} sharh
                    </div>
                  </div>
                </div>
                <Badge
                  label={c.isAvailable ? "Faol" : "Nofaol"}
                  tone={c.isAvailable ? "success" : "neutral"}
                  dot
                />
              </div>

              <div className="mt-4 space-y-2 text-xs text-foreground/60">
                <div className="flex items-center gap-2">
                  <MapPin className="h-3.5 w-3.5 shrink-0 text-foreground/35" />
                  <span className="truncate">{c.address}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="h-3.5 w-3.5 shrink-0 text-foreground/35" />
                  {c.phone}
                </div>
                <div className="flex items-center gap-2">
                  <Building2 className="h-3.5 w-3.5 shrink-0 text-foreground/35" />
                  Ish vaqti: {c.workingHours}
                </div>
              </div>

              {c.tags.length > 0 && (
                <div className="mt-3 flex flex-wrap gap-1.5">
                  {c.tags.map((t) => (
                    <Badge key={t} label={t} tone="brand" />
                  ))}
                </div>
              )}

              <button
                onClick={() => toggleAvailability(c.id)}
                className="mt-4 w-full rounded-xl border border-border py-2 text-xs font-semibold text-foreground/70 transition-colors hover:bg-surface-muted"
              >
                {c.isAvailable ? "Vaqtincha to'xtatish" : "Qayta faollashtirish"}
              </button>
            </div>
          ))}
        </div>
      </main>
    </>
  );
}
