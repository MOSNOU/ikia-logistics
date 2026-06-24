import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { getSettlement } from "@/lib/settlement/get-settlement";
import { SupplierSettlementActions } from "./supplier-settlement-actions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function SupplierSettlementDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getSettlement(id, "supplier");
  if (!detail) notFound();
  const { settlement } = detail;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{settlement.settlement_code}</h1>
          <p className="text-sm text-muted-foreground">
            <Badge variant="outline">{settlement.currency}</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{settlement.status}</Badge>
            {" · "}
            اختلاف: <Badge variant="outline">{settlement.dispute_status ?? "—"}</Badge>
          </p>
        </div>
        <SupplierSettlementActions
          settlementId={settlement.id}
          status={settlement.status}
        />
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">مبلغ مصوب</div>
            <div className="text-lg font-semibold">
              {Number(settlement.planned_amount).toLocaleString("fa-IR")} {settlement.currency}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">آزادشده</div>
            <div className="text-lg font-semibold">
              {Number(settlement.released_amount).toLocaleString("fa-IR")} {settlement.currency}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">قرارداد</div>
            <div className="font-mono text-xs">{settlement.executed_contract_id ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">محموله</div>
            <div className="font-mono text-xs">{settlement.shipment_id ?? "—"}</div>
          </div>
          {settlement.settlement_terms ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">شرایط تسویه</div>
              <div>{settlement.settlement_terms}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>
    </div>
  );
}
