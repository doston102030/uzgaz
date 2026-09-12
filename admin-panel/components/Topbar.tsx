import { Bell, Search } from "lucide-react";

export function Topbar({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <header className="flex flex-wrap items-center justify-between gap-4 border-b border-border bg-surface/80 px-6 py-5 backdrop-blur">
      <div>
        <h1 className="text-xl font-bold text-foreground">{title}</h1>
        {subtitle && <p className="mt-0.5 text-sm text-foreground/50">{subtitle}</p>}
      </div>
      <div className="flex items-center gap-3">
        <label className="relative hidden sm:block">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-foreground/35" />
          <input
            placeholder="Qidirish..."
            className="w-56 rounded-xl border border-border bg-surface-muted py-2 pl-9 pr-3 text-sm outline-none placeholder:text-foreground/35 focus:border-brand-light"
          />
        </label>
        <button
          type="button"
          className="relative flex h-10 w-10 items-center justify-center rounded-xl border border-border bg-surface text-foreground/60 hover:bg-surface-muted"
        >
          <Bell className="h-[18px] w-[18px]" />
          <span className="absolute right-2 top-2 h-1.5 w-1.5 rounded-full bg-danger" />
        </button>
        <div className="flex items-center gap-2.5 rounded-xl border border-border bg-surface py-1.5 pl-1.5 pr-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-brand-light to-brand text-xs font-bold text-white">
            AD
          </div>
          <div className="hidden leading-tight sm:block">
            <p className="text-sm font-semibold text-foreground">Administrator</p>
            <p className="text-xs text-foreground/45">admin@gazenergiya.uz</p>
          </div>
        </div>
      </div>
    </header>
  );
}
