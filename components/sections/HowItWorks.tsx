import type { Step } from "@/content/types";

const toFa = (n: number) => n.toLocaleString("fa-IR");

// Numbered steps with a connecting line on desktop.
export function HowItWorks({ steps }: { steps: Step[] }) {
  return (
    <div className="relative">
      {/* connector line (desktop) */}
      <div
        aria-hidden
        className="absolute inset-x-0 top-7 hidden h-px bg-gradient-to-l from-transparent via-brand-200 to-transparent lg:block"
      />
      <ol className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
        {steps.map((step, i) => (
          <li key={step.title} className="relative flex flex-col items-center text-center">
            <div className="relative z-10 mb-5 flex h-14 w-14 items-center justify-center rounded-full bg-navy-900 text-lg font-black text-white shadow-lg ring-4 ring-white">
              {toFa(i + 1)}
            </div>
            <h3 className="mb-2 text-base font-extrabold text-navy-900">{step.title}</h3>
            <p className="text-sm leading-7 text-slate-500">{step.desc}</p>
          </li>
        ))}
      </ol>
    </div>
  );
}
