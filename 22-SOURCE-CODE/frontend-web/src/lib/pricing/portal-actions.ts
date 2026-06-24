"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface PricingActionState {
  error?: string;
  ok?: boolean;
}

// =============================================================================
// Supplier portal actions — price lists
// =============================================================================

export async function createPriceList(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const supplierId = String(formData.get("supplierId") ?? "");
  const code = String(formData.get("code") ?? "").trim();
  const nameEn = String(formData.get("nameEn") ?? "").trim();
  const nameFa = String(formData.get("nameFa") ?? "").trim();
  const currencyCode = String(formData.get("currencyCode") ?? "").trim();
  const description = (formData.get("description") as string | null) || undefined;

  if (!supplierId || !code || !nameEn || !nameFa || !currencyCode) {
    return { error: "همه فیلدهای الزامی را پر کنید" };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .rpc("portal_create_price_list", {
      p_supplier_id: supplierId,
      p_code: code,
      p_name_en: nameEn,
      p_name_fa: nameFa,
      p_currency_code: currencyCode,
      p_description: description,
    });

  if (error) {
    console.error("portal_create_price_list", error);
    return { error: "ایجاد فهرست قیمت ناموفق بود" };
  }
  revalidatePath("/supplier/price-lists");
  redirect(`/supplier/price-lists/${data}`);
}

export async function upsertPriceListItem(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const priceListId = String(formData.get("priceListId") ?? "");
  const productId = String(formData.get("productId") ?? "");
  const unitPriceRaw = formData.get("unitPrice");
  const uom = String(formData.get("uom") ?? "").trim();
  const minQtyRaw = formData.get("minQty");
  const maxQtyRaw = formData.get("maxQty");
  const notes = (formData.get("notes") as string | null) || undefined;

  if (!priceListId || !productId || !uom || unitPriceRaw == null) {
    return { error: "ورودی نامعتبر" };
  }
  const unitPrice = Number(unitPriceRaw);
  if (!Number.isFinite(unitPrice) || unitPrice < 0) {
    return { error: "قیمت نامعتبر" };
  }
  const minQty = minQtyRaw ? Number(minQtyRaw) : undefined;
  const maxQty = maxQtyRaw ? Number(maxQtyRaw) : undefined;

  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("portal_upsert_price_list_item", {
      p_price_list_id: priceListId,
      p_product_id: productId,
      p_unit_price: unitPrice,
      p_uom: uom,
      p_min_qty: minQty,
      p_max_qty: maxQty,
      p_notes: notes,
    });

  if (error) {
    console.error("portal_upsert_price_list_item", error);
    return { error: "ذخیره ردیف ناموفق بود" };
  }
  revalidatePath(`/supplier/price-lists/${priceListId}`);
  return { ok: true };
}

export async function publishPriceList(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const id = String(formData.get("priceListId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("portal_publish_price_list", { p_id: id, p_effective_from: undefined });
  if (error) {
    console.error("portal_publish_price_list", error);
    return { error: "انتشار فهرست ناموفق بود" };
  }
  revalidatePath(`/supplier/price-lists/${id}`);
  revalidatePath("/supplier/price-lists");
  return { ok: true };
}

export async function pausePriceList(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const id = String(formData.get("priceListId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("portal_pause_price_list", { p_id: id, p_reason: reason });
  if (error) {
    console.error("portal_pause_price_list", error);
    return { error: "توقف فهرست ناموفق بود" };
  }
  revalidatePath(`/supplier/price-lists/${id}`);
  revalidatePath("/supplier/price-lists");
  return { ok: true };
}

export async function archivePriceList(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const id = String(formData.get("priceListId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("portal_archive_price_list", { p_id: id, p_reason: reason });
  if (error) {
    console.error("portal_archive_price_list", error);
    return { error: "بایگانی فهرست ناموفق بود" };
  }
  revalidatePath(`/supplier/price-lists/${id}`);
  revalidatePath("/supplier/price-lists");
  return { ok: true };
}

// =============================================================================
// Supplier portal actions — quotations
// =============================================================================

export async function createQuotation(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const supplierId = String(formData.get("supplierId") ?? "");
  const buyerOrgId = String(formData.get("buyerOrganizationId") ?? "");
  const quotationCode = String(formData.get("quotationCode") ?? "").trim();
  const currencyCode = String(formData.get("currencyCode") ?? "").trim();
  const rfqRequestId = (formData.get("rfqRequestId") as string | null) || undefined;
  const validUntil = (formData.get("validUntil") as string | null) || undefined;

  if (!supplierId || !buyerOrgId || !quotationCode || !currencyCode) {
    return { error: "همه فیلدهای الزامی را پر کنید" };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .rpc("portal_create_quotation", {
      p_supplier_id: supplierId,
      p_buyer_organization_id: buyerOrgId,
      p_quotation_code: quotationCode,
      p_currency_code: currencyCode,
      p_rfq_request_id: rfqRequestId,
      p_valid_until: validUntil,
    });
  if (error) {
    console.error("portal_create_quotation", error);
    return { error: "ایجاد پیشنهاد ناموفق بود" };
  }
  revalidatePath("/supplier/quotations");
  redirect(`/supplier/quotations/${data}`);
}

export async function addQuotationItem(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const quotationId = String(formData.get("quotationId") ?? "");
  const productId = String(formData.get("productId") ?? "");
  const quantity = Number(formData.get("quantity"));
  const uom = String(formData.get("uom") ?? "").trim();
  const unitPrice = Number(formData.get("unitPrice"));
  const discount = formData.get("discount") ? Number(formData.get("discount")) : 0;
  const notes = (formData.get("notes") as string | null) || undefined;

  if (!quotationId || !productId || !uom) return { error: "ورودی نامعتبر" };
  if (!Number.isFinite(quantity) || quantity <= 0) return { error: "تعداد نامعتبر" };
  if (!Number.isFinite(unitPrice) || unitPrice < 0) return { error: "قیمت نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("portal_add_quotation_item", {
      p_quotation_id: quotationId,
      p_product_id: productId,
      p_quantity: quantity,
      p_uom: uom,
      p_unit_price: unitPrice,
      p_discount_amount: discount,
      p_notes: notes,
    });
  if (error) {
    console.error("portal_add_quotation_item", error);
    return { error: "افزودن ردیف ناموفق بود" };
  }
  revalidatePath(`/supplier/quotations/${quotationId}`);
  return { ok: true };
}

export async function sendQuotation(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const id = String(formData.get("quotationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("portal_send_quotation", { p_id: id });
  if (error) {
    console.error("portal_send_quotation", error);
    return { error: "ارسال پیشنهاد ناموفق بود" };
  }
  revalidatePath(`/supplier/quotations/${id}`);
  revalidatePath("/supplier/quotations");
  return { ok: true };
}

// =============================================================================
// Buyer portal actions
// =============================================================================

export async function acceptQuotation(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const id = String(formData.get("quotationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("portal_accept_quotation", { p_id: id });
  if (error) {
    console.error("portal_accept_quotation", error);
    return { error: "پذیرفتن پیشنهاد ناموفق بود" };
  }
  revalidatePath(`/buyer/quotations/${id}`);
  revalidatePath("/buyer/quotations");
  return { ok: true };
}

export async function rejectQuotation(
  _prev: PricingActionState | null,
  formData: FormData,
): Promise<PricingActionState> {
  const id = String(formData.get("quotationId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("portal_reject_quotation", { p_id: id, p_reason: reason });
  if (error) {
    console.error("portal_reject_quotation", error);
    return { error: "رد پیشنهاد ناموفق بود" };
  }
  revalidatePath(`/buyer/quotations/${id}`);
  revalidatePath("/buyer/quotations");
  return { ok: true };
}
