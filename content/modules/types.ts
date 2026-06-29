// iKIA product module inventory model. Source of truth for navigation,
// homepage grids, and module/service/solution/corridor landing pages.

export type ModuleStatus = "current" | "near-future" | "strategic-future";

export type ModuleCategory =
  | "freight"
  | "platform"
  | "value-added"
  | "solution"
  | "corridor";

export type ModuleDetail = {
  // Problem framing
  pains: { title: string; desc: string }[];
  // iKIA capabilities (icon = key from components/ui/icons)
  capabilities: { icon: string; title: string; desc: string }[];
  // Operational workflow
  steps: { title: string; desc: string }[];
  // Trust / controls
  controls: { title: string; desc: string }[];
};

export type ModuleEntry = {
  key: string;
  faTitle: string;
  enTitle: string;
  value: string; // one-line value proposition (fa)
  pain: string; // headline customer pain (fa)
  solution: string; // headline iKIA solution (fa)
  status: ModuleStatus;
  targetUsers: string[]; // fa audience labels
  route: string;
  icon: string; // icon key (components/ui/icons)
  cta: string; // CTA label (fa)
  category: ModuleCategory;
  detail?: ModuleDetail; // present for entries that have a dedicated landing page
};

// Persian + tone for the status badge shown across the site.
export const STATUS_META: Record<ModuleStatus, { label: string; tone: string }> = {
  current: { label: "فعال", tone: "bg-green/10 text-green ring-1 ring-green/20" },
  "near-future": { label: "به‌زودی", tone: "bg-blue/10 text-blue ring-1 ring-blue/20" },
  "strategic-future": { label: "نقشه‌ راه", tone: "bg-muted/10 text-muted ring-1 ring-muted/20" },
};
