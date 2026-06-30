import type { ReactNode } from "react";

type Tone = "light" | "soft" | "ink" | "brand";

const toneClasses: Record<Tone, string> = {
  light: "bg-white text-muted",
  soft: "bg-soft text-muted",
  ink: "bg-ink text-ondark",
  brand: "bg-gradient-to-b from-ink via-ink-2 to-steel text-ondark",
};

export function Container({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`mx-auto w-full max-w-6xl px-5 sm:px-6 lg:px-8 ${className}`}>{children}</div>;
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
      <Container className="py-16 sm:py-20 lg:py-24">{children}</Container>
    </section>
  );
}

export function Eyebrow({ children, invert = false }: { children: ReactNode; invert?: boolean }) {
  return (
    <p className={`text-[11px] font-bold uppercase tracking-[0.2em] ${invert ? "text-blue-bright" : "text-blue"}`}>
      {children}
    </p>
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
    <div className={`mb-10 sm:mb-12 ${center ? "mx-auto max-w-2xl text-center" : "max-w-2xl text-start"}`}>
      {eyebrow ? <Eyebrow invert={invert}>{eyebrow}</Eyebrow> : null}
      <h2
        className={`mt-3 text-[clamp(1.6rem,3vw,2.4rem)] font-bold leading-[1.2] tracking-tight ${
          invert ? "text-white" : "text-ink"
        }`}
      >
        {title}
      </h2>
      {subtitle ? (
        <p className={`mt-3.5 text-[15px] leading-7 sm:text-base sm:leading-8 ${invert ? "text-ondark-muted" : "text-muted"}`}>
          {subtitle}
        </p>
      ) : null}
    </div>
  );
}
