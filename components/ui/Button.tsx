import Link from "next/link";
import type { ReactNode } from "react";

type Variant = "primary" | "accent" | "light" | "outline" | "outlineLight" | "ghost";
type Size = "sm" | "md" | "lg";

const base =
  "inline-flex items-center justify-center gap-2 rounded-xl font-bold whitespace-nowrap transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2";

const variants: Record<Variant, string> = {
  primary: "bg-brand-600 text-white shadow-sm hover:bg-brand-700 hover:shadow-md hover:-translate-y-0.5",
  accent: "bg-accent-600 text-white shadow-sm hover:bg-accent-500 hover:shadow-md hover:-translate-y-0.5",
  light: "bg-white text-navy-900 shadow-sm hover:bg-slate-100 hover:-translate-y-0.5",
  outline: "border border-navy-900/15 text-navy-900 hover:border-navy-900/30 hover:bg-slate-50",
  outlineLight: "border border-white/30 text-white hover:bg-white hover:text-navy-900",
  ghost: "text-navy-800 hover:bg-slate-100",
};

const sizes: Record<Size, string> = {
  sm: "px-4 py-2 text-sm",
  md: "px-5 py-2.5 text-sm",
  lg: "px-7 py-3.5 text-base",
};

export function Button({
  children,
  href,
  variant = "primary",
  size = "md",
  className = "",
  external,
}: {
  children: ReactNode;
  href: string;
  variant?: Variant;
  size?: Size;
  className?: string;
  external?: boolean;
}) {
  const cls = `${base} ${variants[variant]} ${sizes[size]} ${className}`;
  if (external) {
    return (
      <a href={href} className={cls} rel="noopener noreferrer">
        {children}
      </a>
    );
  }
  return (
    <Link href={href} className={cls}>
      {children}
    </Link>
  );
}
