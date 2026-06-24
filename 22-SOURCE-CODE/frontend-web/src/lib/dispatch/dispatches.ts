import { createClient } from "@/lib/supabase/server";
import type {
  DispatchDetail,
  DispatchListRow,
  DispatchStatus,
} from "@/types/database";

export type DispatchAudience = "buyer" | "carrier" | "admin";

export interface ListDispatchesParams {
  status?: DispatchStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListDispatchesResult {
  rows: DispatchListRow[];
  page: number;
  pageSize: number;
}

export async function listDispatches(
  audience: DispatchAudience,
  { status = null, page = 0, pageSize = 25 }: ListDispatchesParams = {},
): Promise<ListDispatchesResult> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_list_my_dispatches"
      : audience === "carrier"
        ? "carrier_list_my_dispatches"
        : "admin_list_dispatches";
  const { data, error } = await supabase
    .schema("dispatch")
    .rpc(rpc, {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error(`dispatch.${rpc}`, error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as DispatchListRow[],
    page,
    pageSize,
  };
}

export async function getDispatch(
  dispatchId: string,
  audience: DispatchAudience,
): Promise<DispatchDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_dispatch"
      : audience === "carrier"
        ? "carrier_get_dispatch"
        : "admin_get_dispatch";
  const { data, error } = await supabase
    .schema("dispatch")
    .rpc(rpc, { p_dispatch_id: dispatchId });
  if (error || !data) {
    if (error) console.error(`dispatch.${rpc}`, error);
    return null;
  }
  return data as unknown as DispatchDetail;
}
