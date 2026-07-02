// Phase K (v1.3) — Device Capability Detection (read-only).
//
// Pure feature-detection of the browser/device capabilities that a future
// background-tracking implementation would depend on. Detection only — nothing
// is activated here. SSR-safe (returns all-false on the server).

export interface DeviceCapabilities {
  geolocation: boolean;
  permissionsApi: boolean;
  visibilityApi: boolean;
  secureContext: boolean;
  standalonePwa: boolean;
  online: boolean;
  /** Presence of the SW API (detection only — v1.3 never registers one). */
  serviceWorkerApi: boolean;
  /** Presence of the Wake Lock API (readiness signal only). */
  wakeLockApi: boolean;
}

const NONE: DeviceCapabilities = {
  geolocation: false,
  permissionsApi: false,
  visibilityApi: false,
  secureContext: false,
  standalonePwa: false,
  online: false,
  serviceWorkerApi: false,
  wakeLockApi: false,
};

export function detectCapabilities(): DeviceCapabilities {
  if (typeof window === "undefined" || typeof navigator === "undefined") {
    return { ...NONE };
  }
  return {
    geolocation: "geolocation" in navigator,
    permissionsApi: "permissions" in navigator,
    visibilityApi:
      typeof document !== "undefined" && "visibilityState" in document,
    secureContext: window.isSecureContext === true,
    standalonePwa:
      window.matchMedia?.("(display-mode: standalone)").matches === true,
    online: navigator.onLine !== false,
    serviceWorkerApi: "serviceWorker" in navigator,
    wakeLockApi: "wakeLock" in navigator,
  };
}

export const CAPABILITY_LABEL: Record<keyof DeviceCapabilities, string> = {
  geolocation: "موقعیت‌یابی",
  permissionsApi: "API مجوزها",
  visibilityApi: "API نمایش صفحه",
  secureContext: "زمینه امن (HTTPS)",
  standalonePwa: "اجرای نصب‌شده (PWA)",
  online: "اتصال اینترنت",
  serviceWorkerApi: "سرویس‌ورکر",
  wakeLockApi: "قفل بیداری صفحه",
};
