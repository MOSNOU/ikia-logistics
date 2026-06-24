import { createClient } from "@/lib/supabase/server";
import type {
  NotificationCategory,
  NotificationInboxRow,
  NotificationStatus,
} from "@/types/database";

export interface ListMyNotificationsParams {
  status?: NotificationStatus | null;
  category?: NotificationCategory | null;
  page?: number;
  pageSize?: number;
}

export interface ListMyNotificationsResult {
  rows: NotificationInboxRow[];
  page: number;
  pageSize: number;
}

export async function listMyNotifications({
  status = null,
  category = null,
  page = 0,
  pageSize = 25,
}: ListMyNotificationsParams = {}): Promise<ListMyNotificationsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("notify")
    .rpc("portal_list_my_notifications", {
      p_status: status ?? undefined,
      p_category: category ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("portal_list_my_notifications", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as NotificationInboxRow[],
    page,
    pageSize,
  };
}
