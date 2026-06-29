import { MapPin, Truck } from "lucide-react";
import { Container, Eyebrow } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";

const STATUS_CHIPS = [
  { label: "Booked", done: true },
  { label: "Dispatched", done: true },
  { label: "In Transit", active: true },
  { label: "Delivered", done: false },
];

export function ControlTower() {
  return (
    <section className="relative overflow-hidden bg-ink text-ondark">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(45% 55% at 12% 15%, rgba(31,156,224,0.18) 0%, transparent 55%), radial-gradient(40% 50% at 90% 90%, rgba(21,194,107,0.10) 0%, transparent 55%)",
        }}
      />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-[0.05]"
        style={{
          backgroundImage:
            "linear-gradient(rgba(255,255,255,1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,1) 1px, transparent 1px)",
          backgroundSize: "56px 56px",
        }}
      />
      <Container className="relative grid items-center gap-12 py-20 lg:grid-cols-2 lg:py-28">
        <div className="text-center lg:text-start">
          <Eyebrow invert>Control Tower</Eyebrow>
          <h2 className="mt-3 text-[clamp(1.6rem,3vw,2.4rem)] font-bold leading-[1.2] tracking-tight">
            برج کنترل دیجیتال برای دیدن، تصمیم‌گیری و اقدام در لحظه
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-[15px] leading-8 text-ondark-muted sm:text-base lg:mx-0">
            سفارش‌ها، ناوگان، اسناد، وضعیت مسیر و رخدادهای عملیاتی در یک نمای زنده جمع می‌شوند تا تیم شما در لحظه
            تصمیم بگیرد و اقدام کند.
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-3 lg:justify-start">
            <Button href="/platform/control-tower" variant="primary" size="lg">
              مشاهده برج کنترل
            </Button>
            <Button href="/platform" variant="outlineLight" size="lg">
              نمای کلی پلتفرم
            </Button>
          </div>
        </div>

        {/* dashboard mockup */}
        <div className="relative mx-auto w-full max-w-xl">
          <div className="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.05] shadow-2xl shadow-black/30 backdrop-blur">
            <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
              <div className="flex items-center gap-1.5">
                <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
                <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
                <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
              </div>
              <span className="font-mono text-xs text-blue-bright" dir="ltr">iKIA OS · Control Tower</span>
              <span className="inline-flex items-center gap-1.5 rounded-full bg-green/15 px-2.5 py-0.5 text-[10px] font-bold text-green">
                <span className="h-1.5 w-1.5 rounded-full bg-green" />
                Live
              </span>
            </div>

            <div className="space-y-4 p-4">
              <div className="rounded-xl border border-white/10 bg-white/[0.04] p-4">
                <div className="mb-3 flex items-center justify-between text-xs">
                  <span className="font-mono text-white/80" dir="ltr">SH-2026-08471</span>
                  <span className="rounded-full bg-blue/20 px-2 py-0.5 font-bold text-blue-bright">North–South</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex flex-col items-center">
                    <MapPin className="h-4 w-4 text-blue-bright" aria-hidden />
                    <span className="mt-1 text-[10px] text-white/60">تهران</span>
                  </div>
                  <div className="relative h-1.5 flex-1 rounded-full bg-white/10">
                    <div className="absolute inset-y-0 right-0 w-[58%] rounded-full bg-gradient-to-l from-blue-bright to-blue" />
                    <div className="absolute top-1/2 right-[58%] flex h-6 w-6 -translate-y-1/2 translate-x-1/2 items-center justify-center rounded-full bg-white shadow">
                      <Truck className="h-3.5 w-3.5 text-blue" aria-hidden />
                    </div>
                  </div>
                  <div className="flex flex-col items-center">
                    <MapPin className="h-4 w-4 text-white/50" aria-hidden />
                    <span className="mt-1 text-[10px] text-white/60">بندرعباس</span>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                {["اظهارنامه", "بارنامه", "بیمه", "گواهی مبدأ"].map((d) => (
                  <div key={d} className="rounded-xl border border-white/10 bg-white/[0.03] px-3 py-2.5">
                    <div className="text-xs font-bold text-white">{d}</div>
                    <div className="mt-0.5 text-[10px] text-green">تأیید شده</div>
                  </div>
                ))}
              </div>

              <div className="grid grid-cols-3 gap-3">
                {[
                  { l: "زمان تحویل", v: "۱۸h", c: "text-blue-bright" },
                  { l: "تطبیق ظرفیت", v: "۹۴٪", c: "text-green" },
                  { l: "تأخیر فعال", v: "۲", c: "text-orange" },
                ].map((m) => (
                  <div key={m.l} className="rounded-xl border border-white/10 bg-white/[0.04] px-3 py-3 text-center">
                    <div className={`text-lg font-bold ${m.c}`}>{m.v}</div>
                    <div className="mt-0.5 text-[10px] text-white/60">{m.l}</div>
                  </div>
                ))}
              </div>

              <div className="flex flex-wrap gap-2">
                {STATUS_CHIPS.map((c) => (
                  <span
                    key={c.label}
                    dir="ltr"
                    className={`rounded-full px-2.5 py-1 text-[10px] font-bold ${
                      c.active
                        ? "bg-blue/25 text-blue-bright ring-1 ring-blue/40"
                        : c.done
                          ? "bg-green/15 text-green"
                          : "bg-white/5 text-white/40"
                    }`}
                  >
                    {c.label}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      </Container>
    </section>
  );
}
