import Link from "next/link";
import { Button } from "@/components/ui/button";
import { ControlTowerActivityTable } from "@/components/control-tower/activity-table";
import { loadAdminActivity } from "@/lib/control-tower/loaders";

interface PageProps {
  searchParams: Promise<{ page?: string }>;
}

const PAGE_SIZE = 50;

export default async function AdminControlTowerActivityPage({ searchParams }: PageProps) {
  const { page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const rows = await loadAdminActivity({ limit: PAGE_SIZE, offset: page * PAGE_SIZE });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">جریان رویدادهای پلتفرم</h1>
          <p className="text-sm text-muted-foreground">
            ترکیب رویدادهای رزرو، اعزام، تسویه و شیپمنت. مرتب‌شده بر اساس زمان نزولی.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/control-tower">بازگشت</Link>
        </Button>
      </div>

      <ControlTowerActivityTable rows={rows} />

      <div className="flex justify-between text-xs text-muted-foreground">
        <span>صفحه {page + 1} — {rows.length} ردیف</span>
        <div className="flex gap-2">
          {page > 0 ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/control-tower/activity?page=${page - 1}`}>قبلی</Link>
            </Button>
          ) : null}
          {rows.length === PAGE_SIZE ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/control-tower/activity?page=${page + 1}`}>بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
