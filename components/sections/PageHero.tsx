import type { ReactNode } from "react";
import { Container } from "@/components/ui/Section";

// Inner-page hero with the brand gradient. Used by content & persona pages.
export function PageHero({
  eyebrow,
  title,
  subtitle,
  children,
}: {
  eyebrow?: string;
  title: string;
  subtitle?: string;
  children?: ReactNode;
}) {
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-navy-950 via-navy-900 to-navy-800 text-white">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(60% 50% at 50% 0%, rgba(11,92,173,0.35) 0%, transparent 70%), radial-gradient(40% 40% at 12% 100%, rgba(226,27,45,0.12) 0%, transparent 70%)",
        }}
      />
      <Container className="relative py-20 text-center md:py-28">
        {eyebrow ? (
          <span className="mb-5 inline-block rounded-full bg-white/10 px-3.5 py-1.5 text-xs font-bold tracking-wide text-brand-100 ring-1 ring-white/15">
            {eyebrow}
          </span>
        ) : null}
        <h1 className="mx-auto max-w-3xl text-3xl font-black leading-tight tracking-tight md:text-5xl">{title}</h1>
        {subtitle ? (
          <p className="mx-auto mt-5 max-w-2xl text-base leading-8 text-slate-300 md:text-lg">{subtitle}</p>
        ) : null}
        {children ? <div className="mt-9 flex flex-wrap justify-center gap-3">{children}</div> : null}
      </Container>
    </section>
  );
}
