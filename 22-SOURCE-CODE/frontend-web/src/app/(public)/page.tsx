import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { siteConfig } from "@/lib/config/site";

const highlights = [
  {
    title: "بازارگاه RFQ",
    description: "درخواست خرید، پیشنهاد، مذاکره و انعقاد قرارداد در یک بستر یکپارچه.",
  },
  {
    title: "اجرای لجستیک",
    description: "هماهنگی محموله، حمل‌کننده و ردیابی لحظه‌ای در سراسر کشور.",
  },
  {
    title: "مالی و امانی",
    description: "تسویه، اعتبارسنجی و حساب‌های امانی برای اطمینان طرفین معامله.",
  },
  {
    title: "هوش مصنوعی",
    description: "دستیار هوشمند برای تأمین‌کننده، خریدار، تطبیق و مدیران ارشد.",
  },
];

export default function HomePage() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-16">
      <section className="text-center">
        <p className="text-sm font-medium text-muted-foreground">{siteConfig.nameEn}</p>
        <h1 className="mt-3 text-3xl font-bold tracking-tight md:text-5xl">
          {siteConfig.nameFa}
        </h1>
        <p className="mx-auto mt-4 max-w-2xl text-base text-muted-foreground md:text-lg">
          {siteConfig.taglineFa}
        </p>
        <div className="mt-8 flex justify-center gap-3">
          <Button asChild>
            <Link href="/login">ورود به سامانه</Link>
          </Button>
          <Button asChild variant="outline">
            <Link href="/dashboard">پنل کاربری</Link>
          </Button>
        </div>
      </section>

      <section className="mt-16 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {highlights.map((item) => (
          <Card key={item.title}>
            <CardHeader>
              <CardTitle>{item.title}</CardTitle>
              <CardDescription>{item.description}</CardDescription>
            </CardHeader>
            <CardContent />
          </Card>
        ))}
      </section>
    </div>
  );
}
