import { createClient } from "@/lib/supabase/server";

export interface TenantOption {
  id: string;
  code: string;
  nameFa: string;
  nameEn: string;
}

export async function listTenants(): Promise<TenantOption[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("identity")
    .from("tenants")
    .select("id, code, name_fa, name_en")
    .is("deleted_at", null)
    .order("code");

  if (error) {
    console.error("list_tenants", error);
    return [];
  }
  return (data ?? []).map((t) => ({
    id: t.id,
    code: t.code,
    nameFa: t.name_fa,
    nameEn: t.name_en,
  }));
}
