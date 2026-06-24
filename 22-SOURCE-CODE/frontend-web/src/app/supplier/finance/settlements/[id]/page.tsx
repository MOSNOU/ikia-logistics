import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { SettlementSummaryCard } from "@/components/finance/settlement-summary-card";
import { getSettlement } from "@/lib/settlement/get-settlement";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function SupplierFinanceSettlementDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getSettlement(id, "supplier");
  if (!detail) notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">جزئیات تسویه</h1>
          <p className="text-sm text-muted-foreground">نمای فقط-خواندنی مالی.</p>
        </div>
        <div className="flex gap-2">
          <Button asChild variant="outline" size="sm">
            <Link href="/supplier/finance/settlements">بازگشت</Link>
          </Button>
          <Button asChild variant="outline" size="sm">
            <Link href={`/supplier/settlements/${id}`}>نمای عملیاتی</Link>
          </Button>
        </div>
      </div>

      <SettlementSummaryCard detail={detail} />
    </div>
  );
}
