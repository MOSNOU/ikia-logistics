import { Radar, ShieldCheck, Truck } from "lucide-react";
import { Container } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { ControlTowerVisual } from "./Visuals";
import { PRODUCT_URLS } from "@/content/siteArchitecture";

const CHIPS = [
  { icon: Radar, label: "رهگیری لحظه‌ای" },
  { icon: ShieldCheck, label: "اسناد و انطباق" },
  { icon: Truck, label: "۴ شیوه حمل" },
];

export function Hero() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-soft to-white">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{ background: "radial-gradient(50% 55% at 88% 5%, rgba(31,156,224,0.10) 0%, transparent 60%)" }}
      />
      <Container className="relative grid items-center gap-12 py-14 lg:grid-cols-[1.02fr_0.98fr] lg:gap-14 lg:py-20">
        {/* copy — right in RTL */}
        <div className="text-center lg:text-start">
          <span className="mb-5 inline-flex items-center gap-2 rounded-full border border-line bg-white px-3.5 py-1.5 text-[12px] font-semibold text-blue shadow-[0_1px_2px_rgba(6,26,47,0.04)]">
            <span className="h-1.5 w-1.5 rounded-full bg-green" />
            iKIA Logistic Operating System
          </span>
          <h1 className="text-[clamp(2rem,4.6vw,3.5rem)] font-bold leading-[1.12] tracking-tight text-ink">
            سیستم‌عامل دیجیتال لجستیک،{" "}
            <span className="text-blue">حمل‌ونقل و ترانزیت</span>
          </h1>
          <p className="mx-auto mt-5 max-w-xl text-[16px] leading-8 text-muted lg:mx-0">
            iKIA جریان کالا، ظرفیت حمل، مراکز لجستیک، اسناد، گمرک، تسویه و داده‌های عملیاتی را در یک پلتفرم هوشمند و
            یکپارچه مدیریت می‌کند.
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-3 lg:justify-start">
            <Button href={PRODUCT_URLS.platform} variant="primary" size="lg">
              مشاهده پلتفرم
            </Button>
            <Button href={PRODUCT_URLS.start} variant="outline" size="lg">
              شروع همکاری
            </Button>
          </div>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-x-6 gap-y-3 lg:justify-start">
            {CHIPS.map((c) => (
              <div key={c.label} className="inline-flex items-center gap-2 text-[13px] font-medium text-muted">
                <c.icon className="h-4 w-4 text-blue" strokeWidth={2} aria-hidden />
                {c.label}
              </div>
            ))}
          </div>
        </div>

        {/* product visual — left in RTL */}
        <div className="mx-auto w-full max-w-md lg:max-w-none">
          <ControlTowerVisual />
        </div>
      </Container>
    </section>
  );
}
