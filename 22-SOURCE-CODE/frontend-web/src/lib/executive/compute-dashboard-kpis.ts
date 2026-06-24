import type {
  ActivityRow,
  ExecutiveKpi,
  PipelineStep,
  RiskItem,
} from "@/types/database";

interface StatusCount {
  status: string;
}

function countByStatus<T extends StatusCount>(
  rows: T[],
  values: string[],
): number {
  const set = new Set(values);
  return rows.reduce((n, r) => (set.has(r.status) ? n + 1 : n), 0);
}

// Convenience: the set of "active" status values for each pipeline stage. Kept
// at module scope so callers don't drift between the KPI section and the
// pipeline section.
export const ACTIVE_STATUS = {
  rfq: ["submitted", "published", "invited"],
  offer: ["submitted", "shortlisted"],
  evaluation: ["in_review"],
  contract_prep: ["draft", "under_review", "ready_for_contract"],
  shipment_active: ["planned", "booked", "in_transit", "arrived"],
  shipment_delivered: ["delivered", "closed"],
  settlement_open: ["draft", "ready", "holding"],
  settlement_disputed: ["disputed"],
  dispute_open: ["opened", "under_review"],
  kyc_pending: ["submitted", "in_review", "info_requested"],
  kyc_attention: ["rejected", "info_requested", "expired"],
};

export interface KpiInputs {
  rfqs?: StatusCount[];
  offers?: StatusCount[];
  evaluations?: StatusCount[];
  contractPreparations?: StatusCount[];
  executedContractCount?: number;
  shipments?: StatusCount[];
  settlements?: StatusCount[];
  disputes?: StatusCount[];
  kycVerifications?: StatusCount[];
  unreadNotifications?: number;
  financeExceptionCount?: number;
}

export interface SectionAvailability {
  rfqs: boolean;
  offers: boolean;
  evaluations: boolean;
  contracts: boolean;
  shipments: boolean;
  settlements: boolean;
  disputes: boolean;
  kyc: boolean;
  notifications: boolean;
  financeExceptions: boolean;
}

function kpi(
  id: string,
  label: string,
  value: number,
  available: boolean,
  opts?: { caption?: string; tone?: ExecutiveKpi["tone"]; href?: string },
): ExecutiveKpi {
  return {
    id,
    label,
    value: available ? value : 0,
    caption: opts?.caption,
    tone: opts?.tone ?? "default",
    available,
    href: opts?.href,
  };
}

