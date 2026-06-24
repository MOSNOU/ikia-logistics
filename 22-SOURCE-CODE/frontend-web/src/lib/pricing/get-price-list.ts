import { createClient } from "@/lib/supabase/server";
import type { Database } from "@/types/database";

export type PriceListRow = Database["pricing"]["Tables"]["price_lists"]["Row"];
export type PriceListItemRow = Database["pricing"]["Tables"]["price_list_items"]["Row"];

export interface PriceListBundle {
  list: PriceListRow | null;
  items: PriceListItemRow[];
}

export async function getPriceList(listId: string): Promise<PriceListBundle> {
  const supabase = await createClient();

  const { data: list, error: listError } = await supabase
    .schema("pricing")
    .from("price_lists")
    .select(
      "id, tenant_id, supplier_id, organization_id, code, name_en, name_fa, description, currency_code, status, effective_from, effective_to, metadata, created_by, created_at, updated_by, updated_at, deleted_at, version",
    )
    .eq("id", listId)
    .is("deleted_at", null)
    .maybeSingle<PriceListRow>();

  if (listError) {
    console.error("get_price_list:lists", listError);
    return { list: null, items: [] };
  }
  if (!list) return { list: null, items: [] };

  const { data: items, error: itemsError } = await supabase
    .schema("pricing")
    .from("price_list_items")
    .select(
      "id, tenant_id, price_list_id, product_id, unit_price, unit_of_measure, min_order_quantity, max_order_quantity, notes, created_at, updated_at, version",
    )
    .eq("price_list_id", listId)
    .order("created_at", { ascending: true });

  if (itemsError) {
    console.error("get_price_list:items", itemsError);
    return { list, items: [] };
  }

  return { list, items: (items ?? []) as PriceListItemRow[] };
}
