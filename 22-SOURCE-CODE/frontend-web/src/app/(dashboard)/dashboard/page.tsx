import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { portalTitles, type Portal } from "@/lib/config/nav";

const portals: Portal[] = ["admin", "buyer", "supplier", "carrier"];

export default function GenericDashboardPage() {
  return (
    <div className="mx-auto max-w-5xl px-4 py-10">
      <h1 className="text-2xl font-semibold">انتخاب پنل</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        برای ورود به فضای کاری مرتبط، یک پنل را انتخاب کنید.
      </p>
      <div className="mt-6 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {portals.map((portal) => (
          <Card key={portal}>
            <CardHeader>
              <CardTitle>{portalTitles[portal].fa}</CardTitle>
              <CardDescription>{portalTitles[portal].en}</CardDescription>
            </CardHeader>
            <CardContent>
              <Button asChild variant="outline" className="w-full">
                <Link href={`/${portal}/dashboard`}>ورود</Link>
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
