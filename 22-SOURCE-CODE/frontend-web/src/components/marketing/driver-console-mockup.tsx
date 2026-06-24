import { Badge } from "@/components/ui/badge";

// CC-56 — Phone-frame mockup of the driver console, drawn in pure HTML +
// CSS using existing CC-54 design tokens. Mirrors (loosely) the real
// driver trip detail layout shipped in CC-50/CC-51 so the marketing
// visual stays honest. No real network calls; no client state.

export function DriverConsoleMockup({ className = "" }: { className?: string }) {
  return (
    <div className={className} aria-hidden>
      {/* Stylized phone bezel. */}
      <div className="mx-auto w-full max-w-[280px] rounded-[2.25rem] border border-border-soft bg-card p-3 shadow-elevated">
        {/* Top notch placeholder for visual rhythm only. */}
        <div className="mx-auto mb-2 h-1.5 w-16 rounded-full bg-muted" />

        {/* Screen surface. */}
        <div className="rounded-[1.5rem] bg-surface-muted p-3 space-y-3 text-right">
          {/* Hero block. */}
          <div className="rounded-xl border border-border-soft bg-card p-3 space-y-2">
            <div className="text-[11px] font-semibold tracking-tight">سفر راننده</div>
            <div className="flex flex-wrap gap-1.5">
              <Badge variant="success">فعال</Badge>
              <Badge variant="info">نشست تله‌متری</Badge>
            </div>
          </div>

          {/* Live capture block. */}
          <div className="rounded-xl border border-border-soft bg-card p-3 space-y-2">
            <div className="text-[10px] font-medium text-muted-foreground">
              ارسال سریع موقعیت زنده
            </div>
            <div className="rounded-md bg-muted/50 p-2 text-[10px] leading-5">
              <div dir="ltr" className="font-mono text-foreground">
                35.68920, 51.38900
              </div>
              <div className="text-muted-foreground">دقت ۸ متر</div>
            </div>
            <div className="h-7 rounded-md bg-primary text-center text-[10px] font-medium leading-7 text-primary-foreground">
              ارسال این موقعیت
            </div>
          </div>

          {/* Timeline preview. */}
          <div className="rounded-xl border border-border-soft bg-card p-3 space-y-2">
            <div className="text-[10px] font-medium">خط زمانی سفر</div>
            <div className="space-y-1.5">
              <div className="flex items-center gap-1.5 text-[10px]">
                <Badge variant="info">موقعیت</Badge>
                <span className="text-muted-foreground">— الان</span>
              </div>
              <div className="flex items-center gap-1.5 text-[10px]">
                <Badge variant="success">شروع نشست</Badge>
                <span className="text-muted-foreground">— ۲ دقیقه پیش</span>
              </div>
              <div className="flex items-center gap-1.5 text-[10px]">
                <Badge variant="warning">قطع سیگنال</Badge>
                <span className="text-muted-foreground">— ۱۲ دقیقه پیش</span>
              </div>
            </div>
          </div>

          {/* Privacy hint. */}
          <div className="text-[9px] leading-5 text-muted-foreground">
            موقعیت فقط با کلیک شما ارسال می‌شود — ردیابی پس‌زمینه فعال نیست.
          </div>
        </div>
      </div>
    </div>
  );
}
