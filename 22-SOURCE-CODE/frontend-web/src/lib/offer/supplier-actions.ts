"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface OfferActionState {
  error?: string;
  ok?: boolean;
}

function revalidateSupplier(id: string) {
  revalidatePath("/supplier/offers");
  revalidatePath(`/supplier/offers/${id}`);
  revalidatePath("/admin/offers");
  revalidatePath(`/admin/offers/${id}`);
}

export async function supplierCreateDraftOffer(
  _prev: OfferActionState | null,
  formData: FormData,
): Promise<OfferActionState> {
  const requestId = String(formData.get("requestId") ?? "");
  const currency = (formData.get("currency") as string | null)?.trim() || undefined;
  if (!requestId) return { error: "شناسه RFQ نامعتبر" };

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("offer")
    .rpc("supplier_create_draft_offer", {
      p_request_id: requestId,
      p_currency: currency,
    });
  if (error) {
    console.error("supplier_create_draft_offer", error);
    return { error: "ایجاد پیش‌نویس پیشنهاد ناموفق بود" };
  }
  revalidatePath("/supplier/offers");
  redirect(`/supplier/offers/${data}`);
}

export async function supplierUpsertOfferItem(
  _prev: OfferActionState | null,
  formData: FormData,
): Promise<OfferActionState> {
  const offerId = String(formData.get("offerId") ?? "");
  const requestItemId = (formData.get("requestItemId") as string | null)?.trim() || undefined;
  const offeredQuantity = formData.get("offeredQuantity")
    ? Number(formData.get("offeredQuantity"))
    : undefined;
  const quantityUnit = (formData.get("quantityUnit") as string | null)?.trim() || undefined;
  const unitPrice = formData.get("unitPrice")
    ? Number(formData.get("unitPrice"))
    : undefined;
  const totalPrice = formData.get("totalPrice")
    ? Number(formData.get("totalPrice"))
    : undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;
  if (!offerId) return { error: "شناسه پیشنهاد نامعتبر" };
  if (offeredQuantity !== undefined && (!Number.isFinite(offeredQuantity) || offeredQuantity <= 0)) {
    return { error: "تعداد نامعتبر" };
  }
  if (unitPrice !== undefined && (!Number.isFinite(unitPrice) || unitPrice < 0)) {
    return { error: "قیمت واحد نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("offer")
    .rpc("supplier_upsert_offer_item", {
      p_offer_id: offerId,
      p_request_item_id: requestItemId,
      p_offered_quantity: offeredQuantity,
      p_quantity_unit: quantityUnit,
      p_unit_price: unitPrice,
      p_total_price: totalPrice,
      p_notes: notes,
    });
  if (error) {
    console.error("supplier_upsert_offer_item", error);
    return { error: "افزودن ردیف ناموفق بود" };
  }
  revalidateSupplier(offerId);
  return { ok: true };
}

export async function supplierRemoveOfferItem(
  _prev: OfferActionState | null,
  formData: FormData,
): Promise<OfferActionState> {
  const itemId = String(formData.get("offerItemId") ?? "");
  const offerId = String(formData.get("offerId") ?? "");
  if (!itemId) return { error: "شناسه ردیف نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("offer")
    .rpc("supplier_remove_offer_item", { p_offer_item_id: itemId });
  if (error) {
    console.error("supplier_remove_offer_item", error);
    return { error: "حذف ردیف ناموفق بود" };
  }
  if (offerId) revalidateSupplier(offerId);
  return { ok: true };
}

export async function supplierSubmitOffer(
  _prev: OfferActionState | null,
  formData: FormData,
): Promise<OfferActionState> {
  const id = String(formData.get("offerId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("offer")
    .rpc("supplier_submit_my_offer", { p_offer_id: id });
  if (error) {
    console.error("supplier_submit_my_offer", error);
    return { error: "ارسال پیشنهاد ناموفق بود" };
  }
  revalidateSupplier(id);
  return { ok: true };
}

export async function supplierWithdrawOffer(
  _prev: OfferActionState | null,
  formData: FormData,
): Promise<OfferActionState> {
  const id = String(formData.get("offerId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("offer")
    .rpc("supplier_withdraw_my_offer", { p_offer_id: id, p_reason: reason });
  if (error) {
    console.error("supplier_withdraw_my_offer", error);
    return { error: "پس‌گرفتن ناموفق بود" };
  }
  revalidateSupplier(id);
  return { ok: true };
}
