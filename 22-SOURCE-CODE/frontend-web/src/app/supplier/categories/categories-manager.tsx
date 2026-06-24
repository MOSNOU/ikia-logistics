"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { addMyCategory, removeMyCategory, type PortalActionState } from "@/lib/supplier/portal-actions";

interface CategoryOption {
  id: string;
  code: string;
  nameFa: string;
  nameEn: string;
  selected: boolean;
}

export function CategoriesManager({ categories }: { categories: CategoryOption[] }) {
  return (
    <ul className="divide-y">
      {categories.map((cat) => (
        <li key={cat.id} className="flex items-center justify-between gap-4 py-3">
          <div>
            <p className="text-sm font-medium">{cat.nameFa}</p>
            <p className="text-xs text-muted-foreground">{cat.nameEn} · {cat.code}</p>
          </div>
          {cat.selected ? (
            <CategoryForm action={removeMyCategory} categoryId={cat.id} label="حذف" variant="outline" />
          ) : (
            <CategoryForm action={addMyCategory} categoryId={cat.id} label="افزودن" variant="default" />
          )}
        </li>
      ))}
    </ul>
  );
}

interface CategoryFormProps {
  action: (prev: PortalActionState | null, fd: FormData) => Promise<PortalActionState>;
  categoryId: string;
  label: string;
  variant: "default" | "outline";
}

function CategoryForm({ action, categoryId, label, variant }: CategoryFormProps) {
  const [state, formAction, pending] = useActionState<PortalActionState | null, FormData>(
    action,
    null,
  );
  return (
    <form action={formAction} className="flex items-center gap-2">
      <input type="hidden" name="categoryId" value={categoryId} />
      <Button type="submit" size="sm" variant={variant} disabled={pending}>
        {pending ? "..." : label}
      </Button>
      {state?.error ? <span className="text-xs text-destructive">{state.error}</span> : null}
    </form>
  );
}
