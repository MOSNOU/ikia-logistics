import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-medium transition-colors",
  {
    variants: {
      variant: {
        default: "border-transparent bg-primary text-primary-foreground",
        secondary: "border-transparent bg-secondary text-secondary-foreground",
        outline: "text-foreground",
        success: "border-transparent bg-emerald-100 text-emerald-900 dark:bg-emerald-900/30 dark:text-emerald-200",
        warning: "border-transparent bg-amber-100 text-amber-900 dark:bg-amber-900/30 dark:text-amber-200",
        danger: "border-transparent bg-red-100 text-red-900 dark:bg-red-900/30 dark:text-red-200",
        // CC-54: live / tracking / in-progress chip. Additive — no existing
        // call sites change; consumers opt in via variant="info".
        info: "border-transparent bg-sky-100 text-sky-900 dark:bg-sky-900/30 dark:text-sky-200",
        muted: "border-transparent bg-muted text-muted-foreground",
      },
    },
    defaultVariants: { variant: "default" },
  },
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ variant }), className)} {...props} />;
}

export { Badge, badgeVariants };
