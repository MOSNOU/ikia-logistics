"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type {
  NotificationCategory,
  ChannelType,
} from "@/types/database";

export interface InboxActionState {
  error?: string;
  ok?: boolean;
  count?: number;
}

export async function markRead(
  _prev: InboxActionState | null,
  formData: FormData,
): Promise<InboxActionState> {
  const id = String(formData.get("notificationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("notify")
    .rpc("portal_mark_read", { p_notification_id: id });
  if (error) {
    console.error("portal_mark_read", error);
    return { error: "علامت‌گذاری ناموفق بود" };
  }
  revalidatePath("/inbox");
  revalidatePath(`/inbox/${id}`);
  return { ok: true };
}

export async function markAllRead(
  _prev: InboxActionState | null,
  formData: FormData,
): Promise<InboxActionState> {
  const categoryRaw = (formData.get("category") as string | null) || "";
  const category = (categoryRaw || undefined) as NotificationCategory | undefined;
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("notify")
    .rpc("portal_mark_all_read", { p_category: category });
  if (error) {
    console.error("portal_mark_all_read", error);
    return { error: "علامت‌گذاری گروهی ناموفق بود" };
  }
  revalidatePath("/inbox");
  return { ok: true, count: Number(data ?? 0) };
}

export async function archiveNotification(
  _prev: InboxActionState | null,
  formData: FormData,
): Promise<InboxActionState> {
  const id = String(formData.get("notificationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("notify")
    .rpc("portal_archive_notification", { p_notification_id: id });
  if (error) {
    console.error("portal_archive_notification", error);
    return { error: "بایگانی ناموفق بود" };
  }
  revalidatePath("/inbox");
  revalidatePath(`/inbox/${id}`);
  return { ok: true };
}

export async function upsertPreferences(
  _prev: InboxActionState | null,
  formData: FormData,
): Promise<InboxActionState> {
  const organizationId =
    (formData.get("organizationId") as string | null) || undefined;
  const supabase = await createClient();

  // Each pref is encoded as "pref:<category>:<channel>" = "on" | undefined.
  // The form sends all category/channel pairs the user toggled.
  const entries: Array<{
    category: NotificationCategory;
    channel: ChannelType;
    enabled: boolean;
  }> = [];

  for (const key of formData.keys()) {
    if (!key.startsWith("known:")) continue;
    const [, category, channel] = key.split(":") as [
      string,
      NotificationCategory,
      ChannelType,
    ];
    if (!category || !channel) continue;
    const enabled = formData.get(`pref:${category}:${channel}`) === "on";
    entries.push({ category, channel, enabled });
  }

  for (const { category, channel, enabled } of entries) {
    const { error } = await supabase
      .schema("notify")
      .rpc("portal_upsert_preferences", {
        p_category: category,
        p_channel: channel,
        p_enabled: enabled,
        p_organization_id: organizationId,
      });
    if (error) {
      console.error("portal_upsert_preferences", error);
      return { error: "ذخیره تنظیمات ناموفق بود" };
    }
  }

  revalidatePath("/inbox/preferences");
  return { ok: true };
}
