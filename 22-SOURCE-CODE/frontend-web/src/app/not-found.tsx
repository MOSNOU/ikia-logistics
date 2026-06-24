import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <div className="flex min-h-screen items-center justify-center px-4">
      <div className="max-w-md text-center">
        <p className="text-sm font-medium text-muted-foreground">۴۰۴</p>
        <h1 className="mt-2 text-2xl font-semibold">صفحه پیدا نشد</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          آدرس درخواستی موجود نیست یا منتقل شده است.
        </p>
        <Button asChild className="mt-6">
          <Link href="/">بازگشت به خانه</Link>
        </Button>
      </div>
    </div>
  );
}
