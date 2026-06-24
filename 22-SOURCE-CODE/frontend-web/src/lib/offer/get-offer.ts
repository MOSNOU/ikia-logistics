import { createClient } from "@/lib/supabase/server";
import type { OfferDetail } from "@/types/database";

export type OfferAudience = "buyer" | "supplier" | "admin";

export async function getOffer(
  offerId: string,
  audience: OfferAudience,
): Promise<OfferDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_offer"
      : audience === "supplier"
        ? "supplier_get_my_offer"
        : "admin_get_offer";

  const { data, error } = await supabase
    .schema("offer")
    .rpc(rpc, { p_offer_id: offerId });
  if (error) {
    console.error(rpc, error);
    return null;
  }
  if (!data) return null;
  return data as unknown as OfferDetail;
}
