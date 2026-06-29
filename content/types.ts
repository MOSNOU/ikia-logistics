// Shared content types for marketing pages.

export type Capability = {
  icon: string;
  title: string;
  desc: string;
};

export type Step = {
  title: string;
  desc: string;
};

export type Pain = {
  title: string;
  desc: string;
};

export type SEO = {
  title: string;
  description: string;
};

// Generic content for /platform/* and /services/* pages.
export type ContentPage = {
  slug: string;
  eyebrow: string;
  title: string;
  subtitle: string;
  intro: string;
  capabilities: Capability[];
  steps?: Step[];
  note?: string; // careful "not-yet-live" framing where relevant
  seo: SEO;
};

// Persona landing content for /forwarders, /shippers, /enterprise, /carriers.
export type Persona = {
  slug: string;
  badge: string;
  icon: string; // semantic icon key (see components/ui/icons)
  title: string;
  subtitle: string;
  image: string; // public/images/marketing/<slug>.webp (placeholder until provided)
  pains: Pain[];
  capabilities: Capability[];
  steps: Step[];
  cta: { label: string; href: string; note?: string };
  seo: SEO;
};
