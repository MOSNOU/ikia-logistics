// CC-58 — Persian/RTL supply-chain process stepper. Server-renderable
// pure HTML/SVG composition. None of the 19 marketing images depict a
// workflow diagram, so the process section relies on this original
// stepper instead of an image. Seven numbered steps reflecting the
// product's actual lifecycle (CC-09 RFQ → CC-12 contract → CC-14
// shipment → CC-17 settlement).

interface Step {
  num: string;
  title: string;
  description: string;
}

const STEPS: Step[] = [
  { num: "۰۱", title: "ثبت درخواست", description: "RFQ خریدار با مشخصات بار، مبدأ، مقصد و زمان‌بندی." },
  { num: "۰۲", title: "برنامه‌ریزی و پیشنهاد", description: "ارزیابی پیشنهادهای حمل‌کنندگان و انتخاب بهترین گزینه." },
  { num: "۰۳", title: "تأیید و عقد قرارداد", description: "تأیید پیشنهاد و امضای دیجیتال قرارداد اجرایی." },
  { num: "۰۴", title: "اجرا و حمل", description: "تخصیص خودرو، راننده و اعزام محموله از مبدأ." },
  { num: "۰۵", title: "پایش و ردیابی", description: "ردیابی لحظه‌ای، رویدادهای سفر و سلامت تله‌متری." },
  { num: "۰۶", title: "تحویل", description: "تأیید تحویل در مقصد و ثبت اسناد رسمی." },
  { num: "۰۷", title: "تسویه و بستن فرایند", description: "صدور فاکتور، آزادسازی حساب امانی و گزارش‌گیری." },
];

export function SupplyChainProcessStepper({
  className = "",
}: {
  className?: string;
}) {
  return (
    <ol className={`grid gap-4 lg:grid-cols-7 ${className}`}>
      {STEPS.map((s, idx) => (
        <li
          key={s.num}
          className="relative rounded-2xl border border-border-soft bg-card p-4 text-right shadow-card lg:p-3"
        >
          {/* Connector line on desktop. */}
          {idx < STEPS.length - 1 ? (
            <span
              aria-hidden
              className="absolute -left-2 top-7 hidden h-px w-4 bg-brand-200 lg:block"
            />
          ) : null}
          <div
            aria-hidden
            className="inline-flex items-center gap-2 rounded-full bg-brand-50 px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-brand-700"
          >
            مرحله {s.num}
          </div>
          <div className="mt-2 text-sm font-bold text-deep-navy">
            {s.title}
          </div>
          <p className="mt-1 text-[11px] leading-6 text-muted-foreground">
            {s.description}
          </p>
        </li>
      ))}
    </ol>
  );
}
