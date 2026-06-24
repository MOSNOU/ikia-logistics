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
import { getProfile } from "@/lib/auth/get-profile";
import { getMyOrganizationVerification } from "@/lib/kyc/get-my-organization-verification";
import { AttachDocumentForm } from "@/app/profile/kyc/attach-document-form";
import { StartOrgButton } from "./start-org-button";
import { OrgDraftForm } from "./org-draft-form";
import { SubmitOrgButton } from "./submit-org-button";
import type { KycStatus } from "@/types/database";

function statusBadge(s: KycStatus | "not_started") {
  switch (s) {
    case "approved":
      return <Badge variant="success">تأییدشده</Badge>;
    case "submitted":
    case "in_review":
      return <Badge variant="warning">{s === "submitted" ? "ارسال‌شده" : "در حال بررسی"}</Badge>;
    case "rejected":
    case "expired":
      return <Badge variant="danger">{s === "rejected" ? "ردشده" : "منقضی"}</Badge>;
    case "info_requested":
      return <Badge variant="warning">اطلاعات بیشتر</Badge>;
    case "draft":
      return <Badge variant="muted">پیش‌نویس</Badge>;
    case "not_started":
      return <Badge variant="outline">شروع‌نشده</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

export default async function SupplierKybPage() {
  const profile = await getProfile();
  const orgId = profile?.primaryOrganizationId ?? null;

  if (!orgId) {
    return (
      <div className="mx-auto max-w-2xl">
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            سازمان فعالی برای این کاربر تعریف نشده است.
          </CardContent>
        </Card>
      </div>
    );
  }

  const detail = await getMyOrganizationVerification(orgId);
  const status = detail.status;
  const editable = status === "draft" || status === "info_requested";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">احراز هویت سازمان (KYB)</h1>
        <p className="text-sm text-muted-foreground">
          ثبت اطلاعات قانونی سازمان و پیوست مدارک شرکتی برای بررسی مدیریت پلتفرم.
        </p>
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">سازمان</div>
            <div className="font-mono text-xs mt-1">{orgId}</div>
          </div>
          <div>
            <div className="text-muted-foreground">وضعیت</div>
            <div className="mt-1">{statusBadge(status)}</div>
          </div>
          {detail.attempt_no ? (
            <div>
              <div className="text-muted-foreground">شماره تلاش</div>
              <div>{detail.attempt_no}</div>
            </div>
          ) : null}
          {detail.submitted_at ? (
            <div>
              <div className="text-muted-foreground">ارسال‌شده در</div>
              <div className="text-xs">{detail.submitted_at}</div>
            </div>
          ) : null}
          {detail.reviewed_at ? (
            <div>
              <div className="text-muted-foreground">بررسی‌شده در</div>
              <div className="text-xs">{detail.reviewed_at}</div>
            </div>
          ) : null}
          {detail.expires_at ? (
            <div>
              <div className="text-muted-foreground">انقضا</div>
              <div className="text-xs">{detail.expires_at}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      {status === "info_requested" && detail.decision_reason ? (
        <Card>
          <CardContent className="p-6 text-sm">
            <div className="text-muted-foreground">درخواست مدیر</div>
            <div className="mt-1">{detail.decision_reason}</div>
          </CardContent>
        </Card>
      ) : null}

      {status === "rejected" && detail.decision_reason ? (
        <Card>
          <CardContent className="p-6 text-sm">
            <div className="text-muted-foreground">دلیل رد</div>
            <div className="mt-1">{detail.decision_reason}</div>
          </CardContent>
        </Card>
      ) : null}

      {status === "not_started" || status === "rejected" || status === "expired" ? (
        <StartOrgButton organizationId={orgId} />
      ) : null}

      {editable && detail.id ? (
        <>
          <OrgDraftForm
            verificationId={detail.id}
            defaults={{
              legalName: detail.legal_name ?? "",
              registrationNumber: detail.registration_number ?? "",
              taxId: detail.tax_id ?? "",
              countryCode: detail.country_code ?? "",
              incorporatedOn: detail.incorporated_on ?? "",
            }}
          />

          <div>
            <h2 className="text-lg font-semibold mb-3">مدارک شرکتی</h2>
            {(detail.documents ?? []).length === 0 ? (
              <TableEmpty>هنوز مدرکی پیوست نشده.</TableEmpty>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>نوع</TableHead>
                      <TableHead>عنوان</TableHead>
                      <TableHead>وضعیت</TableHead>
                      <TableHead>صادر</TableHead>
                      <TableHead>انقضا</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {(detail.documents ?? []).map((d) => (
                      <TableRow key={d.id}>
                        <TableCell><Badge variant="outline">{d.document_kind}</Badge></TableCell>
                        <TableCell>{d.title ?? "—"}</TableCell>
                        <TableCell><Badge variant="outline">{d.status}</Badge></TableCell>
                        <TableCell className="text-xs">{d.issued_on ?? "—"}</TableCell>
                        <TableCell className="text-xs">{d.expires_on ?? "—"}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}

            <div className="mt-4">
              <AttachDocumentForm
                verificationId={detail.id}
                subjectType="organization"
              />
            </div>
          </div>

          <SubmitOrgButton verificationId={detail.id} />
        </>
      ) : null}

      {status === "submitted" || status === "in_review" ? (
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            درخواست در حال بررسی است. لطفاً منتظر اعلام نتیجه باشید.
          </CardContent>
        </Card>
      ) : null}

      {status === "approved" ? (
        <Card>
          <CardContent className="p-6 text-sm">
            سازمان شما تأیید شد{detail.expires_at ? ` و تا ${detail.expires_at} اعتبار دارد` : ""}.
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
