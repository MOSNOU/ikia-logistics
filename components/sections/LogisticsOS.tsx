import { Section, SectionHeading } from "@/components/ui/Section";
import { Icon } from "@/components/ui/icons";

const CHAIN = [
  { icon: "order", label: "ثبت سفارش" },
  { icon: "route", label: "انتخاب مسیر" },
  { icon: "booking", label: "رزرو ظرفیت" },
  { icon: "customs", label: "اسناد و گمرک" },
  { icon: "tracking", label: "رهگیری" },
  { icon: "finance", label: "تحویل و تسویه" },
];

export function LogisticsOS() {
  return (
    <Section tone="soft">
      <SectionHeading
        eyebrow="End-to-End"
        title="یک سیستم‌عامل، از سفارش تا تسویه"
        subtitle="کل چرخه حمل در یک جریان پیوسته اجرا و کنترل می‌شود — بدون گسست بین مراحل."
      />
      <ol className="flex flex-col gap-3 lg:flex-row lg:items-stretch lg:gap-2">
        {CHAIN.map((step, i) => (
          <li key={step.label} className="flex items-center gap-3 lg:flex-1 lg:flex-col lg:text-center">
            <div className="flex w-full items-center gap-3 rounded-2xl border border-line bg-white p-4 shadow-[0_1px_3px_rgba(10,27,46,0.04)] lg:flex-col lg:gap-3 lg:py-6">
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-soft-2 text-blue ring-1 ring-line">
                <Icon name={step.icon} className="h-[22px] w-[22px]" />
              </span>
              <span className="text-sm font-extrabold text-ink">{step.label}</span>
            </div>
            {i < CHAIN.length - 1 ? (
              <span aria-hidden className="hidden text-line lg:block lg:self-center">
                {/* RTL flow points to the left */}
                <svg width="20" height="20" viewBox="0 0 20 20" className="rotate-0">
                  <path d="M13 4 L7 10 L13 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </span>
            ) : null}
          </li>
        ))}
      </ol>
    </Section>
  );
}
