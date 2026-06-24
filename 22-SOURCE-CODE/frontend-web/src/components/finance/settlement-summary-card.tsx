import { Card, CardContent } from "@/components/ui/card";
import { AmountCell } from "./amount-cell";
import { FinanceStatusBadge } from "./status-badge";
import type { SettlementDetail } from "@/types/database";

interface Props {
  detail: SettlementDetail;
}

export function SettlementSummaryCard({ detail }: Props) {
  const s = detail.settlement;
  return (
    <Card>
      <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
        <div>
          <div className="text-muted-foreground">کد تسویه</div>
          <div className="font-mono text-xs">{s.settlement_code}</div>
        </div>
        <div>
          <div className="text-muted-foreground">وضعیت</div>
          <div><FinanceStatusBadge status={s.status} domain="settlement" /></div>
        </div>
        <div>
          <div className="text-muted-foreground">ارز</div>
          <div className="font-mono text-xs">{s.currency}</div>
        </div>
        <div>
          <div className="text-muted-foreground">مبلغ برنامه‌ریزی‌شده</div>
          <AmountCell value={s.planned_amount} currency={s.currency} />
        </div>
        <div>
          <div className="text-muted-foreground">بلوکه</div>
          <AmountCell value={s.held_amount} currency={s.currency} />
        </div>
        <div>
          <div className="text-muted-foreground">آزاد شده</div>
          <AmountCell value={s.released_amount} currency={s.currency} />
        </div>
        {s.fees_amount != null ? (
          <div>
            <div className="text-muted-foreground">کارمزد</div>
            <AmountCell value={s.fees_amount} currency={s.currency} />
          </div>
        ) : null}
        {s.platform_fee_amount != null ? (
          <div>
            <div className="text-muted-foreground">کارمزد پلتفرم</div>
            <AmountCell value={s.platform_fee_amount} currency={s.currency} />
          </div>
        ) : null}
        <div>
          <div className="text-muted-foreground">حساب امانی</div>
          <div className="font-mono text-xs">{s.escrow_account_id ?? "—"}</div>
        </div>
        <div>
          <div className="text-muted-foreground">قرارداد اجرایی</div>
          <div className="font-mono text-xs">{s.executed_contract_id ?? "—"}</div>
        </div>
        <div>
          <div className="text-muted-foreground">شیپمنت</div>
          <div className="font-mono text-xs">{s.shipment_id ?? "—"}</div>
        </div>
        <div>
          <div className="text-muted-foreground">به‌روزرسانی</div>
          <div className="text-xs">{s.updated_at}</div>
        </div>
        {s.settlement_terms ? (
          <div className="md:col-span-3">
            <div className="text-muted-foreground">شرایط تسویه</div>
            <div className="text-xs whitespace-pre-line">{s.settlement_terms}</div>
          </div>
        ) : null}
        {s.notes ? (
          <div className="md:col-span-3">
            <div className="text-muted-foreground">یادداشت</div>
            <div className="text-xs whitespace-pre-line">{s.notes}</div>
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
}
