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
import { listRfqInvitations } from "@/lib/admin/list-rfq-invitations";
import { ForceRfqActions } from "./force-rfq-actions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminRfqDetailPage({ params }: PageProps) {
  const { id } = await params;
  const [detail, invitations] = await Promise.all([
    getRfq(id, "admin"),
    listRfqInvitations(id),
  ]);
  if (!detail) notFound();

  const { request, items, events } = detail;

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
        <ForceRfqActions requestId={request.id} status={request.status} />
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">سازمان</div>
            <div className="font-mono text-xs">{request.organization_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">مهلت ارسال</div>
            <div className="text-xs">{request.submission_deadline ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">اعتبار تا</div>
            <div className="text-xs">{request.validity_until ?? "—"}</div>
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
          {request.internal_notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت داخلی</div>
              <div>{request.internal_notes}</div>
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
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">دعوت‌ها ({invitations.length})</h2>
        {invitations.length === 0 ? (
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
        )}
      </div>
    </div>
  );
}
