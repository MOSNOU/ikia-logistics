# CC-69 — Full Visible Flexport-Level Homepage Rebuild for iKIA Logistics

این فایل را می‌توانی مستقیم به Claude Code بدهی. هدف این است که صفحه اصلی iKIA Logistics به‌صورت کاملاً قابل مشاهده و جدی بازطراحی شود؛ نه فقط چند تغییر کوچک در متن یا کلاس‌ها.

---

## 1. Mission

Act as an elite UI/UX director, senior product designer, logistics SaaS product architect, and Next.js/Tailwind engineer.

Rebuild the public homepage as a Flexport-inspired enterprise logistics platform website.

The redesign must be visibly obvious in the browser. The first viewport, middle sections, and footer must clearly look different, more premium, and closer to a global logistics SaaS/product platform.

Do not make tiny cosmetic edits.

---

## 2. Repository

```text
/Users/mostafanourabi/Desktop/iKIA-LOGISTICS
```

Frontend:

```text
22-SOURCE-CODE/frontend-web
```

Primary files to inspect/edit:

```text
src/app/(public)/layout.tsx
src/app/(public)/page.tsx
src/app/globals.css
src/styles/tokens.css
src/components/marketing/
```

Do not touch:

```text
backend
database
Supabase
auth/admin logic
package/config files
Vercel files
00-PROJECT-BRIEFS/
Markdown guide files
```

---

## 3. Legal / Brand Rule

Use Flexport only as a benchmark for:

- color rhythm
- enterprise logistics information architecture
- dark/light section alternation
- product dashboard visual language
- header/footer structure
- clean B2B SaaS layout
- trust/proof sections
- logistics platform storytelling

Do not copy Flexport logos, proprietary text, images, videos, screenshots, or exact assets.

Use iKIA identity and original Persian copy.

---

## 4. Design Language

The website must feel:

```text
Serious · Technical · Enterprise · Global Logistics · Product Platform
```

It must not look like a generic corporate transport website or brochure.

The visual language should use:

- Midnight navy
- Clean white / porcelain backgrounds
- Bright blue accents
- Limited green for success/status
- Limited red for secondary action or iKIA accent
- 12-column grid feeling
- Large breathing space, but no empty dead white gaps
- Product UI panels instead of brochure cards
- Dashboard mockups, route lines, status chips, document tiles, metric cards
- Strong typography hierarchy
- RTL-first
- Mobile-first

---

## 5. Color Tokens

Ensure these tokens exist and are used consistently:

```css
:root {
  --color-ink:        #0A1B2E;
  --color-ink-2:      #0E2640;
  --color-navy:       #103A5E;
  --color-blue:       #0B6FB5;
  --color-blue-bright:#1F9CE0;
  --color-cerulean:   #0093BF;

  --color-accent:     #15C26B;
  --color-warn:       #F5A623;
  --color-ikia-red:   #D8202A;

  --color-white:      #FFFFFF;
  --color-bg-soft:    #F5F8FB;
  --color-bg-soft-2:  #EEF3F8;
  --color-border:     #D6E0EA;
  --color-text:       #0A1B2E;
  --color-text-muted: #51637A;
  --color-text-onDark:#E8F0F8;
  --color-muted-onDark:#9FB4C9;

  --shadow-card: 0 8px 30px rgba(10, 27, 46, 0.08);
  --shadow-pop:  0 16px 50px rgba(10, 27, 46, 0.16);
}
```

Color rhythm:

- 60% white / soft backgrounds
- 30% midnight navy / dark sections
- 10% blue, green, and red accents

Never use random gradients everywhere.

---

## 6. Typography

Use strong typographic hierarchy:

```css
:root {
  --font-display: "Plus Jakarta Sans", "Vazirmatn", sans-serif;
  --font-body:    "Inter", "Vazirmatn", sans-serif;

  --fs-hero:   clamp(2.6rem, 5vw, 4.25rem);
  --fs-h2:     clamp(1.9rem, 3.2vw, 2.75rem);
  --fs-h3:     1.5rem;
  --fs-lead:   1.25rem;
  --fs-body:   1rem;
  --fs-small:  0.875rem;
  --fs-eyebrow:0.8125rem;

  --lh-tight: 1.1;
  --lh-base:  1.6;
  --fw-reg: 400;
  --fw-med: 500;
  --fw-semi: 600;
  --fw-bold: 700;
}
```

