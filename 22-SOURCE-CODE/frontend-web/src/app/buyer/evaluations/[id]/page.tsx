import Link from "next/link";
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
import { Button } from "@/components/ui/button";
import { getEvaluation } from "@/lib/evaluation/get-evaluation";
import { EvaluationStatusActions } from "./evaluation-status-actions";
import { UpsertScoreForm } from "./upsert-score-form";
import { RemoveScoreButton } from "./remove-score-button";
import { NotesForm } from "./notes-form";
import { DecisionActions } from "./decision-actions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerEvaluationDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getEvaluation(id, "buyer");
  if (!detail) notFound();

  const { evaluation, scores, decisions } = detail;
  const editable = evaluation.status === "draft" || evaluation.status === "in_review";
  const canComplete = editable && (scores?.length ?? 0) > 0;
  const canDecide = evaluation.status === "completed";

  // Q9=A: advisory weighted-total computed client-side.
  const advisoryTotal = (scores ?? []).reduce((sum, s) => {
    const w = s.weighted_score;
    if (w == null) return sum;
    return sum + Number(w);
  }, 0);

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">ارزیابی پیشنهاد</h1>
          <p className="text-sm text-muted-foreground">
            RFQ:{" "}
            <Link href={`/buyer/rfqs/${evaluation.request_id}`} className="font-mono text-xs underline">
              {evaluation.request_id}
            </Link>
            {" · "}
            پیشنهاد: <span className="font-mono text-xs">{evaluation.offer_id}</span>
            {" · "}
            وضعیت: <Badge variant="outline">{evaluation.status}</Badge>
          </p>
        </div>
        <EvaluationStatusActions
          evaluationId={evaluation.id}
          canComplete={canComplete}
          canCancel={editable}
        />
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
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
          <div className="md:col-span-3">
            <div className="text-muted-foreground">امتیاز وزنی تجمعی (محاسبه محلی)</div>
            <div className="text-lg font-semibold">{advisoryTotal.toLocaleString("fa-IR")}</div>
          </div>
        </CardContent>
      </Card>

      {editable ? (
        <NotesForm
          evaluationId={evaluation.id}
          defaults={{
            overallNotes: evaluation.overall_notes ?? "",
            commercialNotes: evaluation.commercial_notes ?? "",
            technicalNotes: evaluation.technical_notes ?? "",
            riskNotes: evaluation.risk_notes ?? "",
          }}
        />
      ) : (
        <Card>
          <CardContent className="p-6 space-y-3 text-sm">
            {evaluation.overall_notes ? (
              <div>
                <div className="text-muted-foreground">یادداشت کلی</div>
                <div>{evaluation.overall_notes}</div>
              </div>
            ) : null}
            {evaluation.commercial_notes ? (
              <div>
                <div className="text-muted-foreground">یادداشت تجاری</div>
                <div>{evaluation.commercial_notes}</div>
              </div>
            ) : null}
            {evaluation.technical_notes ? (
              <div>
                <div className="text-muted-foreground">یادداشت فنی</div>
                <div>{evaluation.technical_notes}</div>
              </div>
            ) : null}
            {evaluation.risk_notes ? (
              <div>
                <div className="text-muted-foreground">یادداشت ریسک</div>
                <div>{evaluation.risk_notes}</div>
              </div>
            ) : null}
          </CardContent>
        </Card>
      )}

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
                  <TableHead>عملیات</TableHead>
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
                    <TableCell>
                      {editable ? (
                        <RemoveScoreButton scoreId={s.id} evaluationId={evaluation.id} />
                      ) : (
                        <span className="text-xs text-muted-foreground">قفل‌شده</span>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {editable ? (
          <div className="mt-4">
            <h3 className="text-sm font-medium mb-2">افزودن / به‌روزرسانی امتیاز</h3>
            <UpsertScoreForm evaluationId={evaluation.id} />
          </div>
        ) : null}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">تصمیمات ({decisions?.length ?? 0})</h2>
        {!decisions || decisions.length === 0 ? (
          <TableEmpty>هنوز تصمیمی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نتیجه</TableHead>
                  <TableHead>دلیل</TableHead>
                  <TableHead>یادداشت</TableHead>
                  <TableHead>زمان</TableHead>
                  <TableHead>کاربر</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {decisions.map((d) => (
                  <TableRow key={d.id}>
                    <TableCell><Badge variant="outline">{d.decision_status}</Badge></TableCell>
                    <TableCell className="text-xs">{d.reason ?? "—"}</TableCell>
                    <TableCell className="text-xs">{d.decision_notes ?? "—"}</TableCell>
                    <TableCell className="text-xs">{d.decided_at}</TableCell>
                    <TableCell className="font-mono text-xs">{d.decided_by ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {canDecide ? (
          <div className="mt-4">
            <h3 className="text-sm font-medium mb-2">ثبت تصمیم برای این پیشنهاد</h3>
            <DecisionActions offerId={evaluation.offer_id} evaluationId={evaluation.id} />
          </div>
        ) : null}
      </div>

      <div>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/evaluations">بازگشت به فهرست</Link>
        </Button>
      </div>
    </div>
  );
}
