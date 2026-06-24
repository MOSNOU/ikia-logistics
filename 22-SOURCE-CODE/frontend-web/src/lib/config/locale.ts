export const defaultLocale = "fa" as const;
export const locales = ["fa", "en"] as const;

export type Locale = (typeof locales)[number];

export const direction: Record<Locale, "rtl" | "ltr"> = {
  fa: "rtl",
  en: "ltr",
};

export function isLocale(value: string): value is Locale {
  return (locales as readonly string[]).includes(value);
}
