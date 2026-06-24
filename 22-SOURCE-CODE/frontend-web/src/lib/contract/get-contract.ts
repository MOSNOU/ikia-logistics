import { createClient } from "@/lib/supabase/server";
import type {
  ContractPreparationDetail,
  ExecutedContractDetail,
} from "@/types/database";

export type ContractAudience = "buyer" | "supplier" | "admin";

export async function getPreparation(
  preparationId: string,
  audience: ContractAudience,
): Promise<ContractPreparationDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_preparation"
      : audience === "supplier"
        ? "supplier_get_my_preparation"
        : "admin_get_preparation";
  const { data, error } = await supabase
    .schema("contract")
    .rpc(rpc, { p_preparation_id: preparationId });
  if (error) {
    console.error(rpc, error);
    return null;
  }
  if (!data) return null;
  return data as unknown as ContractPreparationDetail;
}

export async function getExecutedContract(
  contractId: string,
  audience: ContractAudience,
): Promise<ExecutedContractDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_executed_contract"
      : audience === "supplier"
        ? "supplier_get_my_executed_contract"
        : "admin_get_executed_contract";
  const { data, error } = await supabase
    .schema("contract")
    .rpc(rpc, { p_contract_id: contractId });
  if (error) {
    console.error(rpc, error);
    return null;
  }
  if (!data) return null;
  return data as unknown as ExecutedContractDetail;
}

// Q5=A: a single /buyer/contracts/[id] URL accepts either a preparation or an
// executed-contract id. This helper tries preparation first, then executed.
export interface UnifiedContract {
  kind: "preparation" | "executed";
  preparation?: ContractPreparationDetail;
  executed?: ExecutedContractDetail;
}

export async function getContractUnified(
  id: string,
  audience: ContractAudience,
): Promise<UnifiedContract | null> {
  const prep = await getPreparation(id, audience);
  if (prep) return { kind: "preparation", preparation: prep };
  const exec = await getExecutedContract(id, audience);
  if (exec) return { kind: "executed", executed: exec };
  return null;
}
