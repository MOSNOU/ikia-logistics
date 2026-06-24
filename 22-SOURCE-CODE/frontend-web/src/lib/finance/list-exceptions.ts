import { createClient } from "@/lib/supabase/server";
import type { FinanceExceptionRow } from "@/types/database";

// Admin exception synthesis. Direct SELECTs on settlements + escrow accounts
// scoped by status. No backend RPC. Combined client-side and sorted by
// updated_at desc. Capped at 100 rows to keep the page snappy.
export async function listAdminFinanceExceptions(): Promise<FinanceExceptionRow[]> {
  const supabase = await createClient();
  const rows: FinanceExceptionRow[] = [];

  const { data: settlementRows, error: setErr } = await supabase
    .schema("settlement")
    .from("settlements")
    .select(
      "id, settlement_code, organization_id, supplier_id, currency, planned_amount, held_amount, released_amount, status, dispute_status, updated_at",
    )
    .is("deleted_at", null)
    .in("status", ["holding", "disputed"])
    .order("updated_at", { ascending: false })
    .limit(80);
  if (setErr) {
    console.error("exceptions: settlements", setErr);
  } else {
    for (const s of (settlementRows ?? []) as Array<{
      id: string;
      settlement_code: string;
      organization_id: string;
      supplier_id: string | null;
      currency: string;
      planned_amount: number | null;
      held_amount: number | null;
      released_amount: number | null;
      status: string;
      dispute_status: string | null;
      updated_at: string;
    }>) {
      const held = Number(s.held_amount ?? 0);
      const planned = Number(s.planned_amount ?? 0);
      if (s.status === "disputed") {
        rows.push({
          kind: "settlement_disputed",
          subject_id: s.id,
          subject_code: s.settlement_code,
          organization_id: s.organization_id,
          supplier_id: s.supplier_id,
          currency: s.currency,
          amount: planned,
          status_label: "تسویه در منازعه",
          updated_at: s.updated_at,
          detail_href: `/admin/finance/settlements/${s.id}`,
        });
      } else if (s.status === "holding" && held > 0) {
        rows.push({
          kind: "settlement_held_with_balance",
          subject_id: s.id,
          subject_code: s.settlement_code,
          organization_id: s.organization_id,
          supplier_id: s.supplier_id,
          currency: s.currency,
          amount: held,
          status_label: "تسویه بلوکه با مانده",
          updated_at: s.updated_at,
          detail_href: `/admin/finance/settlements/${s.id}`,
        });
      }
    }
  }

  const { data: escrowRows, error: escErr } = await supabase
    .schema("settlement")
    .from("escrow_accounts")
    .select(
      "id, account_code, organization_id, supplier_id, currency, available_balance, total_held, status, updated_at",
    )
    .is("deleted_at", null)
    .in("status", ["frozen", "closed"])
    .order("updated_at", { ascending: false })
    .limit(80);
  if (escErr) {
    console.error("exceptions: escrow", escErr);
  } else {
    for (const e of (escrowRows ?? []) as Array<{
      id: string;
      account_code: string;
      organization_id: string;
      supplier_id: string | null;
      currency: string;
      available_balance: number | null;
      total_held: number | null;
      status: string;
      updated_at: string;
    }>) {
      const avail = Number(e.available_balance ?? 0);
      const held = Number(e.total_held ?? 0);
      if (e.status === "frozen") {
        rows.push({
          kind: "escrow_frozen",
          subject_id: e.id,
          subject_code: e.account_code,
          organization_id: e.organization_id,
          supplier_id: e.supplier_id,
          currency: e.currency,
          amount: avail + held,
          status_label: "حساب امانی فریز شده",
          updated_at: e.updated_at,
          detail_href: `/admin/finance#escrow-${e.id}`,
        });
      } else if (e.status === "closed" && (avail + held) > 0) {
        rows.push({
          kind: "escrow_closed_with_balance",
          subject_id: e.id,
          subject_code: e.account_code,
          organization_id: e.organization_id,
          supplier_id: e.supplier_id,
          currency: e.currency,
          amount: avail + held,
          status_label: "حساب امانی بسته با مانده",
          updated_at: e.updated_at,
          detail_href: `/admin/finance#escrow-${e.id}`,
        });
      }
    }
  }

  rows.sort((a, b) => b.updated_at.localeCompare(a.updated_at));
  return rows.slice(0, 100);
}