Rules:

- Hero headline: 44–68px, bold, line-height 1.1.
- Section H2: 32–44px.
- Eyebrow: small, letter-spaced, blue accent.
- Body: muted navy/slate, never too heavy.

---

## 7. Required Homepage Structure

The page should not feel like 25–30 scattered sections.

Preferred visible structure:

```text
1. Announcement Bar
2. Sticky Header
3. Hero with product UI panel
4. Trust / Proof Strip
5. Platform Capability Grid
6. Control Tower Product Dashboard
7. Freight Marketplace / Services
8. Shipment Lifecycle Timeline
9. Corridor Network Visual
10. Industries Compact Grid
11. Final Dark CTA
12. Footer
```

Rhythm:

```text
Dark Hero
Light Trust
White Platform Grid
Dark Product Dashboard
Light Services
White Industries
Dark CTA
Dark Footer
```

No huge blank white gaps.

---

## 8. Header and Announcement

Rebuild the public header to feel like a global SaaS logistics platform:

- slim announcement bar
- sticky white/glass header
- compact official iKIA logo
- clear nav labels
- clean CTA buttons
- mobile responsive

Navigation labels:

```text
پلتفرم
خدمات حمل
راهکارها
کریدورها
بازار حمل
اسناد و تطبیق
درباره ما
```

Public CTAs must not send users to `/login`, because there is no active user account yet.

Use:

```text
درخواست جلسه معرفی → #start
مشاهده پلتفرم → #platform
```

---

## 9. Hero — Must Be Visibly Different

Hero must feel like a logistics operating system, not a photo banner.

Requirements:

- dark navy atmosphere
- right-aligned Persian copy
- massive headline
- visible product UI panel / dashboard mockup
- no generic photo-only hero
- product-platform feeling must be obvious

Headline:

```text
سامانه عملیاتی لجستیک برای کنترل حمل، اسناد و زنجیره تأمین
```

Subhead:

```text
از ثبت سفارش تا تخصیص ناوگان، رهگیری، اسناد گمرکی، تطبیق و تسویه — همه در یک پلتفرم واحد برای بازار ایران و کریدورهای منطقه‌ای.
```

Primary CTA:

```text
درخواست جلسه معرفی
href: #start
```

Secondary CTA:

```text
مشاهده پلتفرم
href: #platform
```

Hero product UI panel should include:

```text
iKIA OS
Shipment ID
Live status
route/corridor row
document compliance
ETA
status chips
```

---

## 10. Platform Capability Grid

Create a clean 2×3 desktop grid:

- Control Tower
- Freight Marketplace
- Documents & Compliance
- Route Intelligence
- Settlement
- Partner Portal

Each card:

- line icon
- English code chip
- Persian title
- short Persian description
- `مشاهده ←` action link
- premium white card
- hover-lift
- blue top accent line

Title:

```text
یک پلتفرم عملیاتی برای کنترل کل زنجیره حمل
```

---

## 11. Control Tower Product Dashboard

This must be one of the strongest visual sections.

Design:

- full-width dark navy section
- two-column layout
- text on one side
- large product dashboard mockup on the other side

Dashboard elements:

```text
Window chrome bar
iKIA OS
Shipment SH-2026-08471
Live
Route: تهران → بندرعباس
ETA
Route line
Document tiles:
  - اظهارنامه
  - بارنامه
  - بیمه
  - گواهی مبدأ
Metric cards:
  - زمان تحویل
  - نرخ تطبیق ظرفیت
  - تأخیر فعال
Status chips:
  - Booked
  - Dispatched
  - In Transit
  - Delivered
```

Headline:

```text
برج کنترل دیجیتال برای دیدن، تصمیم‌گیری و اقدام در لحظه
```

