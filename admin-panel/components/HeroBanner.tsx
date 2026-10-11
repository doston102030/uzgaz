import { Flame, Zap, Fuel, ArrowUpRight } from "lucide-react";
import Link from "next/link";

export function HeroBanner({
  companyCount,
  activeSellerCount,
}: {
  companyCount: number;
  activeSellerCount: number;
}) {
  return (
    <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand via-brand-dark to-brand-deep p-6 shadow-sm shadow-brand/20 sm:p-8">
      {/* Decorative watermark icons — purely visual, hidden from assistive tech */}
      <Flame
        aria-hidden
        className="pointer-events-none absolute -right-6 -top-8 h-40 w-40 text-white/10"
        strokeWidth={1.2}
      />
      <Zap
        aria-hidden
        className="pointer-events-none absolute right-24 bottom-[-1.5rem] h-24 w-24 text-white/10"
        strokeWidth={1.2}
      />
      <Fuel
        aria-hidden
        className="pointer-events-none absolute right-52 top-2 hidden h-16 w-16 text-white/10 sm:block"
        strokeWidth={1.2}
      />

      <div className="relative flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
        <div className="max-w-lg">
          <span className="inline-flex items-center gap-1.5 rounded-full bg-white/15 px-3 py-1 text-xs font-semibold text-white/90 backdrop-blur">
            <Flame className="h-3.5 w-3.5" strokeWidth={2.4} />
            Andijon viloyati
          </span>
          <h2 className="mt-3 text-2xl font-bold tracking-tight text-white sm:text-[1.75rem]">
            Xush kelibsiz, Administrator
          </h2>
          <p className="mt-1.5 text-sm text-white/70">
            {companyCount} ta kompaniya va {activeSellerCount} ta faol sotuvchi tarmog&apos;i
            bugun ham ishlamoqda — buyurtmalar va moderatsiyani shu yerdan boshqaring.
          </p>
        </div>

        <div className="flex shrink-0 flex-wrap gap-2">
          <Link
            href="/sellers"
            className="inline-flex items-center gap-1.5 rounded-xl bg-white px-4 py-2.5 text-sm font-semibold text-brand-deep shadow-sm transition-transform hover:scale-[1.02]"
          >
            Sotuvchilarni ko&apos;rish
            <ArrowUpRight className="h-4 w-4" strokeWidth={2.4} />
          </Link>
          <Link
            href="/products"
            className="inline-flex items-center gap-1.5 rounded-xl border border-white/30 bg-white/10 px-4 py-2.5 text-sm font-semibold text-white backdrop-blur transition-colors hover:bg-white/20"
          >
            Moderatsiya
          </Link>
        </div>
      </div>
    </div>
  );
}
