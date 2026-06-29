import type { ReactNode } from "react";

type Tone = "light" | "surface" | "dark" | "brand";

const toneClasses: Record<Tone, string> = {
  light: "bg-white text-slate-700",
  surface: "bg-surface text-slate-700",
  dark: "bg-navy-900 text-slate-100",
  brand: "bg-gradient-to-b from-navy-950 via-navy-900 to-navy-800 text-white",
};

export function Container({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8 ${className}`}>{children}</div>;
}

export function Section({
  children,
  tone = "light",
  className = "",
  id,
}: {
  children: ReactNode;
  tone?: Tone;
  className?: string;
  id?: string;
}) {
  return (
    <section id={id} className={`${toneClasses[tone]} ${className}`}>
      <Container className="py-20 md:py-28">{children}</Container>
    </section>
  );
}

export function SectionHeading({
  eyebrow,
  title,
  subtitle,
  center = true,
  invert = false,
}: {
  eyebrow?: string;
  title: string;
  subtitle?: string;
  center?: boolean;
  invert?: boolean;
}) {
  return (
    <div className={`mb-14 ${center ? "mx-auto max-w-3xl text-center" : "text-start"}`}>
      {eyebrow ? (
        <span
          className={`mb-4 inline-block rounded-full px-3.5 py-1.5 text-xs font-bold tracking-wide ${
            invert ? "bg-white/10 text-brand-100" : "bg-brand-50 text-brand-600 ring-1 ring-brand-100"
          }`}
        >
          {eyebrow}
        </span>
      ) : null}
      <h2
        className={`text-3xl font-black leading-tight tracking-tight md:text-5xl ${
          invert ? "text-white" : "text-navy-900"
        }`}
      >
        {title}
      </h2>
      {subtitle ? (
        <p className={`mt-5 text-base leading-8 md:text-lg ${invert ? "text-slate-300" : "text-slate-500"}`}>
          {subtitle}
        </p>
      ) : null}
    </div>
  );
}
