// Phase K (v1.3) — Permission Health (read-only).
//
// Reads the geolocation permission state via the Permissions API. Never
// requests permission and never starts geolocation — inspection only.

export type GeoPermission =
  | "granted"
  | "denied"
  | "prompt"
  | "unsupported"
  | "unknown";

export async function readGeolocationPermission(): Promise<GeoPermission> {
  if (typeof navigator === "undefined" || !("geolocation" in navigator)) {
    return "unsupported";
  }
  if (!("permissions" in navigator) || !navigator.permissions?.query) {
    return "unknown";
  }
  try {
    const status = await navigator.permissions.query({ name: "geolocation" });
    const s = status.state as GeoPermission;
    return s === "granted" || s === "denied" || s === "prompt" ? s : "unknown";
  } catch {
    return "unknown";
  }
}

export const GEO_PERMISSION_LABEL: Record<GeoPermission, string> = {
  granted: "اجازه داده‌شده",
  denied: "رد شده",
  prompt: "در انتظار درخواست",
  unsupported: "پشتیبانی‌نشده",
  unknown: "نامشخص",
};
