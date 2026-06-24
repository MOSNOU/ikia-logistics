import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { TransportMode } from "@/types/database";

interface Props {
  action: string;
  initial?: {
    transportMode?: TransportMode | "";
    originCountry?: string;
    destinationCountry?: string;
    search?: string;
  };
  showSearch?: boolean;
  showMode?: boolean;
  showRoute?: boolean;
}

const MODE_OPTIONS: { value: TransportMode | ""; label: string }[] = [
  { value: "", label: "همه مودها" },
  { value: "road", label: "جاده" },
  { value: "rail", label: "ریل" },
  { value: "sea", label: "دریا" },
  { value: "air", label: "هوا" },
  { value: "multimodal", label: "ترکیبی" },
  { value: "pipeline", label: "خط لوله" },
  { value: "other", label: "سایر" },
];

export function MarketplaceFilters({
  action,
  initial,
  showSearch = true,
  showMode = true,
  showRoute = true,
}: Props) {
  return (
    <form action={action} className="flex flex-wrap items-end gap-3">
      {showSearch ? (
        <div className="space-y-1">
          <label htmlFor="search" className="text-xs text-muted-foreground">جستجو</label>
          <Input
            id="search"
            name="search"
            defaultValue={initial?.search ?? ""}
            placeholder="نام یا کد"
            className="h-9"
          />
        </div>
      ) : null}
      {showMode ? (
        <div className="space-y-1">
          <label htmlFor="transportMode" className="text-xs text-muted-foreground">مود حمل</label>
          <select
            id="transportMode"
            name="transportMode"
            defaultValue={initial?.transportMode ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {MODE_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
      ) : null}
      {showRoute ? (
        <>
          <div className="space-y-1">
            <label htmlFor="originCountry" className="text-xs text-muted-foreground">مبدأ</label>
            <Input
              id="originCountry"
              name="originCountry"
              defaultValue={initial?.originCountry ?? ""}
              dir="ltr"
              className="h-9"
              placeholder="IR"
            />
          </div>
          <div className="space-y-1">
            <label htmlFor="destinationCountry" className="text-xs text-muted-foreground">مقصد</label>
            <Input
              id="destinationCountry"
              name="destinationCountry"
              defaultValue={initial?.destinationCountry ?? ""}
              dir="ltr"
              className="h-9"
              placeholder="DE"
            />
          </div>
        </>
      ) : null}
      <Button type="submit" variant="outline">اعمال فیلتر</Button>
    </form>
  );
}
