"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { OrganizationStatus, OrganizationType } from "@/types/database";

export interface CreateOrganizationState {
  error?: string;
}

const TYPES: OrganizationType[] = [
  "buyer",
  "supplier",
  "carrier",
  "broker",
  "government",
  "platform",
];

const STATUSES: OrganizationStatus[] = ["active", "pending", "suspended", "closed"];

export async function createOrganization(
  _prev: CreateOrganizationState | null,
  formData: FormData,
): Promise<CreateOrganizationState> {
  const tenantId = String(formData.get("tenantId") ?? "");
  const code = String(formData.get("code") ?? "").trim();
  const nameFa = String(formData.get("nameFa") ?? "").trim();
  const nameEn = String(formData.get("nameEn") ?? "").trim();
  const type = String(formData.get("type") ?? "") as OrganizationType;
  const status = (String(formData.get("status") ?? "pending") as OrganizationStatus);
  const countryCode = String(formData.get("countryCode") ?? "IR").slice(0, 2).toUpperCase();
  const legalName = (formData.get("legalName") as string | null) || null;
  const registrationNumber = (formData.get("registrationNumber") as string | null) || null;
  const taxId = (formData.get("taxId") as string | null) || null;

  if (!tenantId || !code || !nameFa || !nameEn || !TYPES.includes(type) || !STATUSES.includes(status)) {
    return { error: "فیلدهای ضروری معتبر نیستند" };
  }

  const supabase = await createClient();
  const { data: newId, error } = await supabase
    .schema("identity")
    .rpc("admin_create_organization", {
      p_tenant_id: tenantId,
      p_code: code,
      p_name_fa: nameFa,
      p_name_en: nameEn,
      p_type: type,
      p_status: status,
      p_country_code: countryCode,
      p_legal_name: legalName,
      p_registration_number: registrationNumber,
      p_tax_id: taxId,
    });

  if (error || !newId) {
    console.error("admin_create_organization", error);
    return { error: "ایجاد سازمان ناموفق بود" };
  }

  revalidatePath("/admin/organizations");
  redirect(`/admin/organizations/${newId}`);
}
