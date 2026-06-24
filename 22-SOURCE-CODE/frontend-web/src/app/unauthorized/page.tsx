import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function UnauthorizedPage() {
  return (
    <div className="flex min-h-screen items-center justify-center px-4">
      <div className="max-w-md text-center">
        <p className="text-sm font-medium text-muted-foreground">۴۰۳</p>
        <h1 className="mt-2 text-2xl font-semibold">دسترسی غیرمجاز</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          شما اجازه دسترسی به این بخش را ندارید. در صورت نیاز با مدیر سیستم تماس بگیرید.
        </p>
        <div className="mt-6 flex justify-center gap-3">
          <Button asChild variant="outline">
            <Link href="/">خانه</Link>
          </Button>
          <Button asChild>
            <Link href="/login">ورود مجدد</Link>
          </Button>
        </div>
      </div>
    </div>
  );
}
