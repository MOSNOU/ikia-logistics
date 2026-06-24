import type {
  AdminEscrowAccountRow,
  AdminSettlementListRow,
  BuyerSettlementListRow,
  FinanceKpiBundle,
  InvoiceSummaryRow,
  OrgEscrowAccountRow,
  SupplierSettlementListRow,
} from "@/types/database";

type AnySettlementRow =
  | BuyerSettlementListRow
  | SupplierSettlementListRow
  | AdminSettlementListRow;

function pickCurrency(items: { currency?: string }[]): string | null {
  for (const i of items) {
    if (i.currency) return i.currency;
  }
  return null;
}

function safeNum(v: number | null | undefined): number {
  return typeof v === "number" && Number.isFinite(v) ? v : 0;
}

function isOverdue(inv: InvoiceSummaryRow, today: string): boolean {
  if (!inv.due_date) return false;
  if (inv.status === "paid" || inv.status === "cancelled" || inv.status === "voided") {
    return false;
  }
  return inv.due_date < today && safeNum(inv.paid_amount) < safeNum(inv.total_amount);
}

export function computeFinanceKpis(opts: {
  invoices: InvoiceSummaryRow[];
  settlements: AnySettlementRow[];
  escrowAccounts: OrgEscrowAccountRow[] | AdminEscrowAccountRow[];
}): FinanceKpiBundle {
  const today = new Date().toISOString().slice(0, 10);

  const invTotal = opts.invoices.reduce((s, i) => s + safeNum(i.total_amount), 0);
  const invPaid = opts.invoices.reduce((s, i) => s + safeNum(i.paid_amount), 0);
  const invOverdueCount = opts.invoices.filter((i) => isOverdue(i, today)).length;

  const setPlanned = opts.settlements.reduce(
    (s, x) => s + safeNum((x as { planned_amount?: number }).planned_amount),
    0,
  );
  const setHeld = opts.settlements.reduce(
    (s, x) => s + safeNum((x as { held_amount?: number }).held_amount),
    0,
  );
  const setReleased = opts.settlements.reduce(
    (s, x) => s + safeNum((x as { released_amount?: number }).released_amount),
    0,
  );
  const setHoldCount = opts.settlements.filter(
    (x) => (x as { status: string }).status === "holding",
  ).length;

  const escAvail = opts.escrowAccounts.reduce(
    (s, x) => s + safeNum((x as { available_balance?: number }).available_balance),
    0,
  );
  const escHeld = opts.escrowAccounts.reduce(
    (s, x) => s + safeNum((x as { total_held?: number }).total_held),
    0,
  );
  const escFrozenCount = opts.escrowAccounts.filter(
    (x) => (x as { status: string }).status === "frozen",
  ).length;

  const currency =
    pickCurrency(opts.invoices) ??
    pickCurrency(opts.settlements) ??
    pickCurrency(opts.escrowAccounts);

  return {
    currency,
    invoices: {
      count: opts.invoices.length,
      totalAmount: invTotal,
      paidAmount: invPaid,
      outstandingAmount: Math.max(invTotal - invPaid, 0),
      overdueCount: invOverdueCount,
    },
    settlements: {
      count: opts.settlements.length,
      plannedAmount: setPlanned,
      heldAmount: setHeld,
      releasedAmount: setReleased,
      holdCount: setHoldCount,
    },
    escrow: {
      accountCount: opts.escrowAccounts.length,
      availableBalance: escAvail,
      totalHeld: escHeld,
      frozenCount: escFrozenCount,
    },
  };
}
