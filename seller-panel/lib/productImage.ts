/**
 * Mahsulot rasmini ilovaga tayyorlash — hammasi brauzerda, canvas orqali:
 *  - bo'sh chetlarni kesadi (mahsulot kadrni to'ldiradi, ilovada kichik ko'rinmaydi);
 *  - bir xil rangli yoki "shaxmat katak" fonni olib tashlaydi (internetdan olingan
 *    ko'p PNG'larda katak rasmga chizilgan — ilovada katak bo'lib ko'rinadi);
 *  - uzun tomonini OUT_MAX gacha kichraytirib, WEBP (bo'lmasa PNG/JPEG) qiladi.
 */

type RGB = [number, number, number];

export type BackgroundKind = "transparent" | "solid" | "checker" | "photo";

export interface LoadedImage {
  /** Ishchi nusxa — uzun tomoni WORK_MAX dan oshmaydi. */
  data: ImageData;
  naturalWidth: number;
  naturalHeight: number;
  bytes: number | null;
}

export interface ImageAnalysis {
  background: BackgroundKind;
  /** solid — 1 ta rang, checker — 2 ta (och va to'q katak). */
  colors: RGB[];
  /** "Fonni olib tashlash" oldindan yoqilsinmi. */
  suggestRemoval: boolean;
}

export interface FitOptions {
  trim: boolean;
  removeBackground: boolean;
}

export interface FittedImage {
  blob: Blob;
  width: number;
  height: number;
  transparent: boolean;
  /** Mahsulot qaysi chetda kesilganga o'xshaydi (rasm chetiga keng tegib turibdi). */
  cutEdges: ("top" | "bottom" | "left" | "right")[];
}

const WORK_MAX = 2000;
const OUT_MAX = 1600;
/** Kesilgandan keyin har tomonda qoldiriladigan havo (uzun tomonga nisbatan). */
const PAD_RATIO = 0.03;
const SOLID_TOL = 30;
const CHECKER_TOL = 12;
/** Ombor cheklovi (storage_setup.sql: 5 MB). */
const MAX_BYTES = 5 * 1024 * 1024;

// ── loading ────────────────────────────────────────────────────────

export async function loadImage(src: Blob | string): Promise<LoadedImage> {
  let blob: Blob;
  if (typeof src === "string") {
    const res = await fetch(src, { mode: "cors", cache: "no-store" });
    if (!res.ok) throw new Error(`Rasmni yuklab bo'lmadi (${res.status}).`);
    blob = await res.blob();
  } else {
    blob = src;
  }

  let bitmap: ImageBitmap;
  try {
    bitmap = await createImageBitmap(blob);
  } catch {
    throw new Error("Bu rasmni ochib bo'lmadi — JPG, PNG yoki WEBP tanlang.");
  }

  const scale = Math.min(1, WORK_MAX / Math.max(bitmap.width, bitmap.height));
  const w = Math.max(1, Math.round(bitmap.width * scale));
  const h = Math.max(1, Math.round(bitmap.height * scale));
  const ctx = context(canvas(w, h));
  ctx.imageSmoothingQuality = "high";
  ctx.drawImage(bitmap, 0, 0, w, h);
  const loaded = {
    data: ctx.getImageData(0, 0, w, h),
    naturalWidth: bitmap.width,
    naturalHeight: bitmap.height,
    bytes: blob.size || null,
  };
  bitmap.close();
  return loaded;
}

// ── analysis ───────────────────────────────────────────────────────