export function buildKpis(
  inputs: KpiInputs,
  availability: SectionAvailability,
  audience: "admin" | "buyer" | "supplier",
): ExecutiveKpi[] {
  const rfqs = inputs.rfqs ?? [];
  const offers = inputs.offers ?? [];
  const evals = inputs.evaluations ?? [];
  const cprep = inputs.contractPreparations ?? [];
  const shipments = inputs.shipments ?? [];
  const settlements = inputs.settlements ?? [];
  const disputes = inputs.disputes ?? [];
  const kyc = inputs.kycVerifications ?? [];

  const base = audience === "admin" ? "admin" : audience;

  return [
    kpi(
      "rfqs_active",
      "RFQ‌های فعال",
      countByStatus(rfqs, ACTIVE_STATUS.rfq),
      availability.rfqs,
      { href: `/${base}/rfqs` },
    ),
    kpi(
      "offers_submitted",
      "پیشنهادهای ارسال‌شده",
      countByStatus(offers, ACTIVE_STATUS.offer),
      availability.offers,
      { href: `/${base}/offers` },
    ),
    kpi(
      "evaluations_in_progress",
      "ارزیابی در جریان",
      countByStatus(evals, ACTIVE_STATUS.evaluation),
      availability.evaluations,
      { href: `/${base}/evaluations` },
    ),
    kpi(
      "contracts_in_prep",
      "قراردادهای در حال آماده‌سازی",
      countByStatus(cprep, ACTIVE_STATUS.contract_prep),
      availability.contracts,
      { href: `/${base}/contracts` },
    ),
    kpi(
      "contracts_executed",
      "قراردادهای اجراشده",
      inputs.executedContractCount ?? 0,
      availability.contracts,
      { href: `/${base}/contracts` },
    ),
    kpi(
      "shipments_active",
      "شیپمنت‌های فعال",
      countByStatus(shipments, ACTIVE_STATUS.shipment_active),
      availability.shipments,
      { href: `/${base}/shipments` },
    ),
    kpi(
      "shipments_delivered",
      "شیپمنت‌های تحویل‌شده",
      countByStatus(shipments, ACTIVE_STATUS.shipment_delivered),
      availability.shipments,
      { tone: "success", href: `/${base}/shipments` },
    ),
    kpi(
      "settlements_open",
      "تسویه‌های باز",
      countByStatus(settlements, ACTIVE_STATUS.settlement_open),
      availability.settlements,
      { href: `/${base}/settlements` },
    ),
    kpi(
      "settlements_disputed",
      "تسویه‌های در منازعه",
      countByStatus(settlements, ACTIVE_STATUS.settlement_disputed),
      availability.settlements,
      {
        tone: "danger",
        href: `/${base}/settlements`,
      },
    ),
    kpi(
      "disputes_open",
      "اختلافات باز",
      countByStatus(disputes, ACTIVE_STATUS.dispute_open),
      availability.disputes,
      { tone: "warning", href: `/${base}/disputes` },
    ),
    kpi(
      "kyc_pending",
      "KYC/KYB در انتظار",
      countByStatus(kyc, ACTIVE_STATUS.kyc_pending),
      availability.kyc,
      { tone: "warning", href: `/${base}/kyc` },
    ),
    kpi(
      "notifications_unread",
      "اعلان‌های خوانده‌نشده",
      inputs.unreadNotifications ?? 0,
      availability.notifications,
      { href: "/inbox" },
    ),
    kpi(
      "finance_exceptions",
      "استثناهای مالی",
      inputs.financeExceptionCount ?? 0,
      availability.financeExceptions,
      {
        tone: (inputs.financeExceptionCount ?? 0) > 0 ? "danger" : "default",
        href: "/admin/finance/exceptions",
      },
    ),
  ];
}

export function buildPipeline(
  inputs: KpiInputs,
  availability: SectionAvailability,
  audience: "admin" | "buyer" | "supplier",
): PipelineStep[] {
  const base = audience === "admin" ? "admin" : audience;
  return [
    {
      id: "rfq",
      label: "RFQ",
      count: countByStatus(inputs.rfqs ?? [], ACTIVE_STATUS.rfq),
      href: `/${base}/rfqs`,
      available: availability.rfqs,
    },
    {
      id: "offer",
      label: "پیشنهاد",
      count: countByStatus(inputs.offers ?? [], ACTIVE_STATUS.offer),
      href: `/${base}/offers`,
      available: availability.offers,
    },
    {
      id: "evaluation",
      label: "ارزیابی",
      count: countByStatus(inputs.evaluations ?? [], ACTIVE_STATUS.evaluation),
      href: `/${base}/evaluations`,
      available: availability.evaluations,
    },
    {
      id: "contract",
      label: "قرارداد",
      count: countByStatus(
        inputs.contractPreparations ?? [],
        ACTIVE_STATUS.contract_prep,
      ),
      href: `/${base}/contracts`,
      available: availability.contracts,
    },
    {
      id: "shipment",
      label: "شیپمنت",
      count: countByStatus(inputs.shipments ?? [], ACTIVE_STATUS.shipment_active),
      href: `/${base}/shipments`,
      available: availability.shipments,
    },
    {
      id: "settlement",
      label: "تسویه",
      count: countByStatus(inputs.settlements ?? [], ACTIVE_STATUS.settlement_open),
      href: `/${base}/settlements`,
      available: availability.settlements,
    },
  ];
}

export interface RiskInputs {
  settlements?: StatusCount[];
  disputes?: StatusCount[];
  expiredQuotationCount?: number;
  expiringShipmentDocs?: number;
  kycAttention?: StatusCount[];
  highPriorityUnread?: number;
}

