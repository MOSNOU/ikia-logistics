import { createClient } from "@/lib/supabase/server";
import type {
  NotificationCategory,
  NotificationTemplateRow,
  TemplateStatus,
} from "@/types/database";

export interface ListNotificationTemplatesParams {
  category?: NotificationCategory | null;
  status?: TemplateStatus | null;
}

export async function listNotificationTemplates({
  category = null,
  status = null,
}: ListNotificationTemplatesParams = {}): Promise<NotificationTemplateRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("notify")
    .rpc("admin_list_templates", {
      p_category: category ?? undefined,
      p_status: status ?? undefined,
    });
  if (error) {
    console.error("admin_list_templates", error);
    return [];
  }
  return (data ?? []) as unknown as NotificationTemplateRow[];
}
