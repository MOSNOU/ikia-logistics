"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface AddMembershipState {
  error?: string;
}

export async function addMembership(
  _prev: AddMembershipState | null,
  formData: FormData,
): Promise<AddMembershipState> {
  const organizationId = String(formData.get("organizationId") ?? "");
  const userId = String(formData.get("userId") ?? "");
  const roleCode = String(formData.get("roleCode") ?? "");

  if (!organizationId || !userId || !roleCode) {
    return { error: "همه فیلدها الزامی هستند" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("identity")
    .rpc("admin_add_membership", {
      p_organization_id: organizationId,
      p_user_id: userId,
      p_role_code: roleCode,
    });

  if (error) {
    console.error("admin_add_membership", error);
    return { error: "افزودن عضو ناموفق بود" };
  }

  revalidatePath(`/admin/organizations/${organizationId}`);
  redirect(`/admin/organizations/${organizationId}`);
}
