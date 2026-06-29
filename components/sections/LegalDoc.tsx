import { Section } from "@/components/ui/Section";

export type LegalSection = { heading: string; paragraphs: string[] };

export function LegalDoc({ updated, sections }: { updated: string; sections: LegalSection[] }) {
  return (
    <Section tone="light">
      <article className="mx-auto max-w-3xl">
        <p className="mb-8 text-xs text-slate-400">آخرین به‌روزرسانی: {updated}</p>
        <div className="space-y-8">
          {sections.map((s) => (
            <section key={s.heading}>
              <h2 className="mb-2 text-lg font-black text-[#1e3a5f]">{s.heading}</h2>
              {s.paragraphs.map((p, i) => (
                <p key={i} className="mb-3 text-sm leading-8 text-slate-600">
                  {p}
                </p>
              ))}
            </section>
          ))}
        </div>
        <p className="mt-10 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-7 text-amber-800">
          این متن یک پیش‌نویس اولیه برای مرحله پیش‌بذری است و جایگزین مشاوره حقوقی نیست؛ نسخه نهایی در مسیر تکمیل است.
        </p>
      </article>
    </Section>
  );
}
