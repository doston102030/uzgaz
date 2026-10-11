import { Store, TrendingUp, Plus, ClipboardList } from "lucide-react";
import Link from "next/link";

/**
 * Seller dashboard's welcome banner — deliberately a warm amber/flame
 * gradient (not the admin panel's blue) so the two panels read as
 * distinct tools for distinct roles, even though they share one token
 * system (see `globals.css`).
 */
export function SellerHeroBanner({
  companyName,
  newOrders,
  pendingProducts,
}: {
  companyName: string;
  newOrders: number;
  pendingProducts: number;
}) {
  const statusLine =
    newOrders === 0 && pendingProducts === 0
      ? "Hozircha yangi buyurtma yo'q — hammasi nazoratda."
      : [
          newOrders > 0 ? `${newOrders} ta yangi buyurtma` : null,
          pendingProducts > 0 ? `${pendingProducts} ta mahsulot moderatsiyada` : null,
        ]
          .filter(Boolean)
          .join(" va ") + " kutmoqda.";

  return (
    <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-energy-amber via-energy-flame to-orange-700 p-6 shadow-sm shadow-energy-flame/25 sm:p-8">
      {/* Decorative watermark icons — purely visual, hidden from assistive tech */}
      <Store
        aria-hidden
        className="pointer-events-none absolute -right-6 -top-8 h-40 w-40 text-white/10"
        strokeWidth={1.2}
      />
      <TrendingUp
        aria-hidden
        className="pointer-events-none absolute right-24 bottom-[-1.5rem] h-24 w-24 text-white/10"
        strokeWidth={1.2}
      />

      <div className="relative flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
        <div className="max-w-lg">
          <span className="inline-flex items-center gap-1.5 rounded-full bg-white/15 px-3 py-1 text-xs font-semibold text-white/90 backdrop-blur">
            <Store className="h-3.5 w-3.5" strokeWidth={2.4} />
            Sotuvchi kabineti
          </span>
          <h2 className="mt-3 text-2xl font-bold tracking-tight text-white sm:text-[1.75rem]">
            Xush kelibsiz, {companyName}
          </h2>
          <p className="mt-1.5 text-sm text-white/75">{statusLine}</p>
        </div>

        <div className="flex shrink-0 flex-wrap gap-2">
          <Link
            href="/products?new=1"
            className="inline-flex items-center gap-1.5 rounded-xl bg-white px-4 py-2.5 text-sm font-semibold text-orange-800 shadow-sm transition-transform hover:scale-[1.02]"
          >
            <Plus className="h-4 w-4" strokeWidth={2.6} />
            Mahsulot qo&apos;shish
          </Link>
          <Link
            href="/orders"
            className="inline-flex items-center gap-1.5 rounded-xl border border-white/30 bg-white/10 px-4 py-2.5 text-sm font-semibold text-white backdrop-blur transition-colors hover:bg-white/20"
          >
            <ClipboardList className="h-4 w-4" strokeWidth={2.4} />
            Buyurtmalar
          </Link>
        </div>
      </div>
    </div>
  );
}
