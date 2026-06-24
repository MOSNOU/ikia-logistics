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
import { getRfq } from "@/lib/rfq/get-rfq";
import { listBuyerReceivedOffers } from "@/lib/offer/list-buyer-offers";
import { BuyerRfqActions } from "./buyer-rfq-actions";
import { UpsertItemForm } from "./upsert-item-form";
import { InviteSuppliersForm } from "./invite-suppliers-form";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerRfqDetailPage({ params }: PageProps) {
  const { id } = await params;
  const [detail, offers] = await Promise.all([
    getRfq(id, "buyer"),
    listBuyerReceivedOffers({ requestId: id, pageSize: 100 }),
  ]);
  if (!detail) notFound();

  const { request, items, invitations } = detail;
  const editable = request.status === "draft";
  const canSubmit = request.status === "draft";
  const canClose = request.status === "submitted" || request.status === "published" || request.status === "invited";
  const canCancel = canSubmit || canClose;
  const canInvite = request.status === "draft" || request.status === "submitted" || request.status === "published" || request.status === "invited";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{request.title}</h1>
          <p className="text-sm text-muted-foreground">
            <span className="font-mono text-xs">{request.rfq_code}</span>
            {" · "}
            <Badge variant="outline">{request.preferred_currency}</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{request.status}</Badge>
          </p>
        </div>
        <BuyerRfqActions
          requestId={request.id}
          canSubmit={canSubmit}
          canClose={canClose}
          canCancel={canCancel}
        />
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">مهلت ارسال</div>
            <div className="text-xs">{request.submission_deadline ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">اعتبار تا</div>
            <div className="text-xs">{request.validity_until ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">مدل دیداری</div>
            <div><Badge variant="outline">{request.visibility}</Badge></div>
          </div>
          <div>
            <div className="text-muted-foreground">کشور تحویل</div>
            <div>{request.delivery_country ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شهر تحویل</div>
            <div>{request.delivery_city ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">شرایط پرداخت</div>
            <div>{request.payment_terms_text ?? "—"}</div>
          </div>
          {request.description ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">توضیحات</div>
              <div>{request.description}</div>
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
                  <TableHead>کالا</TableHead>
                  <TableHead>تعداد</TableHead>
                  <TableHead>واحد</TableHead>
                  <TableHead>یادداشت</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((it) => (
                  <TableRow key={it.id}>
                    <TableCell className="font-mono text-xs">{it.product_id ?? "—"}</TableCell>
                    <TableCell>{it.quantity != null ? Number(it.quantity).toLocaleString("fa-IR") : "—"}</TableCell>
                    <TableCell>{it.quantity_unit ?? "—"}</TableCell>
                    <TableCell className="text-xs">{it.notes ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {editable ? (
          <div className="mt-4">
            <h3 className="text-sm font-medium mb-2">افزودن ردیف</h3>
            <UpsertItemForm requestId={request.id} />
          </div>
        ) : null}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">دعوت‌ها ({invitations?.length ?? 0})</h2>
        {!invitations || invitations.length === 0 ? (
          <TableEmpty>دعوتی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>تأمین‌کننده</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>دعوت در</TableHead>
                  <TableHead>دیده‌شده</TableHead>
                  <TableHead>پاسخ‌داده</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invitations.map((inv) => (
                  <TableRow key={inv.id}>
                    <TableCell className="font-mono text-xs">{inv.supplier_id}</TableCell>
                    <TableCell><Badge variant="outline">{inv.status}</Badge></TableCell>
                    <TableCell className="text-xs">{inv.invited_at}</TableCell>
                    <TableCell className="text-xs">{inv.viewed_at ?? "—"}</TableCell>
                    <TableCell className="text-xs">{inv.responded_at ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {canInvite ? (
          <div className="mt-4">
            <h3 className="text-sm font-medium mb-2">دعوت تأمین‌کنندگان</h3>
            <InviteSuppliersForm requestId={request.id} />
          </div>
        ) : null}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">پیشنهادهای دریافتی ({offers.rows.length})</h2>
        {offers.rows.length === 0 ? (
          <TableEmpty>هنوز پیشنهادی دریافت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کد پیشنهاد</TableHead>
                  <TableHead>تأمین‌کننده</TableHead>
                  <TableHead>ارز</TableHead>
                  <TableHead>تعداد ردیف</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>ارسال در</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {offers.rows.map((o) => (
                  <TableRow key={o.id}>
                    <TableCell className="font-mono text-xs">{o.offer_code}</TableCell>
                    <TableCell className="font-mono text-xs">{o.supplier_id ?? "—"}</TableCell>
                    <TableCell><Badge variant="outline">{o.currency}</Badge></TableCell>
                    <TableCell>{o.item_count ?? 0}</TableCell>
                    <TableCell><Badge variant="outline">{o.status}</Badge></TableCell>
                    <TableCell className="text-xs">{o.submitted_at ?? "—"}</TableCell>
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
