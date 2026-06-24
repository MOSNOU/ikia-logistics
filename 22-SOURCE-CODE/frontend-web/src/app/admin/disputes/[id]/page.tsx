import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { getDispute } from "@/lib/dispute/get-dispute";
import {
  listDisputeEvents,
  listDisputeEvidence,
  listDisputeDecisions,
} from "@/lib/admin/list-dispute-events";
import { DisputeSummary } from "@/components/dispute/dispute-summary";
import { AdminDisputeActions } from "./admin-dispute-actions";
import { AdminEvidenceActions } from "./admin-evidence-actions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminDisputeDetailPage({ params }: PageProps) {
  const { id } = await params;
  const [detail, events, evidence, decisions] = await Promise.all([
    getDispute(id, "admin"),
    listDisputeEvents(id),
    listDisputeEvidence(id),
    listDisputeDecisions(id),
  ]);
  if (!detail) notFound();

  // The admin_get_dispute jsonb wrapper does not bundle the sub-arrays; we
  // supplement here so the shared <DisputeSummary> renders the same way for
  // admin as for buyer/supplier.
  const merged = {
    ...detail,
    events,
    evidence,
    decisions,
  };

  const { dispute } = detail;
  const status = dispute.status;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{dispute.title}</h1>
          <p className="text-sm text-muted-foreground">
            <span className="font-mono text-xs">{dispute.dispute_code}</span>
            {" · "}
            <Badge variant="outline">{status}</Badge>
          </p>
        </div>
        <AdminDisputeActions disputeId={dispute.id} status={status} />
      </div>

      <DisputeSummary detail={merged} />

      {evidence.some((e) => e.status === "submitted") ? (
        <Card>
          <CardContent className="p-6 space-y-3">
            <h2 className="text-lg font-semibold">بررسی مدارک منتظر</h2>
            <div className="space-y-2">
              {evidence
                .filter((e) => e.status === "submitted")
                .map((e) => (
                  <AdminEvidenceActions
                    key={e.id}
                    evidenceId={e.id}
                    disputeId={dispute.id}
                    title={e.title}
                  />
                ))}
            </div>
          </CardContent>
        </Card>
      ) : null}
    </div>
  );
}
