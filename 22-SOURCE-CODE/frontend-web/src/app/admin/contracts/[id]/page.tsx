import { notFound } from "next/navigation";
import { getContractUnified } from "@/lib/contract/get-contract";
import { PreparationView } from "@/app/buyer/contracts/[id]/preparation-view";
import { ExecutedView } from "@/app/buyer/contracts/[id]/executed-view";
import { AdminForceActions } from "./admin-force-actions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminContractDetailPage({ params }: PageProps) {
  const { id } = await params;
  const unified = await getContractUnified(id, "admin");
  if (!unified) notFound();

  return (
    <div className="space-y-6">
      {unified.kind === "preparation" ? (
        <PreparationView detail={unified.preparation!} audience="admin" />
      ) : (
        <ExecutedView detail={unified.executed!} audience="admin" />
      )}

      <AdminForceActions
        id={id}
        kind={unified.kind}
        status={
          unified.kind === "preparation"
            ? unified.preparation!.preparation.status
            : unified.executed!.contract.status
        }
      />
    </div>
  );
}
