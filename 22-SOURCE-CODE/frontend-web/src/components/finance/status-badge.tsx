import { Badge } from "@/components/ui/badge";

type Domain = "invoice" | "settlement" | "escrow";

const LABEL_FA: Record<string, string> = {
  // invoice
  draft: "پیش‌نویس",
  issued: "صادرشده",
  sent: "ارسال‌شده",
  partially_paid: "پرداخت ناقص",
  paid: "پرداخت‌شده",
  overdue: "گذشته از موعد",
  cancelled: "لغوشده",
  voided: "ابطال‌شده",
  // settlement
  ready: "آماده تسویه",
  holding: "بلوکه",
  released: "آزاد شد",
  reconciled: "تطبیق‌شده",
  disputed: "در منازعه",
  // escrow
  open: "باز",
  active: "فعال",
  frozen: "فریز",
  closed: "بسته‌شده",
};

function variantFor(status: string, domain: Domain): "success" | "warning" | "danger" | "outline" {
  if (["paid", "released", "reconciled", "open", "active"].includes(status)) return "success";
  if (
    ["overdue", "holding", "frozen", "disputed", "cancelled", "voided"].includes(status)
  ) {
    return ["overdue", "frozen", "disputed"].includes(status) ? "danger" : "warning";
  }
  if (domain === "invoice" && status === "partially_paid") return "warning";
  return "outline";
}

interface Props {
  status: string;
  domain: Domain;
}

export function FinanceStatusBadge({ status, domain }: Props) {
  const v = variantFor(status, domain);
  const label = LABEL_FA[status] ?? status;
  return <Badge variant={v}>{label}</Badge>;
}
