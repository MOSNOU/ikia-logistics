import type { ExecutiveDashboardBundle } from "@/types/database";
import { listBuyerRfqs } from "@/lib/rfq/list-buyer-rfqs";
import { listBuyerReceivedOffers } from "@/lib/offer/list-buyer-offers";
import { listBuyerEvaluations } from "@/lib/evaluation/list-buyer-evaluations";
import {
  listBuyerPreparations,
  listBuyerExecuted,
} from "@/lib/contract/list-buyer-contracts";
import { listBuyerShipments } from "@/lib/shipment/list-buyer-shipments";
import { listBuyerSettlements } from "@/lib/settlement/list-buyer-settlements";
import { listBuyerDisputes } from "@/lib/dispute/list-buyer-disputes";
import { getMyOrganizationVerification } from "@/lib/kyc/get-my-organization-verification";
import { getUnreadCount } from "@/lib/notify/unread-count";
import { listMyNotifications } from "@/lib/notify/list-my-notifications";
import {
  buildKpis,
  buildPipeline,
  buildRisks,
  buildActivity,
} from "./compute-dashboard-kpis";

const PAGE = 100;

export async function loadBuyerExecutiveDashboard(opts: {
  primaryOrganizationId: string | null;
}): Promise<ExecutiveDashboardBundle> {
  const orgId = opts.primaryOrganizationId;

  const [
    rfqRes,
    offerRes,
    evalRes,
    prepRes,
    execRes,
    shipRes,
    settleRes,
    disputeRes,
    kycOrg,
    unread,
    notifRes,
  ] = await Promise.all([
    listBuyerRfqs({ pageSize: PAGE }),
    listBuyerReceivedOffers({ pageSize: PAGE }),
    listBuyerEvaluations({ pageSize: PAGE }),
    listBuyerPreparations({ pageSize: PAGE }),
    listBuyerExecuted({ pageSize: PAGE }),
    listBuyerShipments({ pageSize: PAGE }),
    listBuyerSettlements({ pageSize: PAGE }),
    listBuyerDisputes({ pageSize: PAGE }),
    orgId ? getMyOrganizationVerification(orgId) : Promise.resolve(null),
    getUnreadCount(),
    listMyNotifications({ pageSize: 50 }),
  ]);

  const availability = {
    rfqs: true,
    offers: true,
    evaluations: true,
    contracts: true,
    shipments: true,
    settlements: true,
    disputes: true,
    kyc: Boolean(orgId),
    notifications: true,
    financeExceptions: false,
  };

  const unavailable: string[] = [];
  if (!orgId) unavailable.push("سازمان فعال برای کاربر تعیین نشده — بخش KYB غیرفعال است");

  // For buyer-org KYB, we have a single verification record. Convert it into
  // a single-row "list" so the count-by-status helpers can work uniformly.
  const kycRows = kycOrg
    ? [{ status: String(kycOrg.status) }]
    : [];

  const highPriorityUnread = notifRes.rows.filter(
    (n) => n.status === "unread" && (n.priority === "high" || n.priority === "urgent"),
  ).length;

  const kpis = buildKpis(
    {
      rfqs: rfqRes.rows,
      offers: offerRes.rows,
      evaluations: evalRes.rows,
      contractPreparations: prepRes.rows,
      executedContractCount: execRes.rows.length,
      shipments: shipRes.rows,
      settlements: settleRes.rows,
      disputes: disputeRes.rows,
      kycVerifications: kycRows,
      unreadNotifications: unread,
      financeExceptionCount: 0,
    },
    availability,
    "buyer",
  );

  const pipeline = buildPipeline(
    {
      rfqs: rfqRes.rows,
      offers: offerRes.rows,
      evaluations: evalRes.rows,
      contractPreparations: prepRes.rows,
      shipments: shipRes.rows,
      settlements: settleRes.rows,
    },
    availability,
    "buyer",
  );

  const risks = buildRisks(
    {
      settlements: settleRes.rows,
      disputes: disputeRes.rows,
      kycAttention: kycRows,
      highPriorityUnread,
    },
    availability,
    "buyer",
  );

  const activity = buildActivity({
    rfqs: rfqRes.rows.slice(0, 5).map((r) => ({
      id: r.id,
      code: r.rfq_code,
      status: r.status,
      created_at: r.created_at,
      href: `/buyer/rfqs/${r.id}`,
    })),
    offers: offerRes.rows.slice(0, 5).map((o) => ({
      id: o.id,
      code: o.offer_code,
      status: o.status,
      created_at: o.created_at,
      href: `/buyer/offers`,
    })),
    shipments: shipRes.rows.slice(0, 5).map((s) => ({
      id: s.id,
      code: s.shipment_code,
      status: s.status,
      created_at: s.created_at,
      href: `/buyer/shipments/${s.id}`,
    })),
    disputes: disputeRes.rows.slice(0, 5).map((d) => ({
      id: d.id,
      code: d.dispute_code,
      status: d.status,
      created_at: d.created_at,
      href: `/buyer/disputes/${d.id}`,
    })),
    notifications: notifRes.rows.slice(0, 5).map((n) => ({
      id: n.id,
      title: n.title_fa || n.title_en,
      category: n.category,
      created_at: n.created_at,
      href: n.action_url ?? `/inbox/${n.id}`,
    })),
  });

  return {
    audience: "buyer",
    kpis,
    pipeline,
    risks,
    activity,
    quickLinks: [
      { href: "/buyer/rfqs", label: "RFQ‌های من" },
      { href: "/buyer/offers", label: "پیشنهادهای دریافتی" },
      { href: "/buyer/evaluations", label: "ارزیابی‌ها" },
      { href: "/buyer/contracts", label: "قراردادها" },
      { href: "/buyer/shipments", label: "شیپمنت‌ها" },
      { href: "/buyer/finance", label: "مالی" },
      { href: "/buyer/settlements", label: "تسویه‌ها" },
      { href: "/buyer/disputes", label: "اختلافات" },
      { href: "/buyer/documents", label: "مدارک تجاری" },
      { href: "/inbox", label: "صندوق اعلان‌ها" },
    ],
    unavailableSections: unavailable,
  };
}
