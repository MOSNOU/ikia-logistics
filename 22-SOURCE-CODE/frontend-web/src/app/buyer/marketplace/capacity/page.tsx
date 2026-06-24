import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { CapacityCard } from "@/components/marketplace/capacity-card";
import { MarketplaceFilters } from "@/components/marketplace/marketplace-filters";
import { listCapacity } from "@/lib/marketplace/list-capacity";
import type { TransportMode } from "@/types/database";

interface PageProps {
  searchParams: Promise<{
    transportMode?: string;
    originCountry?: string;
    destinationCountry?: string;
  }>;
}

export default async function BuyerCapacityPage({ searchParams }: PageProps) {
  const { transportMode, originCountry, destinationCountry } = await searchParams;
  const { rows, available, note } = await listCapacity("buyer", {
    transportMode: (transportMode as TransportMode | undefined) ?? null,
    originCountry: originCountry ?? null,
    destinationCountry: destinationCountry ?? null,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">ظرفیت‌های موجود</h1>
          <p className="text-sm text-muted-foreground">
            فهرست ظرفیت‌های فعال منتشرشده توسط حمل‌کنندگان عمومی.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/marketplace">بازگشت</Link>
        </Button>
      </div>

      <MarketplaceFilters
        action="/buyer/marketplace/capacity"
        initial={{
          transportMode: (transportMode as TransportMode | undefined) ?? "",
          originCountry,
          destinationCountry,
        }}
        showSearch={false}
      />

      {!available ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">{note}</CardContent>
        </Card>
      ) : rows.length === 0 ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            ظرفیتی مطابق با فیلتر شما یافت نشد.
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {rows.map((c) => <CapacityCard key={c.id} listing={c} />)}
        </div>
      )}
    </div>
  );
}
