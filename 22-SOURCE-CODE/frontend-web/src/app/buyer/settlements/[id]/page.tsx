import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getSettlement } from "@/lib/settlement/get-settlement";
import { BuyerSettlementActions } from "./buyer-settlement-actions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerSettlementDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getSettlement(id, "buyer");
  if (!detail) notFound();
  const { settlement, items, events } = detail;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{settlement.settlement_code}</h1>
          <p className="text-sm text-muted-foreground">
            <Badge variant="outline">{settlement.currency}</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{settlement.status}</Badge>
          </p>
        </div>
        <BuyerSettlementActions
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
            <div className="text-muted-foreground">در اسکرو</div>
            <div className="text-lg font-semibold">
              {Number(settlement.held_amount).toLocaleString("fa-IR")} {settlement.currency}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">آزادشده</div>
            <div className="text-lg font-semibold">
              {Number(settlement.released_amount).toLocaleString("fa-IR")} {settlement.currency}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">حساب اسکرو</div>
            <div className="font-mono text-xs">{settlement.escrow_account_id ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">قرارداد اجراشده</div>
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

      <div>
        <h2 className="text-lg font-semibold mb-3">ردیف‌ها ({items?.length ?? 0})</h2>
        {!items || items.length === 0 ? (
          <TableEmpty>ردیفی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>توضیحات</TableHead>
                  <TableHead>مبلغ</TableHead>
                  <TableHead>کارمزدها</TableHead>
                  <TableHead>کارمزد پلتفرم</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((it) => (
                  <TableRow key={it.id}>
                    <TableCell>{it.description}</TableCell>
                    <TableCell>
                      {it.amount != null ? Number(it.amount).toLocaleString("fa-IR") : "—"}
                    </TableCell>
                    <TableCell>
                      {it.fees_amount != null ? Number(it.fees_amount).toLocaleString("fa-IR") : "—"}
                    </TableCell>
                    <TableCell>
                      {it.platform_fee_amount != null
                        ? Number(it.platform_fee_amount).toLocaleString("fa-IR")
                        : "—"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">رویدادها ({events?.length ?? 0})</h2>
        {!events || events.length === 0 ? (
          <TableEmpty>رویدادی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع</TableHead>
                  <TableHead>از</TableHead>
                  <TableHead>به</TableHead>
                  <TableHead>دلیل</TableHead>
                  <TableHead>زمان</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {events.map((e) => (
                  <TableRow key={e.id}>
                    <TableCell><Badge variant="outline">{e.event_type}</Badge></TableCell>
                    <TableCell className="text-xs">{e.from_status ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.to_status ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.reason ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.created_at}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>
    </div>
  );
}
