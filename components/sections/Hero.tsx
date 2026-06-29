import { Radar, Shuffle, FileText, ShieldCheck, MapPin, Truck, ArrowLeft } from "lucide-react";
import { Container } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { PRODUCT_URLS } from "@/content/navigation";

const TRUST_CHIPS = [
  { icon: Radar, label: "رهگیری لحظه‌ای" },
  { icon: Shuffle, label: "تخصیص هوشمند" },
  { icon: FileText, label: "اسناد و انطباق" },
  { icon: ShieldCheck, label: "آمادگی تسویه" },
];

export function Hero() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-navy-950 via-navy-900 to-navy-800 text-white">
      {/* ambient glow */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(50% 60% at 85% 0%, rgba(11,92,173,0.40) 0%, transparent 70%), radial-gradient(40% 50% at 10% 100%, rgba(226,27,45,0.14) 0%, transparent 70%)",
        }}
      />
      {/* subtle grid */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-[0.06]"
        style={{
          backgroundImage:
            "linear-gradient(to right, white 1px, transparent 1px), linear-gradient(to bottom, white 1px, transparent 1px)",
          backgroundSize: "44px 44px",
        }}
      />

      <Container className="relative grid items-center gap-14 py-20 md:py-28 lg:grid-cols-2 lg:gap-10">
        {/* Copy */}
        <div className="text-center lg:text-start">
          <span className="mb-6 inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-1.5 text-xs font-bold tracking-wide text-brand-100 ring-1 ring-white/15">
            <span className="h-1.5 w-1.5 rounded-full bg-accent-500" />
            سیستم‌عامل دیجیتال لجستیک
          </span>
          <h1 className="text-4xl font-black leading-[1.15] tracking-tight md:text-6xl">
            عامل دیجیتال لجستیک،
            <br />
            <span className="bg-gradient-to-l from-brand-400 to-brand-100 bg-clip-text text-transparent">
              حمل‌ونقل و ترانزیت
            </span>
          </h1>
          <p className="mx-auto mt-6 max-w-xl text-base leading-8 text-slate-300 md:text-lg lg:mx-0">
            iKIA یک وب‌سایت نیست؛ زیرساخت هوشمند برای اتصال صاحبان بار، فورواردرها، کریرها و سازمان‌هاست.
          </p>

          <div className="mt-9 flex flex-wrap justify-center gap-3 lg:justify-start">
            <Button href={PRODUCT_URLS.register} variant="primary" size="lg">
              شروع کنید
            </Button>
            <Button href="#personas" variant="outlineLight" size="lg">
              مشاهده راهکارها
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </div>

          <div className="mt-10 flex flex-wrap justify-center gap-x-6 gap-y-3 lg:justify-start">
            {TRUST_CHIPS.map((chip) => (
              <div key={chip.label} className="inline-flex items-center gap-2 text-sm font-semibold text-slate-300">
                <chip.icon className="h-4 w-4 text-brand-400" strokeWidth={2} aria-hidden />
                {chip.label}
              </div>
            ))}
          </div>
        </div>

        {/* Control-tower mockup (pure CSS, no asset required) */}
        <ControlTowerMockup />
      </Container>
    </section>
  );
}

function ControlTowerMockup() {
  return (
    <div className="relative mx-auto w-full max-w-md lg:max-w-none">
      <div className="absolute -inset-4 -z-10 rounded-[2rem] bg-brand-500/20 blur-2xl" aria-hidden />
      <div className="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.04] shadow-2xl backdrop-blur-sm">
        {/* window bar */}
        <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
          <div className="flex items-center gap-1.5">
            <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
            <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
            <span className="h-2.5 w-2.5 rounded-full bg-white/20" />
          </div>
          <span className="text-xs font-bold text-slate-300">iKIA Control Tower</span>
          <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-bold text-emerald-300">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
            زنده
          </span>
        </div>

        <div className="space-y-4 p-4">
          {/* route card */}
          <div className="rounded-xl border border-white/10 bg-navy-950/40 p-4">
            <div className="mb-3 flex items-center justify-between text-xs font-bold text-slate-300">
              <span>محموله SH-۱۰۲۴</span>
              <span className="text-brand-300">۶۴٪ مسیر</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="flex flex-col items-center">
                <MapPin className="h-4 w-4 text-brand-400" />
                <span className="mt-1 text-[10px] text-slate-400">تهران</span>
              </div>
              <div className="relative h-1 flex-1 rounded-full bg-white/10">
                <div className="absolute inset-y-0 right-0 w-[64%] rounded-full bg-gradient-to-l from-brand-400 to-brand-600" />
                <div className="absolute top-1/2 right-[64%] flex h-6 w-6 -translate-y-1/2 translate-x-1/2 items-center justify-center rounded-full bg-white shadow-md">
                  <Truck className="h-3.5 w-3.5 text-brand-600" />
                </div>
              </div>
              <div className="flex flex-col items-center">
                <MapPin className="h-4 w-4 text-slate-400" />
                <span className="mt-1 text-[10px] text-slate-400">مشهد</span>
              </div>
            </div>
          </div>

          {/* KPI tiles */}
          <div className="grid grid-cols-3 gap-3">
            {[
              { v: "۲۴", l: "محموله فعال" },
              { v: "۱۸", l: "در مسیر" },
              { v: "۹۶٪", l: "تحویل به‌موقع" },
            ].map((k) => (
              <div key={k.l} className="rounded-xl border border-white/10 bg-white/[0.03] p-3 text-center">
                <div className="text-lg font-black text-white">{k.v}</div>
                <div className="mt-0.5 text-[10px] text-slate-400">{k.l}</div>
              </div>
            ))}
          </div>

          {/* status rows */}
          <div className="space-y-2">
            {[
              { code: "SH-۱۰۲۴", status: "در مسیر", tone: "bg-brand-500/15 text-brand-200" },
              { code: "SH-۱۰۲۱", status: "تحویل‌شده", tone: "bg-emerald-500/15 text-emerald-300" },
              { code: "SH-۱۰۱۹", status: "در انتظار تسویه", tone: "bg-amber-500/15 text-amber-300" },
            ].map((r) => (
              <div
                key={r.code}
                className="flex items-center justify-between rounded-lg border border-white/5 bg-white/[0.02] px-3 py-2"
              >
                <span className="text-xs font-semibold text-slate-300">{r.code}</span>
                <span className={`rounded-full px-2.5 py-0.5 text-[10px] font-bold ${r.tone}`}>{r.status}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
