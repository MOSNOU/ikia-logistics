import { createClient } from "@/lib/supabase/server";
import type { MarketplaceActivityRow } from "@/types/database";

interface AdminActivityRow {
  event_id: string;
  capacity_listing_id: string;
  carrier_organization_id: string;
  from_status: string | null;
  to_status: string;
  reason: string | null;
  actor_user_id: string | null;
  created_at: string;
}

// CC-40: backed by marketplace.admin_list_activity over the real
// capacity_status_events ledger. Each event becomes a Persian-labelled row.
// Only `published` (to_status=active) and `archived` events are surfaced
// because Q8 keeps the lifecycle-event vocabulary minimal.
export async function listMarketplaceActivity(): Promise<MarketplaceActivityRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("admin_list_activity", { p_limit: 50, p_offset: 0 });
  if (error) {
    console.error("marketplace.admin_list_activity", error);
    return [];
  }
  const rows = (data ?? []) as unknown as AdminActivityRow[];
  const out: MarketplaceActivityRow[] = [];
  for (const e of rows) {
    if (e.to_status === "active") {
      out.push({
        id: e.event_id,
        kind: "capacity_published",
        subject: e.capacity_listing_id,
        description: `انتشار ظرفیت — حمل‌کننده: ${e.carrier_organization_id}`,
        href: undefined,
        created_at: e.created_at,
      });
    } else if (e.to_status === "archived") {
      out.push({
        id: e.event_id,
        kind: "capacity_archived",
        subject: e.capacity_listing_id,
        description:
          e.reason && e.reason.trim()
            ? `بایگانی ظرفیت — دلیل: ${e.reason}`
            : "بایگانی ظرفیت",
        href: undefined,
        created_at: e.created_at,
      });
    }
  }
  return out.slice(0, 30);
}
