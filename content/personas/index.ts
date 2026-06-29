import type { Persona } from "../types";
import { FORWARDERS } from "./forwarders";
import { SHIPPERS } from "./shippers";
import { ENTERPRISE } from "./enterprise";
import { CARRIERS } from "./carriers";

export { FORWARDERS, SHIPPERS, ENTERPRISE, CARRIERS };

export const PERSONAS: Record<string, Persona> = {
  forwarders: FORWARDERS,
  shippers: SHIPPERS,
  enterprise: ENTERPRISE,
  carriers: CARRIERS,
};

// Used by the homepage persona-routing section.
export const PERSONA_LIST: Persona[] = [FORWARDERS, SHIPPERS, ENTERPRISE, CARRIERS];
