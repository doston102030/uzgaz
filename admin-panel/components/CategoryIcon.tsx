import { createElement, CSSProperties } from "react";
import { Tag } from "lucide-react";
import { CATEGORY_ICONS } from "@/lib/categories";

/** Kategoriya belgisi nomi bo'yicha (`product_categories.icon`); noma'lumi — teg. */
export function CategoryIcon({
  icon,
  className,
  style,
  strokeWidth,
}: {
  icon?: string;
  className?: string;
  style?: CSSProperties;
  strokeWidth?: number;
}) {
  return createElement((icon && CATEGORY_ICONS[icon]) || Tag, { className, style, strokeWidth });
}
