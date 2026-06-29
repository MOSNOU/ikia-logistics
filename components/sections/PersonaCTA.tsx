import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Icon } from "@/components/ui/icons";
import { PERSONA_LIST } from "@/content/personas";

// Homepage persona-routing section: فورواردر / صاحب بار / سازمان / کریر.
export function PersonaCTA() {
  return (
    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
      {PERSONA_LIST.map((p) => (
        <Link
          key={p.slug}
          href={`/${p.slug}`}
          className="group relative flex flex-col overflow-hidden rounded-2xl border border-slate-200/80 bg-white p-7 shadow-[0_1px_3px_rgba(7,26,45,0.04)] transition-all duration-200 hover:-translate-y-1 hover:border-brand-200 hover:shadow-[0_12px_40px_-12px_rgba(11,92,173,0.25)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
        >
          {/* top accent bar on hover */}
          <span className="absolute inset-x-0 top-0 h-1 origin-right scale-x-0 bg-gradient-to-l from-brand-600 to-accent-600 transition-transform duration-300 group-hover:scale-x-100" />
          <div className="mb-5 flex h-12 w-12 items-center justify-center rounded-xl bg-navy-900 text-white">
            <Icon name={p.icon} className="h-6 w-6" />
          </div>
          <span className="mb-2 text-xs font-bold text-brand-600">{p.badge}</span>
          <h3 className="text-lg font-extrabold leading-snug text-navy-900">{p.title}</h3>
          <p className="mt-2 flex-1 text-sm leading-7 text-slate-500">{p.subtitle}</p>
          <span className="mt-5 inline-flex items-center gap-1.5 text-sm font-bold text-brand-600">
            مشاهده راهکار
            <ArrowLeft className="h-4 w-4 transition-transform group-hover:-translate-x-1" aria-hidden />
          </span>
        </Link>
      ))}
    </div>
  );
}
