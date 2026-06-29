import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    // The product app is a separate, self-contained Next.js project with its
    // own lint/build pipeline; the marketing app must not lint its sources or
    // build artifacts.
    "22-SOURCE-CODE/**",
    "public/**",
  ]),
]);

export default eslintConfig;
