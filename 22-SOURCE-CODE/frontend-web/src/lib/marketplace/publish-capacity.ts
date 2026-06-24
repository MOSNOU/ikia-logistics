"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { TransportMode } from "@/types/database";

export interface PublishCapacityState {
  ok?: boolean;
  error?: string;
  fieldErrors?: Record<string, string>;
}

const VALID_MODES: TransportMode[] = [
  "road",
  "rail",
  "sea",
  "air",
  "multimodal",
  "pipeline",
  "other",
];

function trimOrUndef(v: FormDataEntryValue | null): string | undefined {
  if (v == null) return undefined;
  const s = String(v).trim();
  return s.length === 0 ? undefined : s;
}

// CC-40: backed by marketplace.supplier_publish_capacity. The form lives under
// the supplier portal shell (CC-38 routing); the actual role gate is enforced
// inside the RPC, which requires carrier_admin / organization_admin /
// platform_admin on a `type='carrier'` org. If the caller's primary org is
// not a carrier, the RPC raises 22023; we surface that as a Persian error
// rather than letting it bubble.
export async function publishCapacity(
  _prev: PublishCapacityState | null,
  formData: FormData,
): Promise<PublishCapacityState> {
  const carrierOrganizationId = trimOrUndef(formData.get("carrierOrganizationId"));
  if (!carrierOrganizationId) {
    return {
      error: "سازمان حمل‌کننده مشخص نشده است.",
      fieldErrors: { carrierOrganizationId: "الزامی" },
    };
  }
  const transportMode = trimOrUndef(formData.get("transportMode")) as
    | TransportMode
    | undefined;
  if (!transportMode || !VALID_MODES.includes(transportMode)) {
    return {
      error: "مود حمل نامعتبر است.",
      fieldErrors: { transportMode: "الزامی" },
    };
  }

  const originCountry = trimOrUndef(formData.get("originCountry"));
  const originCity = trimOrUndef(formData.get("originCity"));
  const destinationCountry = trimOrUndef(formData.get("destinationCountry"));
  const destinationCity = trimOrUndef(formData.get("destinationCity"));
  const unitLabel = trimOrUndef(formData.get("capacityUnitLabel"));
  const validFrom = trimOrUndef(formData.get("validFrom"));
  const validUntil = trimOrUndef(formData.get("validUntil"));
  const notesFa = trimOrUndef(formData.get("notesFa"));
  const notesEn = trimOrUndef(formData.get("notesEn"));

  let capacityUnits: number | undefined;
  const unitsRaw = trimOrUndef(formData.get("capacityUnits"));
  if (unitsRaw) {
    const n = Number.parseFloat(unitsRaw);
    if (!Number.isFinite(n) || n < 0) {
      return {
        error: "مقدار ظرفیت نامعتبر است.",
        fieldErrors: { capacityUnits: "عدد نامعتبر" },
      };
    }
    capacityUnits = n;
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("marketplace")
    .rpc("supplier_publish_capacity", {
      p_carrier_organization_id: carrierOrganizationId,
      p_transport_mode: transportMode,
      p_origin_country: originCountry,
      p_origin_city: originCity,
      p_destination_country: destinationCountry,
      p_destination_city: destinationCity,
      p_capacity_units: capacityUnits,
      p_unit_label: unitLabel,
      p_valid_from: validFrom,
      p_valid_until: validUntil,
      p_notes_fa: notesFa,
      p_notes_en: notesEn,
    });
  if (error) {
    console.error("marketplace.supplier_publish_capacity", error);
    if (error.code === "22023") {
      return {
        error: "سازمان فعال شما از نوع حمل‌کننده نیست؛ امکان انتشار ظرفیت وجود ندارد.",
      };
    }
    if (error.code === "42501") {
      return {
        error: "برای انتشار ظرفیت نیاز به نقش carrier_admin روی سازمان حمل‌کننده دارید.",
      };
    }
    return { error: "ثبت ظرفیت ناموفق بود." };
  }

  revalidatePath("/supplier/marketplace");
  revalidatePath("/supplier/marketplace/capacity");
  revalidatePath("/supplier/marketplace/publish");
  revalidatePath("/admin/marketplace");
  revalidatePath("/admin/marketplace/activity");
  return { ok: true };
}

// CC-40: optional archive action exposed for forthcoming UI; not yet wired
// into the CC-38 supplier-capacity page (which lists but does not mutate).
// Available so a follow-on CC can add an archive button without changing
// the loader/action plumbing.
export async function archiveCapacity(
  _prev: PublishCapacityState | null,
  formData: FormData,
): Promise<PublishCapacityState> {
  const listingId = trimOrUndef(formData.get("listingId"));
  if (!listingId) return { error: "شناسه ظرفیت نامعتبر" };
  const reason = trimOrUndef(formData.get("reason"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("marketplace")
    .rpc("supplier_archive_capacity", {
      p_listing_id: listingId,
      p_reason: reason,
    });
  if (error) {
    console.error("marketplace.supplier_archive_capacity", error);
    if (error.code === "42501") {
      return {
        error: "برای بایگانی این ظرفیت باید مالک سازمان حمل‌کننده باشید.",
      };
    }
    return { error: "بایگانی ظرفیت ناموفق بود." };
  }
  revalidatePath("/supplier/marketplace/capacity");
  revalidatePath("/admin/marketplace/activity");
  return { ok: true };
}
