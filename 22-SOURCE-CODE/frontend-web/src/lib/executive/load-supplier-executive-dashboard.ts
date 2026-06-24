import type { ExecutiveDashboardBundle } from "@/types/database";
import { listSupplierRfqs } from "@/lib/rfq/list-supplier-rfqs";
import { listSupplierOffers } from "@/lib/offer/list-supplier-offers";
import {
  listSupplierPreparations,
  listSupplierExecuted,
} from "@/lib/contract/list-supplier-contracts";
import { listSupplierShipments } from "@/lib/shipment/list-supplier-shipments";
import { listSupplierSettlements } from "@/lib/settlement/list-supplier-settlements";
import { listSupplierDisputes } from "@/lib/dispute/list-supplier-disputes";
import { getMyOrganizationVerification } from "@/lib/kyc/get-my-organization-verification";
import { getMyPersonalVerification } from "@/lib/kyc/get-my-personal-verification";
import { getUnreadCount } from "@/lib/notify/unread-count";
import { listMyNotifications } from "@/lib/notify/list-my-notifications";
import {
  buildKpis,
  buildPipeline,
  buildRisks,
  buildActivity,
} from "./compute-dashboard-kpis";

const PAGE = 100;

export async function loadSupplierExecutiveDashboard(opts: {
  primaryOrganizationId: string | null;
}): Promise<ExecutiveDashboardBundle> {
  const orgId = opts.primaryOrganizationId;

  const [
    rfqRes,
    offerRes,
    prepRes,
    execRes,
    shipRes,
    settleRes,
    disputeRes,
    kycOrg,
    kycPerson,
    unread,
    notifRes,
  ] = await Promise.all([
    listSupplierRfqs({ pageSize: PAGE }),
    listSupplierOffers({ pageSize: PAGE }),
    listSupplierPreparations({ pageSize: PAGE }),
    listSupplierExecuted({ pageSize: PAGE }),
    listSupplierShipments({ pageSize: PAGE }),
    listSupplierSettlements({ pageSize: PAGE }),
    listSupplierDisputes({ pageSize: PAGE }),
    orgId ? getMyOrganizationVerification(orgId) : Promise.resolve(null),
    getMyPersonalVerification(),
    getUnreadCount(),
    listMyNotifications({ pageSize: 50 }),
  ]);

  const availability = {
    rfqs: true,
    offers: true,
    // Suppliers do not have a list-evaluations RPC exposed on the frontend.
    // Mark unavailable so the dashboard shows an "N/A" tile instead of 0.
    evaluations: false,
    contracts: true,
    shipments: true,
    settlements: true,
    disputes: true,
    kyc: true,
    notifications: true,
    financeExceptions: false,
  };

  const unavailable: string[] = [
    "نمای ارزیابی‌ها برای تأمین‌کننده در دسترس نیست (RPC مربوطه برای این نقش وجود ندارد).",
  ];
  if (!orgId) {
    unavailable.push("سازمان فعال برای کاربر تعیین نشده — KYB سازمانی غیرفعال است.");
  }

  const kycRows = [
    ...(kycOrg ? [{ status: String(kycOrg.status) }] : []),
    { status: String(kycPerson.status) },
  ];

  const highPriorityUnread = notifRes.rows.filter(
    (n) => n.status === "unread" && (n.priority === "high" || n.priority === "urgent"),
  ).length;

  // supplier_list_offers row uses `submitted_at`/`updated_at`; rfqs come as
  // SupplierRfqInvitationRow (invitation-shape). Normalize for activity/KPI use.
  const rfqRowsNormalized = rfqRes.rows.map((r) => ({
    id: r.request_id,
    rfq_code: r.rfq_code,
    title: r.title,
    status: r.request_status,
    created_at: r.invited_at,
  }));

  const kpis = buildKpis(
    {
      rfqs: rfqRowsNormalized,
      offers: offerRes.rows,
      evaluations: [],
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
    "supplier",
  );

  const pipeline = buildPipeline(
    {
      rfqs: rfqRowsNormalized,
      offers: offerRes.rows,
      evaluations: [],
      contractPreparations: prepRes.rows,
      shipments: shipRes.rows,
      settlements: settleRes.rows,
    },
    availability,
    "supplier",
  );

  const risks = buildRisks(
    {
      settlements: settleRes.rows,
      disputes: disputeRes.rows,
      kycAttention: kycRows,
      highPriorityUnread,
    },
    availability,
    "supplier",
  );

  const activity = buildActivity({
    rfqs: rfqRowsNormalized.slice(0, 5).map((r) => ({
      id: r.id,
      code: r.rfq_code,
      status: r.status,
      created_at: r.created_at,
      href: `/supplier/rfqs/${r.id}`,
    })),
    offers: offerRes.rows.slice(0, 5).map((o) => ({
      id: o.id,
      code: o.offer_code,
      status: o.status,
      created_at: o.created_at,
      href: `/supplier/offers/${o.id}`,
    })),
    shipments: shipRes.rows.slice(0, 5).map((s) => ({
      id: s.id,
      code: s.shipment_code,
      status: s.status,
      created_at: s.created_at,
      href: `/supplier/shipments/${s.id}`,
    })),
    disputes: disputeRes.rows.slice(0, 5).map((d) => ({
      id: d.id,
      code: d.dispute_code,
      status: d.status,
      created_at: d.created_at,
      href: `/supplier/disputes/${d.id}`,
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
    audience: "supplier",
    kpis,
    pipeline,
    risks,
    activity,
    quickLinks: [
      { href: "/supplier/rfqs", label: "RFQ‌های دعوت‌شده" },
      { href: "/supplier/offers", label: "پیشنهادهای من" },
      { href: "/supplier/contracts", label: "قراردادها" },
      { href: "/supplier/shipments", label: "شیپمنت‌ها" },
      { href: "/supplier/trade-documents", label: "مدارک تجاری" },
      { href: "/supplier/finance", label: "مالی" },
      { href: "/supplier/settlements", label: "تسویه‌ها" },
      { href: "/supplier/disputes", label: "اختلافات" },
      { href: "/supplier/kyb", label: "KYB سازمانی" },
      { href: "/inbox", label: "صندوق اعلان‌ها" },
    ],
    unavailableSections: unavailable,
  };
}
