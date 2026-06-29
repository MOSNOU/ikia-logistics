import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Section, Eyebrow } from "@/components/ui/Section";
import { CorridorNetworkVisual } from "./Visuals";

const STATS = [
  { v: "۲", l: "کریدور راهبردی" },
  { v: "۵۸", l: "مرکز لجستیک" },
  { v: "۴", l: "شیوه حمل متصل" },
];

const LINKS = [
  { title: "کریدور شمال–جنوب (INSTC)", href: "/corridors/instc" },
  { title: "کریدور شرق–غرب", href: "/corridors/east-west" },
  { title: "درگاه‌های مرزی و گمرکی", href: "/corridors" },
  { title: "شبکه ۵۸ مرکز لجستیک", href: "/corridors" },
];

export function CorridorNetwork() {
  return (
    <Section tone="light">
      <div className="grid items-center gap-10 lg:grid-cols-2 lg:gap-14">
        {/* copy + stats */}
        <div>
          <Eyebrow>Regional Corridor Network</Eyebrow>
          <h2 className="mt-3 text-[clamp(1.6rem,3vw,2.4rem)] font-bold leading-[1.2] tracking-tight text-ink">
            کریدورهای منطقه‌ای را مثل یک شبکه زنده مدیریت کنید
          </h2>
          <p className="mt-4 max-w-xl text-[15px] leading-8 text-muted sm:text-base">
            بازار ایران را به کریدورهای شمال–جنوب و شرق–غرب، بنادر جنوبی و شبکه مراکز لجستیک متصل کنید.
          </p>

          <div className="mt-7 grid grid-cols-3 gap-4 border-y border-line py-5">
            {STATS.map((s) => (
              <div key={s.l}>
                <div className="text-2xl font-bold text-ink">{s.v}</div>
                <div className="mt-1 text-[12px] text-muted">{s.l}</div>
              </div>
            ))}
          </div>

          <ul className="mt-6 grid gap-1.5 sm:grid-cols-2">
            {LINKS.map((l) => (
              <li key={l.title}>
                <Link
                  href={l.href}
                  className="group inline-flex items-center gap-2 rounded-lg py-1.5 text-[14px] font-medium text-ink transition-colors hover:text-blue"
                >
                  <ArrowLeft className="h-3.5 w-3.5 text-blue transition-transform group-hover:-translate-x-1" aria-hidden />
                  {l.title}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        {/* network visual */}
        <CorridorNetworkVisual />
      </div>
    </Section>
  );
}
