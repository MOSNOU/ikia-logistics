type Step = { title: string; desc: string };

const FA_NUM = ["۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸"];

// Numbered workflow timeline — ink/blue/green system, responsive flex.
export function HowItWorks({ steps }: { steps: Step[] }) {
  return (
    <ol className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
      {steps.map((step, i) => (
        <li
          key={step.title}
          className="relative flex h-full flex-col rounded-3xl border border-line bg-white p-6 shadow-[0_1px_2px_rgba(6,26,47,0.04)]"
        >
          <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-blue/[0.07] text-[17px] font-extrabold text-blue ring-1 ring-blue/10">
            {FA_NUM[i] ?? i + 1}
          </span>
          <h3 className="mt-4 text-[16px] font-bold leading-snug text-ink">{step.title}</h3>
          <p className="mt-2 text-[14px] leading-7 text-muted">{step.desc}</p>
          {i < steps.length - 1 ? (
            <span
              aria-hidden
              className="absolute -left-3 top-12 hidden h-px w-6 bg-line lg:block"
            />
          ) : null}
        </li>
      ))}
    </ol>
  );
}
