import { createClient } from "@/lib/supabase/server";
import type { OfferStatusEventRow } from "@/types/database";

export async function listOfferEvents(
  offerId: string,
): Promise<OfferStatusEventRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("offer")
    .rpc("admin_list_offer_status_events", { p_offer_id: offerId });
  if (error) {
    console.error("admin_list_offer_status_events", error);
    return [];
  }
  return (data ?? []) as unknown as OfferStatusEventRow[];
}
