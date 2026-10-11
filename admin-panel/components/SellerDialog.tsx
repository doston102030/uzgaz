"use client";

import { FormEvent, useState } from "react";
import { Loader2 } from "lucide-react";
import clsx from "clsx";
import { Modal, ModalButton } from "@/components/ui/Modal";
import { createSeller, updateSeller } from "@/lib/db";
import { CATEGORY_LABEL, DISTRICTS, Seller, SellerStatus, ServiceCategory } from "@/lib/types";

const CATEGORIES = Object.keys(CATEGORY_LABEL) as ServiceCategory[];

const inputClass =
  "w-full rounded-xl border border-border bg-surface-muted px-3 py-2.5 text-sm text-foreground outline-none placeholder:text-foreground/35 focus:border-brand-light focus:bg-surface";

/** "+998 90 123 45 67" → "90 123 45 67" for the input next to the fixed +998. */
function localPhone(phone: string) {
  const digits = phone.replace(/\D/g, "");
  const local = digits.length === 12 && digits.startsWith("998") ? digits.slice(3) : digits;
  return local.replace(/^(\d{2})(\d{3})(\d{2})(\d{2})$/, "$1 $2 $3 $4");
}

/**
 * Admin adds a company straight to `sellers`, or — given `seller` — edits
 * its details (the pencil in the sellers list). Status has its own buttons.
 */
export function SellerDialog({
  seller,
  onClose,
  onSaved,
}: {
  seller?: Seller;
  onClose: () => void;
  onSaved: (seller: Seller) => void;
}) {
  const editing = Boolean(seller);
  const [companyName, setCompanyName] = useState(seller?.companyName ?? "");
  const [ownerName, setOwnerName] = useState(seller?.ownerName ?? "");
  const [category, setCategory] = useState<ServiceCategory>(seller?.category ?? "gazBallon");
  const [district, setDistrict] = useState<string>(seller?.district ?? DISTRICTS[0]);
  const [address, setAddress] = useState(seller?.address ?? "");
  const [phone, setPhone] = useState(seller ? localPhone(seller.phone) : "");
  const [status, setStatus] = useState<SellerStatus>("approved");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: FormEvent) {
    e.preventDefault();
    // Accepts "90 123 45 67" or a pasted "+998 90 123 45 67"; only a full
    // 12-digit number loses its 998 (a 99-operator number starts with 998 too).
    let digits = phone.replace(/\D/g, "");
    if (digits.length === 12 && digits.startsWith("998")) digits = digits.slice(3);
    if (!companyName.trim() || !ownerName.trim()) {
      setError("Kompaniya nomi va egasining ismini kiriting.");
      return;
    }
    if (digits.length !== 9) {
      setError("Telefon raqami 9 ta raqamdan iborat bo'lsin, masalan: 90 123 45 67.");
      return;
    }
    setError(null);
    setSaving(true);
    const input = {
      companyName: companyName.trim(),
      ownerName: ownerName.trim(),
      category,
      district,
      address: address.trim(),
      phone: `+998${digits}`,
    };
    try {
      const saved = seller ? await updateSeller(seller.id, input) : await createSeller({ ...input, status });
      onSaved(saved);
    } catch (err) {
      setError(`Saqlab bo'lmadi: ${err instanceof Error ? err.message : "noma'lum xatolik"}`);
      setSaving(false);
    }
  }

  return (
    <Modal
      busy={saving}
      onClose={onClose}
      onSubmit={submit}
      title={editing ? "Sotuvchini tahrirlash" : "Yangi sotuvchi"}
      subtitle={
        editing
          ? "Nom, manzil va telefon ilovadagi kompaniya kartasida ham yangilanadi"
          : "Kompaniya darhol ro'yxatga qo'shiladi"
      }
      footer={
        <>
          <ModalButton variant="ghost" onClick={onClose} disabled={saving}>
            Bekor qilish
          </ModalButton>
          <ModalButton type="submit" disabled={saving}>
            {saving && <Loader2 className="h-4 w-4 animate-spin" />}
            {editing ? "Saqlash" : "Qo'shish"}
          </ModalButton>
        </>
      }
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="space-y-1.5 sm:col-span-2">
          <span className="text-xs font-semibold text-foreground/60">Kompaniya nomi *</span>
          <input
            autoFocus
            value={companyName}
            onChange={(e) => setCompanyName(e.target.value)}
            placeholder="Masalan: UzGaz Servis"
            className={inputClass}
          />
        </label>
        <label className="space-y-1.5 sm:col-span-2">
          <span className="text-xs font-semibold text-foreground/60">Egasi (F.I.Sh.) *</span>
          <input
            value={ownerName}
            onChange={(e) => setOwnerName(e.target.value)}
            placeholder="Masalan: Aliyev Vali"
            className={inputClass}
          />
        </label>
        <label className="space-y-1.5">
          <span className="text-xs font-semibold text-foreground/60">Faoliyat turi</span>
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value as ServiceCategory)}
            className={inputClass}
          >
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {CATEGORY_LABEL[c]}
              </option>
            ))}
          </select>
        </label>
        <label className="space-y-1.5">
          <span className="text-xs font-semibold text-foreground/60">Tuman</span>
          <select value={district} onChange={(e) => setDistrict(e.target.value)} className={inputClass}>
            {[...new Set([...DISTRICTS, district])].map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
        </label>
        <label className="space-y-1.5 sm:col-span-2">
          <span className="text-xs font-semibold text-foreground/60">Manzil</span>
          <input
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="Ko'cha, uy raqami"
            className={inputClass}
          />
        </label>
        <label className={clsx("space-y-1.5", editing && "sm:col-span-2")}>
          <span className="text-xs font-semibold text-foreground/60">Telefon *</span>
          <div className="flex items-center rounded-xl border border-border bg-surface-muted focus-within:border-brand-light focus-within:bg-surface">
            <span className="pl-3 text-sm text-foreground/50">+998</span>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              inputMode="tel"
              placeholder="90 123 45 67"
              className="w-full bg-transparent px-2 py-2.5 text-sm text-foreground outline-none placeholder:text-foreground/35"
            />
          </div>
        </label>
        {!editing && (
          <fieldset className="space-y-1.5">
            <legend className="mb-1.5 text-xs font-semibold text-foreground/60">Holati</legend>
            <div className="flex gap-2">
              {(
                [
                  ["approved", "Tasdiqlangan"],
                  ["pending", "Yangi ariza"],
                ] as const
              ).map(([value, label]) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setStatus(value)}
                  className={clsx(
                    "flex-1 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors",
                    status === value
                      ? "bg-brand text-white shadow-sm shadow-brand/30"
                      : "bg-surface-muted text-foreground/60 hover:bg-border",
                  )}
                >
                  {label}
                </button>
              ))}
            </div>
          </fieldset>
        )}
      </div>
      {error && (
        <p className="mt-4 rounded-xl border border-danger/30 bg-danger-tint px-3 py-2 text-sm text-danger">{error}</p>
      )}
    </Modal>
  );
}
