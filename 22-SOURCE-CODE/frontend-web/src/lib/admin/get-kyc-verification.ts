import { createClient } from "@/lib/supabase/server";
import type {
  KycSubjectType,
  KycVerificationAdminDetail,
} from "@/types/database";

export async function getAdminKycVerification(
  verificationId: string,
  subjectType: KycSubjectType,
): Promise<KycVerificationAdminDetail | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("kyc")
    .rpc("admin_get_verification", {
      p_verification_id: verificationId,
      p_subject_type: subjectType,
    });
  if (error) {
    console.error("admin_get_verification", error);
    return null;
  }
  if (!data) return null;
  return data as unknown as KycVerificationAdminDetail;
}