---

## 12. Shipment Lifecycle

Make this section lean and elegant.

Use an 8-state timeline:

```text
Draft / پیش‌نویس
Ready / آماده
Matched / تطبیق
Booked / رزرو
Dispatched / اعزام
In Transit / در مسیر
Delivered / تحویل
Reconciled / تسویه
```

Avoid repeating the full Control Tower dashboard here.

---

## 13. Services / Transport Modes

Show 6 modes:

```text
جاده‌ای
ریلی
دریایی
هوایی
انبارداری
گمرک و تطبیق
```

Preserve existing slider behavior if it exists:

- 4-second auto-advance
- RTL motion
- pause on hover/focus
- reduced-motion support

The section wrapper must feel premium and integrated, not floating in empty white space.

---

## 14. Corridor Network Section

Create a visual network using pure inline SVG/CSS.

Nodes:

```text
ایران
ترکیه
قفقاز
آسیای میانه
خلیج فارس
```

Include:

- route lines
- active/dashed line legend
- regional network feel
- no new image
- no new dependency

Title:

```text
کریدورهای منطقه‌ای را مثل یک شبکه زنده مدیریت کنید
```

---

## 15. Industries Section

Compact 6-card grid:

```text
فولاد و معدن
نفت و پتروشیمی
کشاورزی و مواد غذایی
کالاهای مصرفی
پروژه‌های صنعتی
صادرات و واردات
```

No huge separate industry sections.

---

## 16. Trust / Proof Section

Use strong proof metrics:

```text
24/7 — رؤیت لحظه‌ای
4 — شیوه حمل متصل
8 — وضعیت چرخه عمر
1 — سیستم عامل لجستیک
```

Add line:

```text
طراحی‌شده برای شرکت‌های صنعتی، بازرگانی، حمل‌ونقل و فعالان کریدورهای منطقه‌ای.
```

---

## 17. Final CTA

Dark navy, premium, not generic.

Headline:

```text
زنجیره حمل خود را روی یک پلتفرم واحد ببینید و کنترل کنید
```

Subhead:

```text
برای هماهنگی حمل، بازار ظرفیت، اسناد، تطبیق، رهگیری و تسویه — یک جریان عملیاتی واحد بسازید.
```

Buttons:

```text
درخواست جلسه معرفی → #start
مشاهده پلتفرم → #platform
```

---

## 18. Footer

Deep navy 4-column footer:

```text
پلتفرم
خدمات
منابع
شرکت
```

Rules:

- no endless long lists
- no broken anchors
- muted text on dark
- white/blue on hover
- compact and premium

---

## 19. Example Hero Pattern

Use this as inspiration. Adapt to existing project conventions.

