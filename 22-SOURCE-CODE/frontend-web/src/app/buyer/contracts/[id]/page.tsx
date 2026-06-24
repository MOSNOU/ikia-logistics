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
import { getContractUnified } from "@/lib/contract/get-contract";
import { PreparationView } from "./preparation-view";
import { ExecutedView } from "./executed-view";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerContractDetailPage({ params }: PageProps) {
  const { id } = await params;
  const unified = await getContractUnified(id, "buyer");
  if (!unified) notFound();

  if (unified.kind === "preparation") {
    return <PreparationView detail={unified.preparation!} audience="buyer" />;
  }
  return <ExecutedView detail={unified.executed!} audience="buyer" />;
}
