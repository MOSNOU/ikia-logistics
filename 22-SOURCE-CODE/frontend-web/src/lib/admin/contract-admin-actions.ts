"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface ContractAdminActionState {
  error?: string;
  ok?: boolean;
}

function revalidateAdmin(id: string) {
  revalidatePath("/admin/contracts");
  revalidatePath(`/admin/contracts/${id}`);
  revalidatePath("/buyer/contracts");
  revalidatePath("/supplier/contracts");
}

export async function adminForceCancelPreparation(
  _prev: ContractAdminActionState | null,
  formData: FormData,
): Promise<ContractAdminActionState> {
  const id = String(formData.get("preparationId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("admin_force_cancel_preparation", { p_preparation_id: id, p_reason: reason });
  if (error) {
    console.error("admin_force_cancel_preparation", error);
    return { error: "لغو اضطراری ناموفق بود" };
  }
  revalidateAdmin(id);
  return { ok: true };
}

export async function adminSupersedePreparation(
  _prev: ContractAdminActionState | null,
  formData: FormData,
): Promise<ContractAdminActionState> {
  const id = String(formData.get("preparationId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("admin_supersede_preparation", { p_preparation_id: id, p_reason: reason });
  if (error) {
    console.error("admin_supersede_preparation", error);
    return { error: "جایگزینی ناموفق بود" };
  }
  revalidateAdmin(id);
  return { ok: true };
}

export async function adminForceCancelContract(
  _prev: ContractAdminActionState | null,
  formData: FormData,
): Promise<ContractAdminActionState> {
  const id = String(formData.get("contractId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("admin_force_cancel_contract", { p_contract_id: id, p_reason: reason });
  if (error) {
    console.error("admin_force_cancel_contract", error);
    return { error: "لغو اضطراری ناموفق بود" };
  }
  revalidateAdmin(id);
  return { ok: true };
}

export async function adminSupersedeContract(
  _prev: ContractAdminActionState | null,
  formData: FormData,
): Promise<ContractAdminActionState> {
  const id = String(formData.get("contractId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("admin_supersede_contract", { p_contract_id: id, p_reason: reason });
  if (error) {
    console.error("admin_supersede_contract", error);
    return { error: "جایگزینی ناموفق بود" };
  }
  revalidateAdmin(id);
  return { ok: true };
}

export async function adminVoidContract(
  _prev: ContractAdminActionState | null,
  formData: FormData,
): Promise<ContractAdminActionState> {
  const id = String(formData.get("contractId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("admin_void_contract", { p_contract_id: id, p_reason: reason });
  if (error) {
    console.error("admin_void_contract", error);
    return { error: "ابطال قرارداد ناموفق بود" };
  }
  revalidateAdmin(id);
  return { ok: true };
}
