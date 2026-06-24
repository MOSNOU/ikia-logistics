interface Props {
  value: number | null | undefined;
  currency?: string | null;
  className?: string;
}

export function formatAmount(value: number | null | undefined, currency?: string | null): string {
  if (value == null || !Number.isFinite(value)) return "—";
  const code = currency?.toUpperCase() ?? "";
  try {
    return new Intl.NumberFormat("fa-IR", {
      style: code ? "currency" : "decimal",
      currency: code || undefined,
      currencyDisplay: "code",
      maximumFractionDigits: 2,
    }).format(value);
  } catch {
    return `${value.toLocaleString("fa-IR")}${code ? " " + code : ""}`;
  }
}

export function AmountCell({ value, currency, className }: Props) {
  return (
    <span dir="ltr" className={className ?? "font-mono text-xs tabular-nums"}>
      {formatAmount(value, currency)}
    </span>
  );
}
