import type { ExecutiveDashboardBundle } from "@/types/database";
import { listAdminRfqs } from "@/lib/admin/list-rfqs";
import { listAdminOffers } from "@/lib/admin/list-offers";
import { listAdminEvaluations } from "@/lib/admin/list-evaluations";
import {
  listAdminPreparations,
  listAdminExecuted,
} from "@/lib/admin/list-contracts";
import { listAdminShipments } from "@/lib/admin/list-shipments";
import { listAdminSettlements } from "@/lib/admin/list-settlements";
import { listAdminDisputes } from "@/lib/admin/list-disputes";
import { listKycVerifications } from "@/lib/admin/list-kyc-verifications";
import { getUnreadCount } from "@/lib/notify/unread-count";
import { listMyNotifications } from "@/lib/notify/list-my-notifications";
import { listAdminFinanceExceptions } from "@/lib/finance/list-exceptions";
import {
  buildKpis,
  buildPipeline,
  buildRisks,
  buildActivity,
} from "./compute-dashboard-kpis";

const PAGE = 100;

export async function loadAdminExecutiveDashboard(): Promise<ExecutiveDashboardBundle> {
  const [
    rfqRes,
    offerRes,
    evalRes,
    prepRes,
    execRes,
    shipRes,
    settleRes,
    disputeRes,
    kycOrgRes,
    kycPersonRes,
    unread,
    notifRes,
    financeExc,
  ] = await Promise.all([
    listAdminRfqs({ pageSize: PAGE }),
    listAdminOffers({ pageSize: PAGE }),
    listAdminEvaluations({ pageSize: PAGE }),
    listAdminPreparations({ pageSize: PAGE }),
    listAdminExecuted({ pageSize: PAGE }),
    listAdminShipments({ pageSize: PAGE }),
    listAdminSettlements({ pageSize: PAGE }),
    listAdminDisputes({ pageSize: PAGE }),
    listKycVerifications({ subjectType: "organization", pageSize: PAGE }),
    listKycVerifications({ subjectType: "person", pageSize: PAGE }),
    getUnreadCount(),
    listMyNotifications({ pageSize: 50 }),
    listAdminFinanceExceptions(),
  ]);

  const availability = {
    rfqs: true,
    offers: true,
    evaluations: true,
    contracts: true,
    shipments: true,
    settlements: true,
    disputes: true,
    kyc: true,
    notifications: true,
    financeExceptions: true,
  };

  const kycRows = [...kycOrgRes.rows, ...kycPersonRes.rows];

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
      financeExceptionCount: financeExc.length,
    },
    availability,
    "admin",
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
    "admin",
  );

  const risks = buildRisks(
    {
      settlements: settleRes.rows,
      disputes: disputeRes.rows,
      kycAttention: kycRows,
      highPriorityUnread,
    },
    availability,
    "admin",
  );

  const activity = buildActivity({
    rfqs: rfqRes.rows.slice(0, 5).map((r) => ({
      id: r.id,
      code: r.rfq_code,
      status: r.status,
      created_at: r.created_at,
      href: `/admin/rfqs/${r.id}`,
    })),
    offers: offerRes.rows.slice(0, 5).map((o) => ({
      id: o.id,
      code: o.offer_code,
      status: o.status,
      created_at: o.created_at,
      href: `/admin/offers/${o.id}`,
    })),
    shipments: shipRes.rows.slice(0, 5).map((s) => ({
      id: s.id,
      code: s.shipment_code,
      status: s.status,
      created_at: s.created_at,
      href: `/admin/shipments/${s.id}`,
    })),
    disputes: disputeRes.rows.slice(0, 5).map((d) => ({
      id: d.id,
      code: d.dispute_code,
      status: d.status,
      created_at: d.created_at,
      href: `/admin/disputes/${d.id}`,
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
    audience: "admin",
    kpis,
    pipeline,
    risks,
    activity,
    quickLinks: [
      { href: "/admin/rfqs", label: "RFQ", caption: "مدیریت درخواست‌های پیشنهاد" },
      { href: "/admin/offers", label: "پیشنهادها", caption: "بررسی پیشنهادهای دریافتی" },
      { href: "/admin/evaluations", label: "ارزیابی‌ها" },
      { href: "/admin/contracts", label: "قراردادها" },
      { href: "/admin/shipments", label: "شیپمنت‌ها" },
      { href: "/admin/finance", label: "مالی" },
      { href: "/admin/finance/exceptions", label: "استثناهای مالی" },
      { href: "/admin/settlements", label: "تسویه‌ها" },
      { href: "/admin/disputes", label: "اختلافات" },
      { href: "/admin/kyc", label: "KYC/KYB" },
      { href: "/admin/notifications", label: "اعلان‌ها" },
    ],
    unavailableSections: [],
  };
}