export function analyzeImage({ data }: LoadedImage): ImageAnalysis {
  const { width: w, height: h, data: px } = data;
  const border = borderIndexes(w, h);

  let clear = 0;
  for (const i of border) if (px[i * 4 + 3] < 200) clear++;
  if (clear / border.length > 0.25) {
    return { background: "transparent", colors: [], suggestRemoval: false };
  }

  const clusters = clusterColors(px, border);
  const total = border.length;
  const [first, second] = clusters;
  const share1 = first.count / total;

  // Shaxmat katak: ikkita och-kulrang rang navbatma-navbat, oraliq tuslar bilan.
  if (second && second.count / total >= 0.12 && share1 >= 0.12) {
    const a = first.color;
    const b = second.color;
    const lumGap = Math.abs(lum(a) - lum(b));
    if (chroma(a) <= 20 && chroma(b) <= 20 && Math.min(lum(a), lum(b)) >= 110 && lumGap >= 8) {
      const band = checkerBand(a, b);
      let inBand = 0;
      for (const i of border) if (band(px, i * 4)) inBand++;
      if (inBand / total >= 0.55) {
        return { background: "checker", colors: [a, b], suggestRemoval: true };
      }
    }
  }

  if (share1 >= 0.6) {
    const c = first.color;
    return {
      background: "solid",
      colors: [c],
      // Och, deyarli rangsiz fon (oq studiya) — xavfsiz; rangli fonni sotuvchi o'zi yoqadi.
      suggestRemoval: lum(c) >= 190 && chroma(c) <= 30,
    };
  }

  return { background: "photo", colors: [], suggestRemoval: false };
}

// ── fitting ────────────────────────────────────────────────────────

export async function fitProductImage(
  img: LoadedImage,
  analysis: ImageAnalysis,
  opts: FitOptions,
): Promise<FittedImage> {
  const { width: w, height: h } = img.data;
  const px = new Uint8ClampedArray(img.data.data);
  const kind = analysis.background;

  const removing = opts.removeBackground && (kind === "solid" || kind === "checker");
  if (removing) removeBackground(px, w, h, analysis);
  const transparent = removing || kind === "transparent";

  // "Mahsulot" pikseli: shaffof rasmda — ko'rinadigani, aks holda — fondan farqlisi.
  const isContent: (o: number) => boolean = transparent
    ? (o) => px[o + 3] > 16
    : kind === "solid"
      ? (o) => dist(px, o, analysis.colors[0]) > SOLID_TOL
      : kind === "checker"
        ? ((band) => (o: number) => !band(px, o))(checkerBand(analysis.colors[0], analysis.colors[1]))
        : () => true;

  const box = kind !== "photo" ? contentBounds(px, w, h, isContent) : null;
  const cutEdges = transparent && box ? cutSides(px, w, h, isContent) : [];

  const crop = opts.trim && box ? box : { x0: 0, y0: 0, x1: w, y1: h };
  const cw = crop.x1 - crop.x0;
  const ch = crop.y1 - crop.y0;
  const pad = opts.trim && box ? Math.round(Math.max(cw, ch) * PAD_RATIO) : 0;

  const source = canvas(w, h);
  context(source).putImageData(new ImageData(px, w, h), 0, 0);

  let limit = OUT_MAX;
  for (;;) {
    const scale = Math.min(1, limit / Math.max(cw + 2 * pad, ch + 2 * pad));
    const outW = Math.max(1, Math.round((cw + 2 * pad) * scale));
    const outH = Math.max(1, Math.round((ch + 2 * pad) * scale));
    const out = canvas(outW, outH);
    const ctx = context(out);
    if (!transparent) {
      // Kesilgan chetlarga asl fon rangi — oq studiya fonida "ramka" qolmaydi.
      const bg = kind === "solid" ? analysis.colors[0] : ([255, 255, 255] as RGB);
      ctx.fillStyle = `rgb(${bg[0]} ${bg[1]} ${bg[2]})`;
      ctx.fillRect(0, 0, outW, outH);
    }
    ctx.imageSmoothingQuality = "high";
    ctx.drawImage(source, crop.x0, crop.y0, cw, ch, pad * scale, pad * scale, cw * scale, ch * scale);

    const blob = await encode(out, transparent);
    if (blob.size <= MAX_BYTES || limit <= 800) {
      return { blob, width: outW, height: outH, transparent, cutEdges };
    }
    limit = Math.round(limit * 0.75);
  }
}

// ── background removal ─────────────────────────────────────────────

