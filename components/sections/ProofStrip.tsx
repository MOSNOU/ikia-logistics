import { Container } from "@/components/ui/Section";

const METRICS = [
  { v: "۲۴/۷", l: "رؤیت لحظه‌ای" },
  { v: "۴", l: "شیوه حمل متصل" },
  { v: "۸", l: "وضعیت چرخه عمر" },
  { v: "۱", l: "سیستم‌عامل لجستیک" },
];

export function ProofStrip() {
  return (
    <section className="border-y border-line bg-white">
      <Container className="py-12">
        <div className="grid grid-cols-2 gap-6 sm:grid-cols-4">
          {METRICS.map((m) => (
            <div key={m.l} className="text-center">
              <div className="text-3xl font-bold text-ink sm:text-4xl">{m.v}</div>
              <div className="mt-1.5 text-sm font-semibold text-muted">{m.l}</div>
            </div>
          ))}
        </div>
        <p className="mt-8 text-center text-sm text-muted">
          طراحی‌شده برای شرکت‌های صنعتی، بازرگانی، حمل‌ونقل و فعالان کریدورهای منطقه‌ای.
        </p>
      </Container>
    </section>
  );
}