```tsx
<section className="relative isolate min-h-screen overflow-hidden bg-[#0A1B2E] text-white">
  <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(31,156,224,0.25),transparent_35%),linear-gradient(135deg,#0A1B2E_0%,#0E2640_55%,#103A5E_100%)]" />
  <div className="absolute inset-0 opacity-30 [background-image:linear-gradient(rgba(255,255,255,.06)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,.06)_1px,transparent_1px)] [background-size:64px_64px]" />

  <div className="relative mx-auto grid min-h-screen max-w-[1320px] items-center gap-12 px-6 py-28 lg:grid-cols-[0.95fr_1.05fr]">
    <div className="order-2 lg:order-1">
      <div className="rounded-2xl border border-white/10 bg-white/[0.06] p-4 shadow-2xl backdrop-blur">
        <div className="mb-4 flex items-center justify-between border-b border-white/10 pb-3">
          <span className="font-mono text-xs text-sky-200">iKIA OS · Live Shipment</span>
          <span className="rounded-full bg-emerald-400/15 px-3 py-1 text-xs font-semibold text-emerald-200">Live</span>
        </div>

        <div className="space-y-4">
          <div className="rounded-xl bg-white/[0.07] p-4">
            <div className="mb-2 flex items-center justify-between">
              <span className="text-sm text-white/70">Shipment ID</span>
              <span className="font-mono text-sm text-white">SH-2026-08471</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span>تهران</span>
              <span className="mx-4 h-px flex-1 bg-sky-300/50" />
              <span>بندرعباس</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {["اظهارنامه", "بارنامه", "بیمه", "گواهی مبدأ"].map((item) => (
              <div key={item} className="rounded-xl border border-white/10 bg-white/[0.05] p-3">
                <div className="text-sm font-semibold">{item}</div>
                <div className="mt-1 text-xs text-emerald-200">تأیید شده ✓</div>
              </div>
            ))}
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="rounded-xl bg-white/[0.06] p-3">
              <div className="text-xs text-white/60">ETA</div>
              <div className="text-lg font-bold text-sky-200">۲٫۴ روز</div>
            </div>
            <div className="rounded-xl bg-white/[0.06] p-3">
              <div className="text-xs text-white/60">Capacity Match</div>
              <div className="text-lg font-bold text-emerald-200">۹۴٪</div>
            </div>
            <div className="rounded-xl bg-white/[0.06] p-3">
              <div className="text-xs text-white/60">Delay</div>
              <div className="text-lg font-bold text-orange-200">۰</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div className="order-1 text-right lg:order-2">
      <div className="mb-5 inline-flex rounded-full border border-sky-300/30 bg-sky-300/10 px-4 py-2 text-xs font-semibold tracking-[0.18em] text-sky-100">
        IKIA LOGISTICS OPERATING SYSTEM
      </div>

      <h1 className="max-w-3xl text-[clamp(2.6rem,5vw,4.25rem)] font-bold leading-[1.1] tracking-tight">
        سامانه عملیاتی لجستیک برای کنترل حمل، اسناد و زنجیره تأمین
      </h1>

      <p className="mt-6 max-w-2xl text-lg leading-9 text-slate-200">
        از ثبت سفارش تا تخصیص ناوگان، رهگیری، اسناد گمرکی، تطبیق و تسویه — همه در یک پلتفرم واحد برای بازار ایران و کریدورهای منطقه‌ای.
      </p>

      <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:justify-start lg:justify-end">
        <a href="#start" className="rounded-xl bg-[#0B6FB5] px-6 py-4 text-center font-semibold text-white shadow-lg hover:bg-[#1F9CE0]">
          درخواست جلسه معرفی
        </a>
        <a href="#platform" className="rounded-xl border border-white/35 px-6 py-4 text-center font-semibold text-white hover:bg-white/10">
          مشاهده پلتفرم
        </a>
      </div>
    </div>
  </div>
</section>
```

---

## 20. Acceptance Checklist

Claude Code must verify:

```text
[ ] Hero is not only a photo; it includes a visible product UI panel.
[ ] Secondary CTA does not go to /login.
[ ] Colors stay within navy / white / blue / green / red accents.
[ ] Page is shorter and more coherent.
[ ] Dedicated industry sections are consolidated.
[ ] Control Tower looks like a real dashboard.
[ ] Corridors section includes SVG/network visual.
[ ] Footer is compact and four-column.
[ ] Premium cards use hover-lift.
[ ] No broken anchors.
[ ] Root page remains static.
[ ] typecheck passes.
[ ] build passes.
[ ] database tests pass.
[ ] admin route guard verification passes.
```

---

## 21. Visible Verification Strings

After editing, grep for these strings:

```text
مشاهده پلتفرم
سامانه عملیاتی لجستیک برای کنترل حمل
Regional Corridor Network
زنجیره حمل خود را روی یک پلتفرم واحد
```

---

## 22. Validation

Run:

```bash
npm run typecheck
npm run build
bash 23-DATABASE/tests/run.sh
bash scripts/verify-admin-route-guards.sh
```

Build must keep:

```text
○ / Static
```

---

## 23. Final Report Required

Report:

```text
files changed
sections rebuilt
visible first-viewport changes
visible mid-page changes
removed/consolidated sections
anchor verification
validation results
final git status -sb
exact local URL to inspect
```

Do not commit.
Do not push.
Stop after report.
