"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface RfqActionState {
  error?: string;
  ok?: boolean;
  count?: number;
}

function revalidateBuyer(id: string) {
  revalidatePath("/buyer/rfqs");
  revalidatePath(`/buyer/rfqs/${id}`);
  revalidatePath("/admin/rfqs");
  revalidatePath(`/admin/rfqs/${id}`);
}

export async function buyerCreateRfq(
  _prev: RfqActionState | null,
  formData: FormData,
): Promise<RfqActionState> {
  const title = String(formData.get("title") ?? "").trim();
  const description = (formData.get("description") as string | null)?.trim() || undefined;
  const currency = (formData.get("preferredCurrency") as string | null)?.trim() || undefined;
  const deadline = (formData.get("submissionDeadline") as string | null) || undefined;
  const deliveryCountry = (formData.get("deliveryCountry") as string | null)?.trim() || undefined;
  const deliveryCity = (formData.get("deliveryCity") as string | null)?.trim() || undefined;
  const paymentTerms = (formData.get("paymentTermsText") as string | null)?.trim() || undefined;

  if (!title) return { error: "عنوان الزامی است" };

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("rfq")
    .rpc("buyer_create_rfq", {
      p_title: title,
      p_description: description,
      p_preferred_currency: currency,
      p_submission_deadline: deadline,
      p_delivery_country: deliveryCountry,
      p_delivery_city: deliveryCity,
      p_payment_terms_text: paymentTerms,
    });
  if (error) {
    console.error("buyer_create_rfq", error);
    return { error: "ایجاد RFQ ناموفق بود" };
  }
  revalidatePath("/buyer/rfqs");
  redirect(`/buyer/rfqs/${data}`);
}

export async function buyerUpsertRfqItem(
  _prev: RfqActionState | null,
  formData: FormData,
): Promise<RfqActionState> {
  const requestId = String(formData.get("requestId") ?? "");
  const productId = (formData.get("productId") as string | null)?.trim() || undefined;
  const quantityRaw = formData.get("quantity");
  const quantity = quantityRaw ? Number(quantityRaw) : undefined;
  const quantityUnit = (formData.get("quantityUnit") as string | null)?.trim() || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;
  if (!requestId) return { error: "شناسه RFQ نامعتبر" };
  if (quantity !== undefined && (!Number.isFinite(quantity) || quantity <= 0)) {
    return { error: "تعداد نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("rfq")
    .rpc("buyer_upsert_rfq_item", {
      p_request_id: requestId,
      p_product_id: productId,
      p_quantity: quantity,
      p_quantity_unit: quantityUnit,
      p_notes: notes,
    });
  if (error) {
    console.error("buyer_upsert_rfq_item", error);
    return { error: "افزودن ردیف ناموفق بود" };
  }
  revalidateBuyer(requestId);
  return { ok: true };
}

export async function buyerRemoveRfqItem(
  _prev: RfqActionState | null,
  formData: FormData,
): Promise<RfqActionState> {
  const itemId = String(formData.get("itemId") ?? "");
  const requestId = String(formData.get("requestId") ?? "");
  if (!itemId) return { error: "شناسه ردیف نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("rfq")
    .rpc("buyer_remove_rfq_item", { p_item_id: itemId });
  if (error) {
    console.error("buyer_remove_rfq_item", error);
    return { error: "حذف ردیف ناموفق بود" };
  }
  if (requestId) revalidateBuyer(requestId);
  return { ok: true };
}

export async function buyerInviteSuppliers(
  _prev: RfqActionState | null,
  formData: FormData,
): Promise<RfqActionState> {
  const requestId = String(formData.get("requestId") ?? "");
  const supplierIdsRaw = String(formData.get("supplierIds") ?? "");
  const message = (formData.get("message") as string | null)?.trim() || undefined;
  if (!requestId) return { error: "شناسه RFQ نامعتبر" };

  const ids = supplierIdsRaw
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
  if (ids.length === 0) return { error: "هیچ شناسه‌ای وارد نشده" };

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("rfq")
    .rpc("buyer_invite_suppliers", {
      p_request_id: requestId,
      p_supplier_ids: ids,
      p_message: message,
    });
  if (error) {
    console.error("buyer_invite_suppliers", error);
    return { error: "ارسال دعوت‌ها ناموفق بود" };
  }
  revalidateBuyer(requestId);
  return { ok: true, count: Number(data ?? 0) };
}

export async function buyerSubmitRfq(
  _prev: RfqActionState | null,
  formData: FormData,
): Promise<RfqActionState> {
  const id = String(formData.get("requestId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("rfq")
    .rpc("buyer_submit_rfq", { p_request_id: id });
  if (error) {
    console.error("buyer_submit_rfq", error);
    return { error: "انتشار ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerCloseRfq(
  _prev: RfqActionState | null,
  formData: FormData,
): Promise<RfqActionState> {
  const id = String(formData.get("requestId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("rfq")
    .rpc("buyer_close_rfq", { p_request_id: id });
  if (error) {
    console.error("buyer_close_rfq", error);
    return { error: "بستن ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerCancelRfq(
  _prev: RfqActionState | null,
  formData: FormData,
): Promise<RfqActionState> {
  const id = String(formData.get("requestId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("rfq")
    .rpc("buyer_cancel_rfq", { p_request_id: id, p_reason: reason });
  if (error) {
    console.error("buyer_cancel_rfq", error);
    return { error: "لغو ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}
