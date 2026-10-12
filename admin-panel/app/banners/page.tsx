"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { Flame, Cylinder, Zap, Truck, Tag } from "lucide-react";
import { Topbar } from "@/components/Topbar";
import { Modal, ModalButton } from "@/components/ui/Modal";
import { errorText, useConfirm, useToast } from "@/components/ui/feedback";
import { createBanner, deleteBanner, fetchBanners, setBannerActive, updateBanner } from "@/lib/db";
import { BannerInput, BannerIcon, BANNER_ICONS, BUNDLED_BANNER_IMAGE, cleanBanner, isWebUrl, PromoBanner } from "@/lib/banners";
import { CATEGORY_LABEL } from "@/lib/types";
import { uploadProductImage } from "@/lib/supabase";

const EMPTY: BannerInput = { title: "", caption: "", accent: "#16A34A", imageUrl: null, icon: "flame", link: "", sortOrder: 0, isActive: true };
const field = "w-full rounded-xl border border-border bg-surface px-3 py-2.5 text-sm";
const button = "rounded-xl border border-border px-3 py-2 text-sm font-semibold disabled:opacity-40";

export default function BannersPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const [rows, setRows] = useState<PromoBanner[]>([]);
  const [loading, setLoading] = useState(true);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState("");
  const [editing, setEditing] = useState<PromoBanner | "new" | null>(null);
  const [draft, setDraft] = useState<BannerInput>(EMPTY);
  const [busy, setBusy] = useState(false);

  async function load() {
    setLoading(true);
    try {
      const result = await fetchBanners();
      setRows(result.banners); setReady(result.ready); setError("");
    } catch (err) { setError(errorText(err)); }
    finally { setLoading(false); }
  }
  useEffect(() => {
    let cancelled = false;
    void fetchBanners().then((result) => {
      if (!cancelled) { setRows(result.banners); setReady(result.ready); }
    }).catch((err) => { if (!cancelled) setError(errorText(err)); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, []);

  function open(row?: PromoBanner) {
    setDraft(row ? { ...row } : { ...EMPTY, sortOrder: Math.max(0, ...rows.map((r) => r.sortOrder)) + 1 });
    setEditing(row ?? "new");
  }
  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!editing || busy) return;
    setBusy(true);
    try {
      const input = cleanBanner(draft);
      if (editing === "new") await createBanner(input);
      else await updateBanner(editing.id, input);
      setEditing(null); toast.success("Banner saqlandi. Ilovada bosh sahifani yangilang."); await load();
    } catch (err) { toast.error(errorText(err)); }
    finally { setBusy(false); }
  }
  async function upload(file?: File) {
    if (!file) return;
    if (!["image/png", "image/jpeg", "image/webp"].includes(file.type) || file.size > 5 * 1024 * 1024) {
      toast.error("PNG, JPG yoki WEBP rasm tanlang (5 MB gacha)."); return;
    }
    setBusy(true);
    try {
      const url = await uploadProductImage(file);
      setDraft((value) => ({ ...value, imageUrl: url }));
    } catch (err) { toast.error(errorText(err, "Rasm yuklanmadi.")); }
    finally { setBusy(false); }
  }
  async function toggle(row: PromoBanner) {
    setBusy(true);
    try { await setBannerActive(row.id, !row.isActive); await load(); }
    catch (err) { toast.error(errorText(err)); }
    finally { setBusy(false); }
  }
  async function remove(row: PromoBanner) {
    if (!await confirm({ title: "Bannerni o'chirish", message: `“${row.title}” o'chirilsinmi?`, danger: true, confirmLabel: "O'chirish" })) return;
    setBusy(true);
    try { await deleteBanner(row.id); await load(); toast.success("Banner o'chirildi."); }
    catch (err) { toast.error(errorText(err)); }
    finally { setBusy(false); }
  }

  return <>
    <Topbar title="Reklama" subtitle="Ilovaning bosh sahifasidagi bannerlar" />
    <main className="space-y-5 p-4 sm:p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-foreground/60">Kichik tartib raqami birinchi chiqadi. Barcha bannerlar o‘chirilsa, reklama yashiriladi.</p>
        <div className="flex gap-2">
          <button className={button} disabled={busy || loading} onClick={() => void load()}>Yangilash</button>
          <button className={`${button} bg-brand text-white`} disabled={!ready || loading || busy} onClick={() => open()}>Banner qo‘shish</button>
        </div>
      </div>
      {error && <div role="alert" className="rounded-xl bg-danger/10 p-4 text-danger">{error}</div>}
      {loading ? <p role="status">Yuklanmoqda…</p> : !ready && !error ?
        <div className="rounded-2xl border border-border bg-surface p-5">
          <p>Reklama bo‘limini ulash uchun Tizim sahifasidagi reklama sozlamasini ishga tushiring.</p>
          <Link className="mt-3 inline-block font-semibold text-brand" href="/system">Tizimga o‘tish →</Link>
        </div> : ready && rows.length === 0 ? <p>Hali banner yo‘q. Birinchi bannerni qo‘shing.</p> :
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {rows.map((row) => <article key={row.id} className="min-w-0 space-y-3 rounded-2xl border border-border bg-surface p-4">
            <BannerPreview value={row} />
            <p className="text-xs text-foreground/60">Tartib: {row.sortOrder} · {row.isActive ? "Faol" : "Yashirilgan"}</p>
            <div className="flex flex-wrap gap-2">
              <button className={button} disabled={busy} onClick={() => open(row)}>Tahrirlash</button>
              <button className={button} disabled={busy} onClick={() => void toggle(row)}>{row.isActive ? "Yashirish" : "Yoqish"}</button>
              <button className={`${button} text-danger`} disabled={busy} onClick={() => void remove(row)}>O‘chirish</button>
            </div>
          </article>)}
        </div>}
    </main>
    {editing && <Modal title={editing === "new" ? "Yangi banner" : "Bannerni tahrirlash"} busy={busy} onClose={() => setEditing(null)} onSubmit={save}
      footer={<><ModalButton variant="ghost" disabled={busy} onClick={() => setEditing(null)}>Bekor qilish</ModalButton><ModalButton type="submit" disabled={busy}>{busy ? "Saqlanmoqda…" : "Saqlash"}</ModalButton></>}>
      <fieldset disabled={busy} className="space-y-4">
        <BannerPreview value={draft} />
        <label className="block space-y-1 text-sm">Sarlavha<input required maxLength={60} className={field} value={draft.title} onChange={(e) => setDraft({ ...draft, title: e.target.value })} /></label>
        <label className="block space-y-1 text-sm">Izoh<input maxLength={90} className={field} value={draft.caption} onChange={(e) => setDraft({ ...draft, caption: e.target.value })} /></label>
        <div className="grid grid-cols-2 gap-3">
          <label className="block space-y-1 text-sm">Rang<input type="color" className={`${field} h-11`} value={draft.accent} onChange={(e) => setDraft({ ...draft, accent: e.target.value })} /></label>
          <label className="block space-y-1 text-sm">Tartib<input type="number" required min={0} max={2147483647} step={1} className={field} value={draft.sortOrder} onChange={(e) => setDraft({ ...draft, sortOrder: Number(e.target.value) })} /></label>
        </div>
        <label className="block space-y-1 text-sm">Rasm yuklash<input type="file" accept="image/png,image/jpeg,image/webp" className={field} onChange={(e) => void upload(e.target.files?.[0])} /><span className="text-xs text-foreground/50">PNG, JPG yoki WEBP, 5 MB gacha. Rasm kesilmasdan joylashadi.</span></label>
        <label className="block space-y-1 text-sm">Rasm havolasi<input className={field} value={draft.imageUrl ?? ""} onChange={(e) => setDraft({ ...draft, imageUrl: e.target.value || null })} placeholder="https://…" /></label>
        <button type="button" className={button} onClick={() => setDraft({ ...draft, imageUrl: null })}>Rasm o‘rniga belgi</button>
        <label className="block space-y-1 text-sm">Belgi<select className={field} value={draft.icon} onChange={(e) => setDraft({ ...draft, icon: e.target.value as BannerIcon })}>{Object.entries(BANNER_ICONS).map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></label>
        <label className="block space-y-1 text-sm">Bosilganda<select className={field} value={draft.link.startsWith("url:") ? "external" : draft.link} onChange={(e) => setDraft({ ...draft, link: e.target.value === "external" ? "url:https://" : e.target.value })}>
          <option value="">Havolasiz</option><option value="services">Xizmatlar</option>
          {Object.entries(CATEGORY_LABEL).map(([key, label]) => <option key={key} value={`category:${key}`}>{label}</option>)}
          <option value="external">Tashqi sayt</option>
        </select></label>
        {draft.link.startsWith("url:") && <label className="block space-y-1 text-sm">Sayt manzili<input type="url" required className={field} value={draft.link.slice(4)} onChange={(e) => setDraft({ ...draft, link: `url:${e.target.value}` })} /></label>}
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={draft.isActive} onChange={(e) => setDraft({ ...draft, isActive: e.target.checked })} />Ilovada ko‘rsatish</label>
      </fieldset>
    </Modal>}
  </>;
}

function BannerPreview({ value }: { value: BannerInput }) {
  const image = value.imageUrl === BUNDLED_BANNER_IMAGE ? "/images/promo_gas_cylinder.png" : value.imageUrl && isWebUrl(value.imageUrl) ? value.imageUrl : null;
  const Icon = { flame: Flame, cylinder: Cylinder, bolt: Zap, truck: Truck, tag: Tag }[value.icon];
  return <div className="flex h-[148px] items-center gap-3 overflow-hidden rounded-3xl border p-4" style={{ background: `linear-gradient(120deg, ${value.accent}0d, ${value.accent}26)`, borderColor: `${value.accent}30` }}>
    <div className="min-w-0 flex-1"><h2 className="line-clamp-2 text-lg font-bold leading-tight">{value.title || "Banner sarlavhasi"}</h2><p className="mt-2 line-clamp-3 text-sm">{value.caption}</p></div>
    <div className="flex h-24 w-24 shrink-0 items-center justify-center">
      {image ? <Image unoptimized src={image} alt="" width={96} height={96} className="h-full w-full object-contain" /> : <span className="rounded-full p-5 text-white" style={{ background: value.accent }}><Icon aria-label={BANNER_ICONS[value.icon]} className="h-9 w-9" /></span>}
    </div>
  </div>;
}
