import { createClient } from "@/lib/supabase/server";
import type { KycPersonalDetail } from "@/types/database";

export async function getMyPersonalVerification(): Promise<KycPersonalDetail> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("kyc")
    .rpc("get_my_personal_verification");

  if (error) {
    console.error("get_my_personal_verification", error);
    return { status: "not_started" };
  }
  return (data ?? { status: "not_started" }) as unknown as KycPersonalDetail;
}
