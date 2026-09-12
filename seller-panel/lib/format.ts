const MONTHS_UZ = [
  "yanvar", "fevral", "mart", "aprel", "may", "iyun",
  "iyul", "avgust", "sentabr", "oktabr", "noyabr", "dekabr",
];

function pad(n: number): string {
  return n < 10 ? `0${n}` : String(n);
}

/**
 * Manual formatting throughout this file — deliberately avoids
 * `toLocaleString`/`Intl`: Next.js SSRs these components, and Node's ICU
 * data for "uz-UZ" doesn't always match the browser's, which produces a
 * server/client text mismatch (React hydration error #418). Plain
 * getters + a fixed month array are locale-independent, so server and
 * client always render the same string.
 */
export function formatCurrency(value: number): string {
  return `${groupThousands(value)} so'm`;
}

export function formatCurrencyShort(value: number): string {
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)} mln so'm`;
  if (value >= 1_000) return `${Math.round(value / 1000)} ming so'm`;
  return `${value} so'm`;
}

function groupThousands(value: number): string {
  return Math.round(value)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

export function formatDate(iso: string): string {
  const d = new Date(iso);
  return `${d.getDate()} ${MONTHS_UZ[d.getMonth()]} ${d.getFullYear()}`;
}

export function formatShortDate(iso: string): string {
  const d = new Date(iso);
  return `${pad(d.getDate())}.${pad(d.getMonth() + 1)}`;
}

export function formatDateTime(iso: string): string {
  const d = new Date(iso);
  return `${pad(d.getDate())}.${pad(d.getMonth() + 1)}.${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function relativeTime(iso: string, now = new Date("2025-09-12T16:00:00")): string {
  const diffMs = now.getTime() - new Date(iso).getTime();
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 1) return "hozirgina";
  if (minutes < 60) return `${minutes} daqiqa oldin`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} soat oldin`;
  const days = Math.floor(hours / 24);
  return `${days} kun oldin`;
}
