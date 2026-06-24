import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { getDispute } from "@/lib/dispute/get-dispute";
import { DisputeSummary } from "@/components/dispute/dispute-summary";
import { SupplierDisputeActions } from "./supplier-dispute-actions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function SupplierDisputeDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getDispute(id, "supplier");
  if (!detail) notFound();

  const { dispute } = detail;
  const status = dispute.status;
  const canSubmit = status === "opened" || status === "under_review";
  const canWithdraw =
    (status === "opened" || status === "under_review") &&
    dispute.opened_by_party === "supplier";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{dispute.title}</h1>
          <p className="text-sm text-muted-foreground">
            <span className="font-mono text-xs">{dispute.dispute_code}</span>
            {" · "}
            <Badge variant="outline">{dispute.status}</Badge>
          </p>
        </div>
        <SupplierDisputeActions
          disputeId={dispute.id}
          canSubmit={canSubmit}
          canWithdraw={canWithdraw}
        />
      </div>

      <DisputeSummary detail={detail} />

      {!canSubmit && !canWithdraw ? (
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            پرونده در وضعیت <Badge variant="outline">{dispute.status}</Badge> برای شما قفل‌شده است.
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
