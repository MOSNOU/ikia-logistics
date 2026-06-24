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
import { getQuotation } from "@/lib/pricing/get-quotation";
import { ResponseActions } from "./response-actions";

interface PageProps {
  params: Promise<{ quotationId: string }>;
}

export default async function BuyerQuotationDetailPage({ params }: PageProps) {
  const { quotationId } = await params;
  const detail = await getQuotation(quotationId);
  if (!detail) notFound();

  const { quotation, items } = detail;
  const canRespond = quotation.status === "sent";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{quotation.quotation_code}</h1>
          <p className="text-sm text-muted-foreground">
            تأمین‌کننده: <span className="font-mono text-xs">{quotation.supplier_id}</span>
            {" · "}
            ارز: <Badge variant="outline">{quotation.currency_code}</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{quotation.status}</Badge>
          </p>
        </div>
        {canRespond ? <ResponseActions quotationId={quotation.id} /> : null}
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">مبلغ نهایی</div>
            <div className="text-lg font-semibold">
              {Number(quotation.total_amount).toLocaleString("fa-IR")} {quotation.currency_code}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">اعتبار تا</div>
            <div className="text-xs">{quotation.valid_until ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ارسال‌شده در</div>
            <div className="text-xs">{quotation.sent_at ?? "—"}</div>
          </div>
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">ردیف‌ها</h2>
        {items.length === 0 ? (
          <TableEmpty>ردیفی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کالا</TableHead>
                  <TableHead>تعداد</TableHead>
                  <TableHead>واحد</TableHead>
                  <TableHead>قیمت واحد</TableHead>
                  <TableHead>تخفیف</TableHead>
                  <TableHead>جمع</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((it) => (
                  <TableRow key={it.id}>
                    <TableCell className="font-mono text-xs">{it.product_id}</TableCell>
                    <TableCell>{Number(it.quantity).toLocaleString("fa-IR")}</TableCell>
                    <TableCell>{it.unit_of_measure}</TableCell>
                    <TableCell>{Number(it.unit_price).toLocaleString("fa-IR")}</TableCell>
                    <TableCell>{Number(it.discount_amount).toLocaleString("fa-IR")}</TableCell>
                    <TableCell>{Number(it.line_total).toLocaleString("fa-IR")}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {quotation.decision_reason ? (
        <Card>
          <CardContent className="p-6 text-sm">
            <div className="text-muted-foreground">دلیل تصمیم</div>
            <div>{quotation.decision_reason}</div>
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