function removeBackground(px: Uint8ClampedArray, w: number, h: number, a: ImageAnalysis) {
  const isBg: (o: number) => boolean =
    a.background === "checker"
      ? checkerPredicate(px, w, h, a.colors[0], a.colors[1])
      : (o) => dist(px, o, a.colors[0]) <= SOLID_TOL;
  const pred = (i: number) => isBg(i * 4) || px[i * 4 + 3] < 16;

  // 1) Chetdan boshlab fonga ulangan hamma piksel (flood fill).
  const bg = new Uint8Array(w * h);
  const queue = new Int32Array(w * h);
  let head = 0;
  let tail = 0;
  for (const i of borderIndexes(w, h, 1)) {
    if (!bg[i] && pred(i)) {
      bg[i] = 1;
      queue[tail++] = i;
    }
  }
  const fill = (n: number) => {
    if (!bg[n] && pred(n)) {
      bg[n] = 1;
      queue[tail++] = n;
    }
  };
  while (head < tail) {
    const i = queue[head++];
    const x = i % w;
    if (x > 0) fill(i - 1);
    if (x < w - 1) fill(i + 1);
    if (i >= w) fill(i - w);
    if (i < w * (h - 1)) fill(i + w);
  }

  // 2) Yopiq "teshiklar" (masalan, ventil g'ildiragi orasidagi katak) — faqat katakda:
  //    ikkala katak rangi ham uchragan katta bo'lak — bu ham fon.
  if (a.background === "checker") {
    const [c1, c2] = a.colors;
    const seen = new Uint8Array(w * h);
    const minSize = Math.max(48, Math.round(w * h * 0.0004));
    for (let s = 0; s < w * h; s++) {
      if (bg[s] || seen[s] || !pred(s)) continue;
      head = 0;
      tail = 0;
      queue[tail++] = s;
      seen[s] = 1;
      let near1 = 0;
      let near2 = 0;
      const visit = (n: number) => {
        if (seen[n] || bg[n] || !pred(n)) return;
        seen[n] = 1;
        queue[tail++] = n;
      };
      while (head < tail) {
        const i = queue[head++];
        if (dist(px, i * 4, c1) <= CHECKER_TOL) near1++;
        else if (dist(px, i * 4, c2) <= CHECKER_TOL) near2++;
        const x = i % w;
        if (x > 0) visit(i - 1);
        if (x < w - 1) visit(i + 1);
        if (i >= w) visit(i - w);
        if (i < w * (h - 1)) visit(i + w);
      }
      if (tail >= minSize && near1 >= tail * 0.15 && near2 >= tail * 0.15) {
        for (let k = 0; k < tail; k++) bg[queue[k]] = 1;
      }
    }
  }

  // 3) Shaffof qilish + chegarani yumshatish (zinapoya qirralar qolmasin).
  for (let i = 0; i < w * h; i++) if (bg[i]) px[i * 4 + 3] = 0;
  const soft = new Uint8ClampedArray(w * h);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = y * w + x;
      if (bg[i]) continue;
      let bgCount = 0;
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const nx = x + dx;
          const ny = y + dy;
          if (nx >= 0 && ny >= 0 && nx < w && ny < h && bg[ny * w + nx]) bgCount++;
        }
      }
      soft[i] = bgCount === 0 ? 255 : Math.round(255 * Math.min(1, ((9 - bgCount) / 9) * 1.25));
    }
  }
  for (let i = 0; i < w * h; i++) {
    if (!bg[i] && soft[i] < 255) px[i * 4 + 3] = Math.min(px[i * 4 + 3], soft[i]);
  }
}

// ── checker grid ───────────────────────────────────────────────────

interface AxisGrid {
  /** Katak chegarasi koordinatasi (piksel chegarasida, kasr bo'lishi mumkin). */
  start: number;
  cell: number;
  /** `start` dan keyingi katakning rangi: 1 — a, 2 — b. */
  first: 1 | 2;
}

