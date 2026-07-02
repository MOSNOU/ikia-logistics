// Phase K (v1.3) — Driver Consent Manager.
//
// Records the driver's explicit opt-in for (future) continuous location
// sharing. Persisted in localStorage ONLY (no IndexedDB, no cookies, no server
// write). This stores intent; it does NOT start any tracking. Versioned so a
// future consent-copy change can re-prompt.

const STORAGE_KEY = "ikia.driver.tracking.consent.v1";
export const CONSENT_VERSION = 1;

export interface ConsentRecord {
  granted: boolean;
  version: number;
  /** ISO timestamp of the decision. */
  at: string;
}

function storage(): Storage | null {
  try {
    if (typeof window === "undefined" || !window.localStorage) return null;
    return window.localStorage;
  } catch {
    return null;
  }
}

export function getConsent(): ConsentRecord | null {
  const s = storage();
  if (!s) return null;
  try {
    const raw = s.getItem(STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<ConsentRecord>;
    if (typeof parsed.granted !== "boolean") return null;
    return {
      granted: parsed.granted,
      version: typeof parsed.version === "number" ? parsed.version : 0,
      at: typeof parsed.at === "string" ? parsed.at : "",
    };
  } catch {
    return null;
  }
}

export function setConsent(granted: boolean): ConsentRecord {
  const record: ConsentRecord = {
    granted,
    version: CONSENT_VERSION,
    at: new Date().toISOString(),
  };
  const s = storage();
  if (s) {
    try {
      s.setItem(STORAGE_KEY, JSON.stringify(record));
    } catch {
      /* ignore quota / disabled storage — consent simply won't persist */
    }
  }
  return record;
}

export function revokeConsent(): ConsentRecord {
  return setConsent(false);
}

/** Active only when granted AND for the current consent version. */
export function hasActiveConsent(record: ConsentRecord | null): boolean {
  return !!record && record.granted && record.version === CONSENT_VERSION;
}
