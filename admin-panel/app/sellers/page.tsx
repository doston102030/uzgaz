"use client";

import { useMemo, useState } from "react";
import { Topbar } from "@/components/Topbar";
import { Badge, BadgeTone, CategoryTag } from "@/components/Badge";
import { sellers as seedSellers } from "@/lib/mock-data";
import { Seller, SellerStatus, CATEGORY_COLOR, CATEGORY_LABEL } from "@/lib/types";
import { formatDate } from "@/lib/format";
import { Check, X, Ban, RotateCcw, Phone, MapPin } from "lucide-react";
import clsx from "clsx";

const STATUS_LABEL: Record<SellerStatus, string> = {
  pending: "Yangi ariza",
  approved: "Tasdiqlangan",
  rejected: "Rad etilgan",
  suspended: "To'xtatilgan",
};

const STATUS_TONE: Record<SellerStatus, BadgeTone> = {
  pending: "warning",
  approved: "success",
  rejected: "danger",
  suspended: "neutral",
};

const TABS: { key: SellerStatus | "all"; label: string }[] = [
  { key: "all", label: "Barchasi" },
  { key: "pending", label: "Yangi arizalar" },
  { key: "approved", label: "Tasdiqlangan" },
  { key: "suspended", label: "To'xtatilgan" },
  { key: "rejected", label: "Rad etilgan" },
];

export default function SellersPage() {
  const [sellers, setSellers] = useState<Seller[]>(seedSellers);
  const [tab, setTab] = useState<SellerStatus | "all">("all");

  const list = tab === "all" ? sellers : sellers.filter((s) => s.status === tab);
  const counts = useMemo(() => {
    const c: Record<string, number> = { all: sellers.length };
    for (const s of sellers) c[s.status] = (c[s.status] ?? 0) + 1;
    return c;
  }, [sellers]);

  function setStatus(id: string, status: SellerStatus) {
    setSellers((prev) => prev.map((s) => (s.id === id ? { ...s, status } : s)));
  }

  return (
    <>
      <Topbar
        title="Sotuvchilar"
        subtitle={`${sellers.length} ta ro'yxatdan o'tgan sotuvchi · ${counts.pending ?? 0} ta yangi ariza`}
      />
      <main className="flex-1 space-y-4 overflow-y-auto p-6">
        <div className="flex flex-wrap gap-2">
          {TABS.map((t) => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={clsx(
                "flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition-colors",
                tab === t.key
                  ? "bg-brand text-white shadow-sm shadow-brand/30"
                  : "bg-surface text-foreground/60 hover:bg-surface-muted",
              )}
            >
              {t.label}
              <span
                className={clsx(
                  "rounded-full px-1.5 py-0.5 text-xs",
                  tab === t.key ? "bg-white/20" : "bg-surface-muted",
                )}
              >
                {counts[t.key] ?? 0}
              </span>
            </button>
          ))}
        </div>

        <div className="overflow-hidden rounded-2xl border border-border bg-surface shadow-sm shadow-black/[0.02]">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[820px] text-left text-sm">
              <thead>
                <tr className="border-b border-border text-xs uppercase tracking-wide text-foreground/40">
                  <th className="px-5 py-3 font-medium">Kompaniya</th>
                  <th className="px-5 py-3 font-medium">Egasi</th>
                  <th className="px-5 py-3 font-medium">Kategoriya</th>
                  <th className="px-5 py-3 font-medium">Hudud / aloqa</th>
                  <th className="px-5 py-3 font-medium">Ro&apos;yxatdan o&apos;tgan</th>
                  <th className="px-5 py-3 font-medium">Holati</th>
                  <th className="px-5 py-3 font-medium">Amallar</th>
                </tr>
              </thead>
              <tbody>
                {list.map((s) => (
                  <tr key={s.id} className="border-b border-border last:border-0">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-brand-light to-brand text-xs font-bold text-white">
                          {s.companyName.slice(0, 2).toUpperCase()}
                        </div>
                        <span className="font-semibold text-foreground">{s.companyName}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3 text-foreground/70">{s.ownerName}</td>
                    <td className="px-5 py-3">
                      <CategoryTag label={CATEGORY_LABEL[s.category]} color={CATEGORY_COLOR[s.category]} />
                    </td>
                    <td className="px-5 py-3 text-xs text-foreground/55">
                      <div className="flex items-center gap-1.5">
                        <MapPin className="h-3 w-3" /> {s.district}
                      </div>
                      <div className="mt-1 flex items-center gap-1.5">
                        <Phone className="h-3 w-3" /> {s.phone}
                      </div>
                    </td>
                    <td className="px-5 py-3 text-foreground/55">{formatDate(s.createdAt)}</td>
                    <td className="px-5 py-3">
                      <Badge label={STATUS_LABEL[s.status]} tone={STATUS_TONE[s.status]} />
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex gap-1.5">
                        {s.status === "pending" && (
                          <>
                            <button
                              onClick={() => setStatus(s.id, "approved")}
                              title="Tasdiqlash"
                              className="flex h-8 w-8 items-center justify-center rounded-lg bg-success-tint text-success hover:brightness-95"
                            >
                              <Check className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => setStatus(s.id, "rejected")}
                              title="Rad etish"
                              className="flex h-8 w-8 items-center justify-center rounded-lg bg-danger-tint text-danger hover:brightness-95"
                            >
                              <X className="h-4 w-4" />
                            </button>
                          </>
                        )}
                        {s.status === "approved" && (
                          <button
                            onClick={() => setStatus(s.id, "suspended")}
                            title="To'xtatish"
                            className="flex h-8 w-8 items-center justify-center rounded-lg bg-surface-muted text-foreground/60 hover:bg-warning-tint hover:text-warning"
                          >
                            <Ban className="h-4 w-4" />
                          </button>
                        )}
                        {(s.status === "suspended" || s.status === "rejected") && (
                          <button
                            onClick={() => setStatus(s.id, "approved")}
                            title="Qayta tiklash"
                            className="flex h-8 w-8 items-center justify-center rounded-lg bg-success-tint text-success hover:brightness-95"
                          >
                            <RotateCcw className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {list.length === 0 && (
            <p className="p-8 text-center text-sm text-foreground/40">
              Bu bo&apos;limda hozircha sotuvchi yo&apos;q.
            </p>
          )}
        </div>
      </main>
    </>
  );
}
