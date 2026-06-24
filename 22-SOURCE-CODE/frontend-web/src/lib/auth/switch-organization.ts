"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export async function switchOrganization(
  _prevState: { error?: string } | null,
  formData: FormData,
): Promise<{ error?: string }> {
  const orgId = String(formData.get("organizationId") ?? "");
  if (!orgId) return { error: "سازمان انتخاب نشده است" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: membership } = await supabase
    .schema("organization")
    .from("memberships")
    .select("id")
    .eq("user_id", user.id)
    .eq("organization_id", orgId)
    .eq("status", "active")
    .is("deleted_at", null)
    .maybeSingle();

  if (!membership) {
    return { error: "شما عضو این سازمان نیستید" };
  }

  const { error: updateError } = await supabase
    .schema("identity")
    .from("user_profiles")
    .update({ primary_organization_id: orgId })
    .eq("id", user.id);

  if (updateError) {
    return { error: "تغییر سازمان ناموفق بود" };
  }

  await supabase.auth.refreshSession();

  revalidatePath("/", "layout");
  redirect("/dashboard");
}
