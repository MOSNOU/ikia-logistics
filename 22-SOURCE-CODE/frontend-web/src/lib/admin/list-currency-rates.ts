import { createClient } from "@/lib/supabase/server";
import type { CurrencyRateRow } from "@/types/database";

export interface ListCurrencyRatesParams {
  baseCode?: string | null;
  quoteCode?: string | null;
  asOf?: string | null;
}

export async function listCurrencyRates({
  baseCode = null,
  quoteCode = null,
  asOf = null,
}: ListCurrencyRatesParams = {}): Promise<CurrencyRateRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .rpc("list_currency_rates", {
      p_base_code: baseCode ?? undefined,
      p_quote_code: quoteCode ?? undefined,
      p_as_of: asOf ?? undefined,
    });
  if (error) {
    console.error("list_currency_rates", error);
    return [];
  }
  return (data ?? []) as unknown as CurrencyRateRow[];
}
