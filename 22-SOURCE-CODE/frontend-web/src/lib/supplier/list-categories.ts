import { createClient } from "@/lib/supabase/server";
import type { SupplierCategoryRow } from "@/types/database";

export async function listSupplierCategories(): Promise<SupplierCategoryRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("supplier")
    .from("categories")
    .select("id, code, name_fa, name_en, description, parent_category_id, is_active")
    .eq("is_active", true)
    .order("code");

  if (error) {
    console.error("list_supplier_categories", error);
    return [];
  }
  return (data ?? []) as SupplierCategoryRow[];
}
