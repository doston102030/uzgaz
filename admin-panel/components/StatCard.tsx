import { LucideIcon } from "lucide-react";
import clsx from "clsx";

export function StatCard({
  label,
  value,
  icon: Icon,
  trend,
  tone = "brand",
}: {
  label: string;
  value: string;
  icon: LucideIcon;
  trend?: { value: string; positive: boolean };
  tone?: "brand" | "success" | "warning" | "info";
}) {
  const toneClass: Record<string, string> = {
    brand: "from-brand-light to-brand text-white",
    success: "from-emerald-400 to-success text-white",
    warning: "from-amber-400 to-warning text-white",
    info: "from-sky-400 to-info text-white",
  };

  return (
    <div className="rounded-2xl border border-border bg-surface p-5 shadow-sm shadow-black/[0.02]">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium text-foreground/50">{label}</p>
          <p className="mt-2 text-2xl font-bold tracking-tight text-foreground">{value}</p>
        </div>
        <div
          className={clsx(
            "flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br shadow-sm",
            toneClass[tone],
          )}
        >
          <Icon className="h-5 w-5" strokeWidth={2.2} />
        </div>
      </div>
      {trend && (
        <p
          className={clsx(
            "mt-3 text-xs font-semibold",
            trend.positive ? "text-success" : "text-danger",
          )}
        >
          {trend.positive ? "▲" : "▼"} {trend.value}
        </p>
      )}
    </div>
  );
}
