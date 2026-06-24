import { createClient } from "@/lib/supabase/server";
import type {
  AdminNotificationRow,
  NotificationCategory,
} from "@/types/database";

export interface ListAdminNotificationsParams {
  recipientUserId?: string | null;
  organizationId?: string | null;
  category?: NotificationCategory | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminNotificationsResult {
  rows: AdminNotificationRow[];
  page: number;
  pageSize: number;
}

export async function listAdminNotifications({
  recipientUserId = null,
  organizationId = null,
  category = null,
  page = 0,
  pageSize = 25,
}: ListAdminNotificationsParams = {}): Promise<ListAdminNotificationsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("notify")
    .rpc("admin_list_notifications", {
      p_recipient_user_id: recipientUserId ?? undefined,
      p_organization_id: organizationId ?? undefined,
      p_category: category ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_notifications", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as AdminNotificationRow[],
    page,
    pageSize,
  };
}
