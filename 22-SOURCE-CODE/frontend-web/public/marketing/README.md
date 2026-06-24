# iKIA Logistics — Public marketing image slots (CC-57)

This folder hosts the public-facing marketing imagery referenced by the
landing page at `src/app/(public)/page.tsx`. CC-57 does **not** ship any
image files; the landing renders fully with original CSS / SVG fallbacks
when files are absent (see `MarketingImageFrame` in
`src/components/marketing/marketing-image-frame.tsx`).

When images are added, the landing automatically picks them up — no code
change required beyond passing the path to the corresponding
`<MarketingImageFrame src="..." />` call site.

## Expected files

| File path | Used by | Recommended dimensions | Persian alt text |
|---|---|---|---|
| `hero-control-tower.webp` | Hero section behind the operational overlay | 1600 × 900, 16:9 | «نمای کنترل‌تاور عملیات لجستیک» |
| `logistics-truck-corridor.webp` | Corridor section panel | 1200 × 800, 3:2 | «کریدور حمل بار جاده‌ای ایران» |
| `port-container-operations.webp` | Visibility section panel | 1200 × 800, 3:2 | «عملیات بنادر و کانتینرها» |
| `driver-mobile-tracking.webp` | Driver console section panel | 1200 × 1200, 1:1 | «راننده با اپ موبایل ردیابی» |
| `warehouse-dispatch.webp` | Trust strip / roles section | 1200 × 800, 3:2 | «انبار و عملیات اعزام» |

## Asset rules (CC-57 boundaries)

- **No external image URLs.** Files must live under this folder.
- **No stock-photo downloads** without a clear license. Prefer original
  photography or commissioned imagery.
- **No raster files larger than ~250 KB** after compression. Prefer WebP
  with a quality setting of 75–82.
- **No autoplay video, no animated GIFs.**
- **No AI-generated imagery** unless explicitly authorized by the user.

## Fallback behavior

If any file in the table above is missing, the landing still renders. The
corresponding section will display its CSS/SVG fallback panel (a layered
dark-glass card composed from CC-54/CC-57 design tokens). The page never
shows a broken-image icon and never blocks the build.