/**
 * Katak fon pikseli: to'rni chetdagi qator/ustundan topib, har piksel o'z katagining
 * kutilgan rangida ekanini tekshiradi. Shunda kumushrang ventil kabi kulrang
 * detallar "fon" deb yeyilmaydi. To'r topilmasa — oddiy yorug'lik oralig'i.
 */
function checkerPredicate(px: Uint8ClampedArray, w: number, h: number, a: RGB, b: RGB) {
  const band = checkerBand(a, b);
  const classify = (o: number): 0 | 1 | 2 =>
    dist(px, o, a) <= CHECKER_TOL ? 1 : dist(px, o, b) <= CHECKER_TOL ? 2 : 0;

  const best = (lines: number[], length: number, at: (line: number, k: number) => number) => {
    let found: { grid: AxisGrid; line: number; score: number } | null = null;
    for (const line of lines) {
      const r = axisGrid(length, (k) => classify(at(line, k) * 4));
      if (r && (!found || r.score > found.score)) found = { grid: r.grid, line, score: r.score };
    }
    return found;
  };
  const gx = best([0, 1, h - 2, h - 1], w, (y, x) => y * w + x);
  const gy = best([0, 1, w - 2, w - 1], h, (x, y) => y * w + x);
  if (!gx || !gy) return (o: number) => band(px, o);

  const X = gx.grid;
  const Y = gy.grid;
  // Qator `gx.line` qaysi y-katakda ekanini bilib, (0,0) katak rangini tiklaymiz.
  const rowCell = Math.floor((gx.line + 0.5 - Y.start) / Y.cell);
  const colors = [a, b];

  /** Piksel joyidagi kutilgan katak rangi (0 — a, 1 — b) va eng yaqin to'r chizig'igacha masofa. */
  const locate = (x: number, y: number) => {
    const fx = (x + 0.5 - X.start) / X.cell;
    const fy = (y + 0.5 - Y.start) / Y.cell;
    const kx = Math.floor(fx);
    const ky = Math.floor(fy);
    const line = Math.min(
      Math.min(fx - kx, 1 - (fx - kx)) * X.cell,
      Math.min(fy - ky, 1 - (fy - ky)) * Y.cell,
    );
    const flip = (kx + ky - rowCell) & 1;
    return { kx, ky, expected: X.first === 1 ? flip : 1 - flip, line };
  };

  // To'r chetdagi katakni to'g'ri bashorat qilmasa — unga ishonmaymiz.
  let checked = 0;
  let right = 0;
  for (const i of borderIndexes(w, h)) {
    const c = classify(i * 4);
    if (c === 0) continue;
    const x = i % w;
    const { expected, line } = locate(x, (i - x) / w);
    if (line < 1) continue;
    checked++;
    if (c - 1 === expected) right++;
  }
  if (checked < 20 || right / checked < 0.92) return (o: number) => band(px, o);

  // "Toza" katak — ichidagi deyarli hamma piksel kutilgan rangda. Kumushrang detal
  // ichida qo'shni katak hech qachon toza bo'lmaydi (u yerda ikkinchi rang yo'q),
  // shuning uchun fon faqat toza katakning yonida qidiriladi.
  const kx0 = locate(0, 0).kx - 1;
  const ky0 = locate(0, 0).ky - 1;
  const cols = locate(w - 1, 0).kx - kx0 + 2;
  const rows = locate(0, h - 1).ky - ky0 + 2;
  const total = new Uint32Array(cols * rows);
  const matched = new Uint32Array(cols * rows);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const { kx, ky, expected, line } = locate(x, y);
      if (line < 0.5) continue;
      const c = (ky - ky0) * cols + (kx - kx0);
      total[c]++;
      if (dist(px, (y * w + x) * 4, colors[expected]) <= CHECKER_TOL) matched[c]++;
    }
  }
  const pure = (kx: number, ky: number) => {
    const cx = kx - kx0;
    const cy = ky - ky0;
    if (cx < 0 || cy < 0 || cx >= cols || cy >= rows) return false;
    const c = cy * cols + cx;
    return total[c] > 0 && matched[c] >= total[c] * 0.9;
  };

  return (o: number) => {
    if (!band(px, o)) return false;
    const i = o >> 2;
    const x = i % w;
    const { kx, ky, expected, line } = locate(x, (i - x) / w);
    if (!(pure(kx, ky) || pure(kx - 1, ky) || pure(kx + 1, ky) || pure(kx, ky - 1) || pure(kx, ky + 1))) {
      return false;
    }
    // Chegara ustidagi piksel — ikki katak aralashmasi (masshtablangan rasmda).
    if (line < 0.5) return true;
    if (dist(px, o, colors[expected]) <= CHECKER_TOL + 6) return true;
    // To'r biroz siljigan bo'lsa (taxmin xatosi) — chegaraga yaqin joyda boshqa rang ham fon.
    return line < 1.6 && dist(px, o, colors[1 - expected]) <= CHECKER_TOL + 6;
  };
}

