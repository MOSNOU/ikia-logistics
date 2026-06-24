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
import { getAdminKycVerification } from "@/lib/admin/get-kyc-verification";
import type { KycSubjectType } from "@/types/database";
import { VerificationActions } from "./verification-actions";
import { DocumentActions } from "./document-actions";
import { RiskFlagActions } from "./risk-flag-actions";

interface PageProps {
  params: Promise<{ subjectType: string; verificationId: string }>;
}

export default async function AdminKycDetailPage({ params }: PageProps) {
  const { subjectType: subjectParam, verificationId } = await params;
  if (subjectParam !== "person" && subjectParam !== "organization") notFound();
  const subjectType = subjectParam as KycSubjectType;

  const detail = await getAdminKycVerification(verificationId, subjectType);
  if (!detail) notFound();

  const { verification, documents, risk_flags: riskFlags, events } = detail;
  const status = verification.status;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">
            {subjectType === "person" ? "احراز هویت فردی" : "احراز هویت سازمان"}
          </h1>
          <p className="text-sm text-muted-foreground">
            تلاش <span className="font-mono">#{verification.attempt_no}</span>
            {" · "}
            وضعیت <Badge variant="outline">{status}</Badge>
          </p>
        </div>
        <VerificationActions
          verificationId={verification.id}
          subjectType={subjectType}
          status={status}
        />
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          {subjectType === "person" ? (
            <>
              <div>
                <div className="text-muted-foreground">نام کامل قانونی</div>
                <div>{verification.full_legal_name ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">۴ رقم آخر شناسه ملی</div>
                <div className="font-mono">{verification.national_id_last4 ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">تاریخ تولد</div>
                <div className="text-xs">{verification.date_of_birth ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">کشور</div>
                <div>{verification.country_code ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">شناسه کاربر</div>
                <div className="font-mono text-xs">{verification.user_id ?? "—"}</div>
              </div>
            </>
          ) : (
            <>
              <div>
                <div className="text-muted-foreground">نام قانونی</div>
                <div>{verification.legal_name ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">شماره ثبت</div>
                <div className="font-mono">{verification.registration_number ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">شناسه مالیاتی</div>
                <div className="font-mono">{verification.tax_id ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">کشور</div>
                <div>{verification.country_code ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">تاریخ تأسیس</div>
                <div className="text-xs">{verification.incorporated_on ?? "—"}</div>
              </div>
              <div>
                <div className="text-muted-foreground">شناسه سازمان</div>
                <div className="font-mono text-xs">{verification.organization_id ?? "—"}</div>
              </div>
            </>
          )}
          <div>
            <div className="text-muted-foreground">ارسال در</div>
            <div className="text-xs">{verification.submitted_at ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">بررسی در</div>
            <div className="text-xs">{verification.reviewed_at ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تأیید در</div>
            <div className="text-xs">{verification.approved_at ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">انقضا</div>
            <div className="text-xs">{verification.expires_at ?? "—"}</div>
          </div>
          {verification.decision_reason ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">دلیل تصمیم اخیر</div>
              <div>{verification.decision_reason}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">مدارک ({documents.length})</h2>
        {documents.length === 0 ? (
          <TableEmpty>مدرکی پیوست نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع</TableHead>
                  <TableHead>عنوان</TableHead>
                  <TableHead>مسیر</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>دلیل رد</TableHead>
                  <TableHead>عملیات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {documents.map((d) => (
                  <TableRow key={d.id}>
                    <TableCell><Badge variant="outline">{d.document_kind}</Badge></TableCell>
                    <TableCell>{d.title ?? "—"}</TableCell>
                    <TableCell className="font-mono text-xs">{d.storage_path ?? "—"}</TableCell>
                    <TableCell><Badge variant="outline">{d.status}</Badge></TableCell>
                    <TableCell className="text-xs">{d.rejection_reason ?? "—"}</TableCell>
                    <TableCell>
                      {d.status === "pending" ? (
                        <DocumentActions
                          documentId={d.id}
                          subjectType={subjectType}
                          verificationId={verification.id}
                        />
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
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">پرچم‌های ریسک ({riskFlags.length})</h2>
        {riskFlags.length === 0 ? (
          <TableEmpty>پرچم ریسک ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border mb-4">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کد</TableHead>
                  <TableHead>شدت</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>منبع</TableHead>
                  <TableHead>توضیح</TableHead>
                  <TableHead>زمان</TableHead>
                  <TableHead>حل</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {riskFlags.map((f) => (
                  <TableRow key={f.id}>
                    <TableCell className="font-mono text-xs">{f.code}</TableCell>
                    <TableCell><Badge variant="outline">{f.severity}</Badge></TableCell>
                    <TableCell><Badge variant="outline">{f.status}</Badge></TableCell>
                    <TableCell className="text-xs">{f.source}</TableCell>
                    <TableCell className="text-xs">{f.detail ?? "—"}</TableCell>
                    <TableCell className="text-xs">{f.raised_at}</TableCell>
                    <TableCell>
                      {f.status === "open" ? (
                        <RiskFlagActions.Resolve
                          flagId={f.id}
                          subjectType={subjectType}
                          verificationId={verification.id}
                        />
                      ) : (
                        <span className="text-xs text-muted-foreground">{f.resolution_note ?? "—"}</span>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
        <RiskFlagActions.Raise
          subjectType={subjectType}
          subjectId={
            subjectType === "person"
              ? (verification.user_id ?? "")
              : (verification.organization_id ?? "")
          }
          verificationId={verification.id}
        />
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">رویدادها ({events.length})</h2>
        {events.length === 0 ? (
          <TableEmpty>رویدادی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع</TableHead>
                  <TableHead>کاربر</TableHead>
                  <TableHead>زمان</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {events.map((e) => (
                  <TableRow key={e.id}>
                    <TableCell><Badge variant="outline">{e.event_kind}</Badge></TableCell>
                    <TableCell className="font-mono text-xs">{e.actor_user_id ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.occurred_at}</TableCell>
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
