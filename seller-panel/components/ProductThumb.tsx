"use client";

import { useState } from "react";
import clsx from "clsx";
import { CategoryIcon } from "@/components/CategoryIcon";
import { categoryColor, ProductCategory } from "@/lib/categories";

/**
 * Mahsulot rasmi — ilovadagidek to'liq (`contain`), kesilmaydi: uzun balon `cover`da
 * faqat o'rtasi qolardi. Rasm yo'q yoki ochilmasa — kategoriya belgisi uning rangida.
 */
export function ProductThumb({
  src,
  alt,
  categoryId,
  category,
  className,
  iconClassName = "h-10 w-10",
}: {
  src?: string;
  alt: string;
  categoryId: string;
  category?: ProductCategory;
  className?: string;
  iconClassName?: string;
}) {
  const [failed, setFailed] = useState<string | null>(null);
  const color = categoryColor(categoryId);
  if (src && failed !== src) {
    return (
      <div
        className={clsx("flex items-center justify-center overflow-hidden", className)}
        style={{
          background: `radial-gradient(75% 65% at 50% 45%, var(--surface), color-mix(in srgb, ${color} 7%, var(--surface)))`,
        }}
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={src}
          alt={alt}
          loading="lazy"
          onError={() => setFailed(src)}
          className="h-full w-full object-contain p-[6%]"
        />
      </div>
    );
  }
  return (
    <div
      aria-label={alt}
      role="img"
      className={clsx("flex items-center justify-center", className)}
      style={{
        background: `linear-gradient(135deg, color-mix(in srgb, ${color} 10%, var(--surface)), color-mix(in srgb, ${color} 22%, var(--surface)))`,
        color,
      }}
    >
      <CategoryIcon icon={category?.icon} className={iconClassName} strokeWidth={1.6} />
    </div>
  );
}
