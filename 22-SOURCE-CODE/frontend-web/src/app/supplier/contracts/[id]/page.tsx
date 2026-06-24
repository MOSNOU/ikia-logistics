import { notFound } from "next/navigation";
import { getContractUnified } from "@/lib/contract/get-contract";
import { PreparationView } from "@/app/buyer/contracts/[id]/preparation-view";
import { ExecutedView } from "@/app/buyer/contracts/[id]/executed-view";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function SupplierContractDetailPage({ params }: PageProps) {
  const { id } = await params;
  const unified = await getContractUnified(id, "supplier");
  if (!unified) notFound();

  if (unified.kind === "preparation") {
    return <PreparationView detail={unified.preparation!} audience="supplier" />;
  }
  return <ExecutedView detail={unified.executed!} audience="supplier" />;
}
