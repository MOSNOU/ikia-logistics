import { createClient } from "@/lib/supabase/server";
import type {
  KycSubjectType,
  KycStatus,
  KycVerificationListRow,
} from "@/types/database";

export interface ListKycVerificationsParams {
  subjectType: KycSubjectType;
  status?: KycStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListKycVerificationsResult {
  rows: KycVerificationListRow[];
  page: number;
  pageSize: number;
}

export async function listKycVerifications({
  subjectType,
  status = null,
  page = 0,
  pageSize = 25,
}: ListKycVerificationsParams): Promise<ListKycVerificationsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("kyc")
    .rpc("admin_list_verifications", {
      p_subject_type: subjectType,
      p_status_filter: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_verifications", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as KycVerificationListRow[],
    page,
    pageSize,
  };
}