/** Bitta qator bo'ylab katak davri va fazasi; topilmasa null. */
function axisGrid(length: number, cls: (k: number) => 0 | 1 | 2) {
  const edges: number[] = [];
  const after: (1 | 2)[] = [];
  let last: 0 | 1 | 2 = 0;
  let lastPos = -1;
  for (let k = 0; k < length; k++) {
    const c = cls(k);
    if (c === 0) continue;
    if (last && k - lastPos > 2) {
      // Orada mahsulot bor — chegara noaniq, zanjir shu yerda uziladi.
      edges.push(NaN);
      after.push(c);
    } else if (last && c !== last) {
      edges.push((lastPos + 1 + k) / 2);
      after.push(c);
    }
    last = c;
    lastPos = k;
  }
  if (edges.length < 4) return null;

  const diffs = edges.slice(1).map((e, k) => e - edges[k]);
  const valid = diffs.filter((d) => !Number.isNaN(d)).sort((p, q) => p - q);
  if (valid.length < 3) return null;
  const med = valid[valid.length >> 1];
  if (med < 2) return null;
  const slack = Math.max(1, med * 0.15);
  let bestStart = 0;
  let bestLen = 0;
  let runStart = 0;
  diffs.forEach((d, k) => {
    if (Number.isNaN(d) || Math.abs(d - med) > slack) {
      runStart = k + 1;
      return;
    }
    if (k - runStart + 1 > bestLen) {
      bestLen = k - runStart + 1;
      bestStart = runStart;
    }
  });
  if (bestLen < 3) return null;

  const start = edges[bestStart];
  const cell = (edges[bestStart + bestLen] - start) / bestLen;
  return { grid: { start, cell, first: after[bestStart] } as AxisGrid, score: bestLen };
}

// ── helpers ────────────────────────────────────────────────────────

function canvas(w: number, h: number): HTMLCanvasElement {
  const c = document.createElement("canvas");
  c.width = w;
  c.height = h;
  return c;
}

function context(c: HTMLCanvasElement): CanvasRenderingContext2D {
  const ctx = c.getContext("2d", { willReadFrequently: true });
  if (!ctx) throw new Error("Brauzer rasmni qayta ishlay olmadi.");
  return ctx;
}

function toBlob(c: HTMLCanvasElement, type: string, quality?: number): Promise<Blob | null> {
  return new Promise((resolve) => c.toBlob(resolve, type, quality));
}

async function encode(c: HTMLCanvasElement, transparent: boolean): Promise<Blob> {
  // Safari WEBP yozolmaydi — toBlob PNG qaytaradi, shuning uchun turini tekshiramiz.
  const webp = await toBlob(c, "image/webp", transparent ? 0.92 : 0.88);
  if (webp && webp.type === "image/webp") return webp;
  const fallback = transparent ? await toBlob(c, "image/png") : await toBlob(c, "image/jpeg", 0.9);
  if (!fallback) throw new Error("Rasmni saqlab bo'lmadi.");
  return fallback;
}

