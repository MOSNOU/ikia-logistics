import { createClient } from "@/lib/supabase/server";
import type { KycOrganizationDetail } from "@/types/database";

export async function getMyOrganizationVerification(
  organizationId: string,
): Promise<KycOrganizationDetail> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("kyc")
    .rpc("get_my_organization_verification", { p_organization_id: organizationId });

  if (error) {
    console.error("get_my_organization_verification", error);
    return { status: "not_started" };
  }
  return (data ?? { status: "not_started" }) as unknown as KycOrganizationDetail;
}
