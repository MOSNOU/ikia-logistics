import { createClient } from "@/lib/supabase/server";
import type { OrganizationStatus, OrganizationType } from "@/types/database";

export interface AdminOrganizationRow {
  id: string;
  tenantId: string;
  code: string;
  nameFa: string;
  nameEn: string;
  type: OrganizationType;
  status: OrganizationStatus;
  countryCode: string;
  createdAt: string;
}

export interface ListOrgsResult {
  rows: AdminOrganizationRow[];
  page: number;
  pageSize: number;
}

export async function listAdminOrganizations({
  page = 0,
  pageSize = 25,
}: { page?: number; pageSize?: number } = {}): Promise<ListOrgsResult> {
  const supabase = await createClient();
  const from = page * pageSize;
  const to = from + pageSize - 1;
  const { data, error } = await supabase
    .schema("organization")
    .from("organizations")
    .select("id, tenant_id, code, name_fa, name_en, type, status, country_code, created_at")
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .range(from, to);

  if (error) {
    console.error("list_organizations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []).map((o) => ({
      id: o.id,
      tenantId: o.tenant_id,
      code: o.code,
      nameFa: o.name_fa,
      nameEn: o.name_en,
      type: o.type,
      status: o.status,
      countryCode: o.country_code,
      createdAt: o.created_at,
    })),
    page,
    pageSize,
  };
}

export async function getAdminOrganization(orgId: string): Promise<AdminOrganizationRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("organization")
    .from("organizations")
    .select("id, tenant_id, code, name_fa, name_en, type, status, country_code, created_at")
    .eq("id", orgId)
    .maybeSingle();

  if (error || !data) {
    if (error) console.error("get_organization", error);
    return null;
  }
  return {
    id: data.id,
    tenantId: data.tenant_id,
    code: data.code,
    nameFa: data.name_fa,
    nameEn: data.name_en,
    type: data.type,
    status: data.status,
    countryCode: data.country_code,
    createdAt: data.created_at,
  };
}
