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
import { getEvaluation } from "@/lib/evaluation/get-evaluation";
import { listAdminEvaluationDecisions } from "@/lib/admin/list-evaluation-decisions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminEvaluationDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getEvaluation(id, "admin");
  if (!detail) notFound();

  const { evaluation, scores } = detail;
  const offerDecisions = await listAdminEvaluationDecisions({
    offerId: evaluation.offer_id,
    pageSize: 50,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ارزیابی (مدیریت)</h1>
        <p className="text-sm text-muted-foreground">
          <span className="font-mono text-xs">{evaluation.id}</span>
          {" · "}
          وضعیت: <Badge variant="outline">{evaluation.status}</Badge>
        </p>
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">سازمان</div>
            <div className="font-mono text-xs">{evaluation.organization_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">RFQ</div>
            <div className="font-mono text-xs">{evaluation.request_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">پیشنهاد</div>
            <div className="font-mono text-xs">{evaluation.offer_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ارزیاب</div>
            <div className="font-mono text-xs">{evaluation.evaluator_user_id ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ایجاد</div>
            <div className="text-xs">{evaluation.created_at}</div>
          </div>
          <div>
            <div className="text-muted-foreground">به‌روزرسانی</div>
            <div className="text-xs">{evaluation.updated_at}</div>
          </div>
          {evaluation.overall_notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت کلی</div>
              <div>{evaluation.overall_notes}</div>
            </div>
          ) : null}
          {evaluation.commercial_notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت تجاری</div>
              <div>{evaluation.commercial_notes}</div>
            </div>
          ) : null}
          {evaluation.technical_notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت فنی</div>
              <div>{evaluation.technical_notes}</div>
            </div>
          ) : null}
          {evaluation.risk_notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت ریسک</div>
              <div>{evaluation.risk_notes}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">امتیازها ({scores?.length ?? 0})</h2>
        {!scores || scores.length === 0 ? (
          <TableEmpty>امتیازی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>بعد</TableHead>
                  <TableHead>امتیاز</TableHead>
                  <TableHead>حداکثر</TableHead>
                  <TableHead>وزن</TableHead>
                  <TableHead>وزنی</TableHead>
                  <TableHead>یادداشت</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {scores.map((s) => (
                  <TableRow key={s.id}>
                    <TableCell>{s.dimension}</TableCell>
                    <TableCell>{s.score_value ?? "—"}</TableCell>
                    <TableCell>{s.max_score ?? "—"}</TableCell>
                    <TableCell>{s.weight ?? "—"}</TableCell>
                    <TableCell>{s.weighted_score ?? "—"}</TableCell>
                    <TableCell className="text-xs">{s.notes ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">
          تصمیمات پیشنهاد ({offerDecisions.rows.length})
        </h2>
        {offerDecisions.rows.length === 0 ? (
          <TableEmpty>تصمیمی برای این پیشنهاد ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نتیجه</TableHead>
                  <TableHead>کاربر تصمیم‌گیرنده</TableHead>
                  <TableHead>زمان تصمیم</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {offerDecisions.rows.map((d) => (
                  <TableRow key={d.id}>
                    <TableCell><Badge variant="outline">{d.decision_status}</Badge></TableCell>
                    <TableCell className="font-mono text-xs">{d.decided_by ?? "—"}</TableCell>
                    <TableCell className="text-xs">{d.decided_at}</TableCell>
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
