import Link from "next/link";
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
import type { ExecutedContractDetail } from "@/types/database";
import { ExecutedStatusActions } from "./executed-status-actions";
import { CreateSignatureRequestForm } from "./create-signature-request-form";
import { SignatureRequestActions } from "./signature-request-actions";

interface Props {
  detail: ExecutedContractDetail;
  audience: "buyer" | "supplier" | "admin";
}

export function ExecutedView({ detail, audience }: Props) {
  const { contract, parties, signature_requests: signatureRequests, events } = detail;
  const canMarkPending =
    audience === "buyer" && contract.status === "draft_execution";
  const canCancel =
    audience === "buyer" &&
    (contract.status === "draft_execution" || contract.status === "pending_signatures");
  const canCreateSignatureReq =
    audience === "buyer" &&
    (contract.status === "draft_execution" || contract.status === "pending_signatures");

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{contract.title}</h1>
          <p className="text-sm text-muted-foreground">
            <span className="font-mono text-xs">{contract.contract_code}</span>
            {" · "}
            <Badge variant="success">phase: executed</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{contract.status}</Badge>
          </p>
        </div>
        {audience === "buyer" ? (
          <ExecutedStatusActions
            contractId={contract.id}
            canMarkPending={canMarkPending}
            canCancel={canCancel}
          />
        ) : null}
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">RFQ</div>
            <div className="font-mono text-xs">{contract.request_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">پیشنهاد</div>
            <div className="font-mono text-xs">{contract.offer_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">آماده‌سازی</div>
            <div className="font-mono text-xs">{contract.preparation_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تاریخ شروع اعتبار</div>
            <div className="text-xs">{contract.effective_date ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تاریخ انقضا</div>
            <div className="text-xs">{contract.expiry_date ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ارز</div>
            <div>{contract.currency ?? "—"}</div>
          </div>
          {contract.payment_terms_text ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">شرایط پرداخت</div>
              <div>{contract.payment_terms_text}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">طرف‌ها ({parties?.length ?? 0})</h2>
        {!parties || parties.length === 0 ? (
          <TableEmpty>طرفی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نام</TableHead>
                  <TableHead>نوع</TableHead>
                  <TableHead>نقش</TableHead>
                  <TableHead>امضاکننده</TableHead>
                  <TableHead>ترتیب</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {parties.map((p) => (
                  <TableRow key={p.id}>
                    <TableCell>{p.display_name}</TableCell>
                    <TableCell><Badge variant="outline">{p.party_type}</Badge></TableCell>
                    <TableCell>{p.role_title ?? "—"}</TableCell>
                    <TableCell>{p.is_required_signer ? "بله" : "خیر"}</TableCell>
                    <TableCell>{p.signing_order ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">
          درخواست‌های امضا ({signatureRequests?.length ?? 0})
        </h2>
        {!signatureRequests || signatureRequests.length === 0 ? (
          <TableEmpty>درخواست امضایی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>طرف</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>درخواست در</TableHead>
                  <TableHead>سررسید</TableHead>
                  <TableHead>پاسخ</TableHead>
                  <TableHead>عملیات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {signatureRequests.map((sr) => (
                  <TableRow key={sr.id}>
                    <TableCell className="font-mono text-xs">{sr.party_id}</TableCell>
                    <TableCell><Badge variant="outline">{sr.status}</Badge></TableCell>
                    <TableCell className="text-xs">{sr.requested_at}</TableCell>
                    <TableCell className="text-xs">{sr.due_at ?? "—"}</TableCell>
                    <TableCell className="text-xs">{sr.responded_at ?? "—"}</TableCell>
                    <TableCell>
                      <SignatureRequestActions
                        contractId={contract.id}
                        signatureRequestId={sr.id}
                        status={sr.status}
                        audience={audience}
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {canCreateSignatureReq && parties && parties.length > 0 ? (
          <div className="mt-4">
            <h3 className="text-sm font-medium mb-2">ایجاد درخواست امضای جدید</h3>
            <CreateSignatureRequestForm
              contractId={contract.id}
              parties={parties.map((p) => ({ id: p.id, displayName: p.display_name }))}
            />
          </div>
        ) : null}
      </div>

      {events && events.length > 0 ? (
        <div>
          <h2 className="text-lg font-semibold mb-3">رویدادها ({events.length})</h2>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>از</TableHead>
                  <TableHead>به</TableHead>
                  <TableHead>دلیل</TableHead>
                  <TableHead>کاربر</TableHead>
                  <TableHead>زمان</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {events.map((e) => (
                  <TableRow key={e.id}>
                    <TableCell className="text-xs">{e.from_status ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.to_status ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.reason ?? "—"}</TableCell>
                    <TableCell className="font-mono text-xs">{e.actor_user_id ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.created_at}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </div>
      ) : null}

      <div>
        <Button asChild variant="outline" size="sm">
          <Link href={audience === "supplier" ? "/supplier/contracts" : "/buyer/contracts"}>
            بازگشت به فهرست
          </Link>
        </Button>
      </div>
    </div>
  );
}