/** Chetdagi piksellar indekslari (`depth` qator ichkariga ham). */
function borderIndexes(w: number, h: number, depth = 1): number[] {
  const out: number[] = [];
  for (let d = 0; d < depth && d < h / 2 && d < w / 2; d++) {
    for (let x = d; x < w - d; x++) {
      out.push(d * w + x);
      if (h - 1 - d !== d) out.push((h - 1 - d) * w + x);
    }
    for (let y = d + 1; y < h - 1 - d; y++) {
      out.push(y * w + d);
      if (w - 1 - d !== d) out.push(y * w + (w - 1 - d));
    }
  }
  return out;
}

/** Chetdagi ranglarni guruhlarga ajratadi, eng ko'pi birinchi. */
function clusterColors(px: Uint8ClampedArray, idx: number[]) {
  const clusters: { color: RGB; sum: RGB; count: number }[] = [];
  for (const i of idx) {
    const o = i * 4;
    let best = -1;
    let bestD = Infinity;
    for (let k = 0; k < clusters.length; k++) {
      const d = dist(px, o, clusters[k].color);
      if (d < bestD) {
        bestD = d;
        best = k;
      }
    }
    if (best === -1 || (bestD > 22 && clusters.length < 16)) {
      clusters.push({ color: [px[o], px[o + 1], px[o + 2]], sum: [px[o], px[o + 1], px[o + 2]], count: 1 });
      continue;
    }
    const c = clusters[best];
    c.count++;
    c.sum[0] += px[o];
    c.sum[1] += px[o + 1];
    c.sum[2] += px[o + 2];
    c.color = [Math.round(c.sum[0] / c.count), Math.round(c.sum[1] / c.count), Math.round(c.sum[2] / c.count)];
  }
  return clusters.sort((a, b) => b.count - a.count);
}

/** Katak foniga tegishli piksel: rangsiz, yorug'ligi ikki katak oralig'ida. */
function checkerBand(a: RGB, b: RGB) {
  const lo = Math.min(lum(a), lum(b)) - CHECKER_TOL;
  const hi = Math.max(lum(a), lum(b)) + CHECKER_TOL;
  return (px: Uint8ClampedArray, o: number) => {
    const r = px[o];
    const g = px[o + 1];
    const bl = px[o + 2];
    const l = 0.299 * r + 0.587 * g + 0.114 * bl;
    return Math.max(r, g, bl) - Math.min(r, g, bl) <= 16 && l >= lo && l <= hi;
  };
}

function contentBounds(px: Uint8ClampedArray, w: number, h: number, isContent: (o: number) => boolean) {
  let x0 = w;
  let y0 = h;
  let x1 = -1;
  let y1 = -1;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      if (!isContent((y * w + x) * 4)) continue;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y < y0) y0 = y;
      if (y > y1) y1 = y;
    }
  }
  if (x1 < 0) return null;
  return { x0, y0, x1: x1 + 1, y1: y1 + 1 };
}

/** Mahsulot chetning 25% dan ko'prog'iga tegib tursa — u tomondan kesilgan bo'lishi mumkin. */
function cutSides(px: Uint8ClampedArray, w: number, h: number, isContent: (o: number) => boolean) {
  const run = (count: number, at: (k: number) => number) => {
    let hits = 0;
    for (let k = 0; k < count; k++) if (isContent(at(k) * 4)) hits++;
    return hits / count >= 0.25;
  };
  const sides: FittedImage["cutEdges"] = [];
  if (run(w, (x) => x)) sides.push("top");
  if (run(w, (x) => (h - 1) * w + x)) sides.push("bottom");
  if (run(h, (y) => y * w)) sides.push("left");
  if (run(h, (y) => y * w + w - 1)) sides.push("right");
  return sides;
}

function dist(px: Uint8ClampedArray, o: number, c: RGB) {
  const dr = px[o] - c[0];
  const dg = px[o + 1] - c[1];
  const db = px[o + 2] - c[2];
  return Math.sqrt(dr * dr + dg * dg + db * db);
}

const lum = (c: RGB) => 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2];
const chroma = (c: RGB) => Math.max(...c) - Math.min(...c);
