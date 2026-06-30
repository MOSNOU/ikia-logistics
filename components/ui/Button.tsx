import Link from "next/link";
import type { ReactNode } from "react";

type Variant = "primary" | "green" | "light" | "outline" | "outlineLight" | "ghost" | "subtle";
type Size = "sm" | "md" | "lg";

const base =
  "inline-flex items-center justify-center gap-2 rounded-xl font-semibold whitespace-nowrap transition-colors duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue/40 focus-visible:ring-offset-2";

const variants: Record<Variant, string> = {
  primary: "bg-blue text-white shadow-[0_8px_20px_-12px_rgba(11,92,173,0.65)] hover:bg-blue-hover",
  green: "bg-[#16a34a] text-white shadow-[0_8px_20px_-12px_rgba(22,163,74,0.6)] hover:bg-[#15803d]",
  light: "bg-white text-ink shadow-sm ring-1 ring-line hover:bg-soft",
  outline: "border border-line text-ink hover:border-blue/40 hover:text-blue",
  outlineLight: "border border-white/30 text-white hover:bg-white/10",
  ghost: "text-ink hover:bg-soft",
  subtle: "bg-soft text-ink ring-1 ring-line hover:bg-soft-2",
};

const sizes: Record<Size, string> = {
  sm: "h-11 px-5 text-sm",
  md: "h-11 px-5 text-[15px]",
  lg: "h-12 px-6 text-[15px]",
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
