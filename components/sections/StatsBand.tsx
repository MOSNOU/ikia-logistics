export type Stat = { value: string; label: string };

// Trust / metrics band. Values are illustrative pilot targets (pre-seed),
// framed as goals rather than audited figures.
export function StatsBand({ stats }: { stats: Stat[] }) {
  return (
    <div className="grid grid-cols-2 gap-px overflow-hidden rounded-2xl bg-white/10 sm:grid-cols-4">
      {stats.map((s) => (
        <div key={s.label} className="bg-navy-900 px-6 py-8 text-center">
          <div className="text-3xl font-black text-white sm:text-4xl">{s.value}</div>
          <div className="mt-2 text-sm font-semibold text-slate-400">{s.label}</div>
        </div>
      ))}
    </div>
  );
}
