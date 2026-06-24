"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface PricingAdminActionState {
  error?: string;
  ok?: boolean;
}

export async function setCurrencyRate(
  _prev: PricingAdminActionState | null,
  formData: FormData,
): Promise<PricingAdminActionState> {
  const baseCode = String(formData.get("baseCode") ?? "").trim().toUpperCase();
  const quoteCode = String(formData.get("quoteCode") ?? "").trim().toUpperCase();
  const rate = Number(formData.get("rate"));
  const effectiveFrom = (formData.get("effectiveFrom") as string | null) || undefined;
  const effectiveTo = (formData.get("effectiveTo") as string | null) || undefined;
  const source = (formData.get("source") as string | null)?.trim() || "manual";

  if (!baseCode || !quoteCode) return { error: "کد ارز نامعتبر" };
  if (baseCode === quoteCode) return { error: "کد مبدا و مقصد نباید یکسان باشد" };
  if (!Number.isFinite(rate) || rate <= 0) return { error: "نرخ نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("admin_set_currency_rate", {
      p_base_code: baseCode,
      p_quote_code: quoteCode,
      p_rate: rate,
      p_effective_from: effectiveFrom,
      p_effective_to: effectiveTo,
      p_source: source,
    });
  if (error) {
    console.error("admin_set_currency_rate", error);
    return { error: "ثبت نرخ ارز ناموفق بود" };
  }
  revalidatePath("/admin/pricing");
  redirect("/admin/pricing?tab=currency-rates");
}

export async function expireDueQuotations(
  _prev: PricingAdminActionState | null,
  _formData: FormData,
): Promise<PricingAdminActionState> {
  const supabase = await createClient();
  const { error } = await supabase
    .schema("pricing")
    .rpc("admin_expire_due_quotations");
  if (error) {
    console.error("admin_expire_due_quotations", error);
    return { error: "اجرای انقضای پیشنهادها ناموفق بود" };
  }
  revalidatePath("/admin/pricing");
  return { ok: true };
}
