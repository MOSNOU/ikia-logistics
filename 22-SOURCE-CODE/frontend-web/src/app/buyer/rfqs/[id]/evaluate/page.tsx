import Link from "next/link";
import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
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
import { listBuyerEvaluations } from "@/lib/evaluation/list-buyer-evaluations";
import { CreateEvaluationButton } from "./create-evaluation-button";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerRfqEvaluatePage({ params }: PageProps) {
  const { id: requestId } = await params;
  const [rfq, offers, evals] = await Promise.all([
    getRfq(requestId, "buyer"),
    listBuyerReceivedOffers({ requestId, pageSize: 100 }),
    listBuyerEvaluations({ requestId, pageSize: 100 }),
  ]);
  if (!rfq) notFound();

  // Index evaluations by offer_id for quick lookup.
  const byOffer = new Map<string, string>();
  for (const e of evals.rows) {
    byOffer.set(e.offer_id, e.id);
  }

  const submittedOffers = offers.rows.filter(
    (o) => o.status === "submitted" || o.status === "shortlisted" || o.status === "accepted",
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ارزیابی RFQ — {rfq.request.title}</h1>
        <p className="text-sm text-muted-foreground">
          <span className="font-mono text-xs">{rfq.request.rfq_code}</span>
          {" · "}
          وضعیت RFQ: <Badge variant="outline">{rfq.request.status}</Badge>
        </p>
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">
          پیشنهادهای آماده ارزیابی ({submittedOffers.length})
        </h2>
        {submittedOffers.length === 0 ? (
          <TableEmpty>هیچ پیشنهاد ارسال‌شده‌ای برای این RFQ وجود ندارد.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کد پیشنهاد</TableHead>
                  <TableHead>تأمین‌کننده</TableHead>
                  <TableHead>ارز</TableHead>
                  <TableHead>تعداد ردیف</TableHead>
                  <TableHead>وضعیت پیشنهاد</TableHead>
                  <TableHead>ارزیابی</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {submittedOffers.map((o) => {
                  const existingEval = byOffer.get(o.id);
                  return (
                    <TableRow key={o.id}>
                      <TableCell className="font-mono text-xs">{o.offer_code}</TableCell>
                      <TableCell className="font-mono text-xs">{o.supplier_id ?? "—"}</TableCell>
                      <TableCell><Badge variant="outline">{o.currency}</Badge></TableCell>
                      <TableCell>{o.item_count ?? 0}</TableCell>
                      <TableCell><Badge variant="outline">{o.status}</Badge></TableCell>
                      <TableCell>
                        {existingEval ? (
                          <Button asChild variant="outline" size="sm">
                            <Link href={`/buyer/evaluations/${existingEval}`}>
                              مشاهده ارزیابی
                            </Link>
                          </Button>
                        ) : (
                          <CreateEvaluationButton offerId={o.id} />
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/rfqs/${requestId}`}>بازگشت به RFQ</Link>
        </Button>
      </div>
    </div>
  );
}