export function buildRisks(
  inputs: RiskInputs,
  availability: SectionAvailability,
  audience: "admin" | "buyer" | "supplier",
): RiskItem[] {
  const base = audience === "admin" ? "admin" : audience;
  const disputed = countByStatus(
    inputs.settlements ?? [],
    ACTIVE_STATUS.settlement_disputed,
  );
  const openDisputes = countByStatus(
    inputs.disputes ?? [],
    ACTIVE_STATUS.dispute_open,
  );
  const kycAttention = countByStatus(
    inputs.kycAttention ?? [],
    ACTIVE_STATUS.kyc_attention,
  );

  return [
    {
      id: "settlements_disputed",
      label: "تسویه‌های در منازعه",
      count: disputed,
      severity: disputed > 0 ? "danger" : "info",
      href: `/${base}/settlements`,
      available: availability.settlements,
    },
    {
      id: "disputes_open",
      label: "اختلافات باز",
      count: openDisputes,
      severity: openDisputes > 0 ? "warning" : "info",
      href: `/${base}/disputes`,
      available: availability.disputes,
    },
    {
      id: "quotations_expired",
      label: "استعلامات منقضی",
      count: inputs.expiredQuotationCount ?? 0,
      severity: (inputs.expiredQuotationCount ?? 0) > 0 ? "warning" : "info",
      href: audience === "admin" ? "/admin/pricing" : undefined,
      available: audience === "admin",
    },
    {
      id: "shipment_docs_overdue",
      label: "مدارک شیپمنت منقضی/در شرف انقضا",
      count: inputs.expiringShipmentDocs ?? 0,
      severity: (inputs.expiringShipmentDocs ?? 0) > 0 ? "warning" : "info",
      href: `/${base}/documents`,
      available: availability.shipments,
    },
    {
      id: "kyc_attention",
      label: "KYC نیازمند توجه",
      count: kycAttention,
      severity: kycAttention > 0 ? "warning" : "info",
      href: `/${base}/kyc`,
      available: availability.kyc,
    },
    {
      id: "notifications_high_priority",
      label: "اعلان‌های با اولویت بالا (خوانده‌نشده)",
      count: inputs.highPriorityUnread ?? 0,
      severity: (inputs.highPriorityUnread ?? 0) > 0 ? "warning" : "info",
      href: "/inbox",
      available: availability.notifications,
    },
  ];
}

export function buildActivity(opts: {
  rfqs?: Array<{ id: string; code?: string; status: string; created_at: string; href: string }>;
  offers?: Array<{ id: string; code?: string; status: string; created_at: string; href: string }>;
  shipments?: Array<{ id: string; code?: string; status: string; created_at: string; href: string }>;
  disputes?: Array<{ id: string; code?: string; status: string; created_at: string; href: string }>;
  notifications?: Array<{
    id: string;
    title: string;
    category: string;
    created_at: string;
    href?: string;
  }>;
}): ActivityRow[] {
  const out: ActivityRow[] = [];
  for (const r of (opts.rfqs ?? []).slice(0, 5)) {
    out.push({
      id: `rfq-${r.id}`,
      category: "rfq",
      subject: r.code ?? r.id,
      description: `وضعیت: ${r.status}`,
      href: r.href,
      created_at: r.created_at,
    });
  }
  for (const o of (opts.offers ?? []).slice(0, 5)) {
    out.push({
      id: `offer-${o.id}`,
      category: "offer",
      subject: o.code ?? o.id,
      description: `وضعیت: ${o.status}`,
      href: o.href,
      created_at: o.created_at,
    });
  }
  for (const s of (opts.shipments ?? []).slice(0, 5)) {
    out.push({
      id: `shipment-${s.id}`,
      category: "shipment",
      subject: s.code ?? s.id,
      description: `وضعیت: ${s.status}`,
      href: s.href,
      created_at: s.created_at,
    });
  }
  for (const d of (opts.disputes ?? []).slice(0, 5)) {
    out.push({
      id: `dispute-${d.id}`,
      category: "dispute",
      subject: d.code ?? d.id,
      description: `وضعیت: ${d.status}`,
      href: d.href,
      created_at: d.created_at,
    });
  }
  for (const n of (opts.notifications ?? []).slice(0, 5)) {
    out.push({
      id: `notification-${n.id}`,
      category: "notification",
      subject: n.title,
      description: `دسته: ${n.category}`,
      href: n.href,
      created_at: n.created_at,
    });
  }
  out.sort((a, b) => b.created_at.localeCompare(a.created_at));
  return out.slice(0, 15);
}
