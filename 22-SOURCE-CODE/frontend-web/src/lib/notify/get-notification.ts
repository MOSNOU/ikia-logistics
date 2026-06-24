import { createClient } from "@/lib/supabase/server";
import type { NotificationDetail } from "@/types/database";

export async function getNotification(
  notificationId: string,
): Promise<NotificationDetail | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("notify")
    .rpc("portal_get_notification", { p_notification_id: notificationId });
  if (error) {
    console.error("portal_get_notification", error);
    return null;
  }
  if (!data) return null;
  return data as unknown as NotificationDetail;
}
