import { createClient } from "@/lib/supabase/server";
import type {
  ChannelType,
  DeliveryAttemptRow,
  DeliveryStatus,
} from "@/types/database";

export interface ListDeliveryAttemptsParams {
  notificationId?: string | null;
  channel?: ChannelType | null;
  status?: DeliveryStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListDeliveryAttemptsResult {
  rows: DeliveryAttemptRow[];
  page: number;
  pageSize: number;
}

export async function listDeliveryAttempts({
  notificationId = null,
  channel = null,
  status = null,
  page = 0,
  pageSize = 25,
}: ListDeliveryAttemptsParams = {}): Promise<ListDeliveryAttemptsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("notify")
    .rpc("admin_list_delivery_attempts", {
      p_notification_id: notificationId ?? undefined,
      p_channel: channel ?? undefined,
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_delivery_attempts", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as DeliveryAttemptRow[],
    page,
    pageSize,
  };
}
