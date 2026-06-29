import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import type { ModuleEntry } from "@/content/modules/types";
import { STATUS_META } from "@/content/modules/types";
import { Icon } from "@/components/ui/icons";

export function ModuleCard({ module, featured = false }: { module: ModuleEntry; featured?: boolean }) {
  const status = STATUS_META[module.status];
  return (
    <Link
      href={module.route}
      className={`group flex h-full flex-col items-center text-center rounded-[24px] border border-line/80 bg-white shadow-[0_1px_2px_rgba(6,26,47,0.04),0_16px_44px_-30px_rgba(6,26,47,0.34)] transition-all duration-200 hover:-translate-y-0.5 hover:border-blue/25 hover:shadow-[0_22px_56px_-30px_rgba(6,26,47,0.42)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue/30 ${
        featured ? "p-8 sm:min-h-[310px]" : "p-6"
      }`}
    >
      <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue/[0.07] text-blue ring-1 ring-blue/10 transition-colors group-hover:bg-blue group-hover:text-white">
        <Icon name={module.icon} className="h-[20px] w-[20px]" />
      </span>
      <div className="mt-4 flex items-center justify-center gap-2">
        <p className="font-mono text-[10px] font-bold uppercase tracking-[0.16em] text-muted/55" dir="ltr">
          {module.enTitle}
        </p>
        {module.status !== "current" ? (
          <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${status.tone}`}>{status.label}</span>
        ) : null}
      </div>
      <h3 className={`${featured ? "mt-1.5 text-[21px]" : "mt-1 text-[17px]"} font-extrabold leading-snug text-ink`}>
        {module.faTitle}
      </h3>
      <p className={`${featured ? "mt-3 text-[15px] leading-8" : "mt-2 text-[13.5px] leading-7"} flex-1 text-muted`}>
        {module.value}
      </p>
      <span className="mt-5 inline-flex items-center gap-1.5 text-[13px] font-bold text-blue">
        مشاهده
        <ArrowLeft className="h-4 w-4 transition-transform group-hover:-translate-x-1" aria-hidden />
      </span>
    </Link>
  );
}

export function ModuleGrid({
  modules,
  cols = 3,
  featuredCount = 0,
}: {
  modules: ModuleEntry[];
  cols?: 2 | 3;
  featuredCount?: 0 | 1 | 2;
}) {
  const colClass = cols === 2 ? "sm:grid-cols-2" : "sm:grid-cols-2 lg:grid-cols-3";
  return (
    <div className={`grid grid-cols-1 gap-5 ${colClass}`}>
      {modules.map((m, i) => (
        <ModuleCard key={m.key} module={m} featured={i < featuredCount} />
      ))}
    </div>
  );
}
