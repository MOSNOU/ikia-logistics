"use client";

import { useCallback, useEffect, useState } from "react";
import { detectCapabilities, type DeviceCapabilities } from "./capabilities";
import {
  readGeolocationPermission,
  type GeoPermission,
} from "./permission-health";
import {
  getConsent,
  setConsent,
  revokeConsent,
  type ConsentRecord,
} from "./consent";
import { computeSessionHealth, type SessionHealth } from "./session-health";

// Phase K (v1.3) — readiness hook. Observes capabilities, permission health,
// consent and connectivity and computes session health. It does NOT request
// permission and does NOT start any tracking; the consent setters only persist
// intent locally.

export interface TrackingReadiness {
  capabilities: DeviceCapabilities | null;
  permission: GeoPermission;
  consent: ConsentRecord | null;
  online: boolean;
  health: SessionHealth | null;
  grantConsent: () => void;
  revokeConsent: () => void;
  refreshPermission: () => void;
}

export function useTrackingReadiness(): TrackingReadiness {
  const [capabilities, setCapabilities] = useState<DeviceCapabilities | null>(null);
  const [permission, setPermission] = useState<GeoPermission>("unknown");
  const [consent, setConsentState] = useState<ConsentRecord | null>(null);
  const [online, setOnline] = useState(true);

  const refreshPermission = useCallback(() => {
    void readGeolocationPermission().then(setPermission);
  }, []);

  useEffect(() => {
    setCapabilities(detectCapabilities());
    setConsentState(getConsent());
    setOnline(typeof navigator === "undefined" ? true : navigator.onLine);
    refreshPermission();

    const onOnline = () => setOnline(true);
    const onOffline = () => setOnline(false);
    const onVisible = () => refreshPermission();
    window.addEventListener("online", onOnline);
    window.addEventListener("offline", onOffline);
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      window.removeEventListener("online", onOnline);
      window.removeEventListener("offline", onOffline);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, [refreshPermission]);

  const grant = useCallback(() => setConsentState(setConsent(true)), []);
  const revoke = useCallback(() => setConsentState(revokeConsent()), []);

  const health = capabilities
    ? computeSessionHealth({ capabilities, permission, consent, online })
    : null;

  return {
    capabilities,
    permission,
    consent,
    online,
    health,
    grantConsent: grant,
    revokeConsent: revoke,
    refreshPermission,
  };
}
