import { createClient } from "@/lib/supabase/server";
import type {
  AdminRfqInvitationRow,
  InvitationStatus,
} from "@/types/database";

export async function listRfqInvitations(
  requestId: string,
  status: InvitationStatus | null = null,
): Promise<AdminRfqInvitationRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("rfq")
    .rpc("admin_list_invitations", {
      p_request_id: requestId,
      p_status: status ?? undefined,
      p_limit: 200,
      p_offset: 0,
    });
  if (error) {
    console.error("admin_list_invitations", error);
    return [];
  }
  return (data ?? []) as unknown as AdminRfqInvitationRow[];
}
