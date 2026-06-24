import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { CarrierCard } from "@/components/marketplace/carrier-card";
import { MarketplaceFilters } from "@/components/marketplace/marketplace-filters";
import { listCarriers } from "@/lib/marketplace/list-carriers";

interface PageProps {
  searchParams: Promise<{
    search?: string;
    originCountry?: string;
    page?: string;
  }>;
}

export default async function BuyerCarriersPage({ searchParams }: PageProps) {
  const { search, originCountry, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const { rows, pageSize } = await listCarriers("buyer", {
    search: search ?? null,
    countryCode: originCountry ?? null,
    page,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">حمل‌کنندگان</h1>
          <p className="text-sm text-muted-foreground">
            فهرست سازمان‌های نوع حمل‌کننده. دسترسی بر اساس RLS تنظیم می‌شود.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/marketplace">بازگشت</Link>
        </Button>
      </div>

      <MarketplaceFilters
        action="/buyer/marketplace/carriers"
        initial={{ search, originCountry }}
        showMode={false}
        showRoute={false}
      />

      {rows.length === 0 ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            حمل‌کننده‌ای مطابق فیلتر شما در فهرست عمومی پیدا نشد. فقط حمل‌کنندگانی که ثبت‌نام عمومی خود را فعال کرده‌اند نمایش داده می‌شوند.
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {rows.map((c) => (
            <CarrierCard key={c.id} carrier={c} />
          ))}
        </div>
      )}

      <div className="flex justify-between text-xs text-muted-foreground">
        <span>صفحه {page + 1} — {rows.length} ردیف</span>
        <div className="flex gap-2">
          {page > 0 ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/buyer/marketplace/carriers?search=${search ?? ""}&originCountry=${originCountry ?? ""}&page=${page - 1}`}>قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/buyer/marketplace/carriers?search=${search ?? ""}&originCountry=${originCountry ?? ""}&page=${page + 1}`}>بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
