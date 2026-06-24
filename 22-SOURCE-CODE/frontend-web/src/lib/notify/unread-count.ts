import { createClient } from "@/lib/supabase/server";
import type { NotificationCategory } from "@/types/database";

export async function getUnreadCount(
  category: NotificationCategory | null = null,
): Promise<number> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("notify")
    .rpc("portal_unread_count", { p_category: category ?? undefined });
  if (error) {
    console.error("portal_unread_count", error);
    return 0;
  }
  return Number(data ?? 0);
}
