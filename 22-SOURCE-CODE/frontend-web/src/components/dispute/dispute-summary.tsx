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
import type { DisputeDetail } from "@/types/database";

export function DisputeSummary({ detail }: { detail: DisputeDetail }) {
  const { dispute, evidence, decisions, events } = detail;
  return (
    <>
      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">تسویه</div>
            <div className="font-mono text-xs">{dispute.settlement_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">سازمان</div>
            <div className="font-mono text-xs">{dispute.organization_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تأمین‌کننده</div>
            <div className="font-mono text-xs">{dispute.supplier_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">باز شده توسط</div>
            <div><Badge variant="outline">{dispute.opened_by_party}</Badge></div>
          </div>
          <div>
            <div className="text-muted-foreground">مبلغ اختلاف</div>
            <div>
              {Number(dispute.amount_in_dispute).toLocaleString("fa-IR")} {dispute.currency}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">میانجی</div>
            <div className="font-mono text-xs">{dispute.assigned_mediator_id ?? "—"}</div>
          </div>
          {dispute.description ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">توضیحات</div>
              <div>{dispute.description}</div>
            </div>
          ) : null}
          {dispute.decision_reason ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">دلیل تصمیم</div>
              <div>{dispute.decision_reason}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">مدارک ({evidence?.length ?? 0})</h2>
        {!evidence || evidence.length === 0 ? (
          <TableEmpty>مدرکی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>عنوان</TableHead>
                  <TableHead>نوع</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>طرف</TableHead>
                  <TableHead>زمان</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {evidence.map((e) => (
                  <TableRow key={e.id}>
                    <TableCell>{e.title}</TableCell>
                    <TableCell><Badge variant="outline">{e.evidence_kind}</Badge></TableCell>
                    <TableCell><Badge variant="outline">{e.status}</Badge></TableCell>
                    <TableCell><Badge variant="outline">{e.submitter_party_role}</Badge></TableCell>
                    <TableCell className="text-xs">{e.created_at}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">تصمیمات ({decisions?.length ?? 0})</h2>
        {!decisions || decisions.length === 0 ? (
          <TableEmpty>تصمیمی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نتیجه</TableHead>
                  <TableHead>اقدام تسویه</TableHead>
                  <TableHead>سهم خریدار</TableHead>
                  <TableHead>سهم تأمین‌کننده</TableHead>
                  <TableHead>ابطال‌شده در</TableHead>
                  <TableHead>زمان</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {decisions.map((d) => (
                  <TableRow key={d.id}>
                    <TableCell><Badge variant="outline">{d.outcome}</Badge></TableCell>
                    <TableCell><Badge variant="outline">{d.settlement_action}</Badge></TableCell>
                    <TableCell>{Number(d.buyer_share_amount).toLocaleString("fa-IR")}</TableCell>
                    <TableCell>{Number(d.supplier_share_amount).toLocaleString("fa-IR")}</TableCell>
                    <TableCell className="text-xs">{d.voided_at ?? "—"}</TableCell>
                    <TableCell className="text-xs">{d.created_at}</TableCell>
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
    </>
  );
}
