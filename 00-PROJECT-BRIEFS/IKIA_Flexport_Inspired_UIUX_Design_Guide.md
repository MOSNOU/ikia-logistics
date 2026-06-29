# راهنمای جامع طراحی UI/UX الهام‌گرفته از Flexport برای iKIA Logistics

> نسخه: 1.0  
> کاربرد: سند مرجع برای تیم طراحی، UI/UX، فرانت‌اند و برندینگ  
> هدف: بازطراحی وب‌سایت iKIA Logistics با کیفیت، ریتم، معماری اطلاعات و حس محصولی نزدیک به Flexport، بدون کپی مستقیم دارایی‌ها، متن‌ها، لوگو یا هویت اختصاصی Flexport.

---

## 1. اصل راهبردی طراحی

Flexport یک سایت معرفی ساده نیست؛ خود را به‌عنوان یک **پلتفرم عملیاتی زنجیره تأمین و لجستیک** معرفی می‌کند. در طراحی iKIA نیز باید همین نگاه وجود داشته باشد:

- وب‌سایت باید حس «نرم‌افزار لجستیکی» بدهد، نه بروشور شرکتی.
- محور اصلی صفحه باید «کنترل، شفافیت، سرعت، اسناد، مسیر، بازار حمل و عملیات» باشد.
- تصویرسازی باید بیشتر شبیه dashboard، control tower، timeline، map و status UI باشد.
- عکس‌های استوک کامیون/بندر فقط نقش مکمل داشته باشند، نه ستون اصلی طراحی.
- ریتم کلی باید enterprise، فنی، تمیز و قابل اعتماد باشد.

---

## 2. قوانین حقوقی و برند

این سند برای الگوبرداری از منطق طراحی است، نه کپی‌برداری.

مجاز:
- الهام از ریتم صفحه، ساختار منو، بخش‌های تیره/روشن، کارت‌های محصولی، مگامنو، CTA، فوتر چندستونه و حس UI محصول.
- استفاده از رنگ‌های نزدیک در قالب هویت iKIA.
- بازسازی layout patterns با متن، لوگو، تصویر و محتوای اختصاصی iKIA.

غیرمجاز:
- کپی دقیق متن Flexport.
- استفاده از لوگو، تصویر، ویدیو، آیکون، اسکرین‌شات یا دارایی‌های اختصاصی Flexport.
- تقلید آن‌قدر نزدیک که سایت iKIA با Flexport اشتباه گرفته شود.
- استفاده از نام Flexport در UI عمومی سایت مگر در متن همکاری رسمی آینده.

---

## 3. شخصیت بصری

| محور | تصمیم طراحی برای iKIA |
|---|---|
| لحن | سازمانی، جهانی، فنی، قابل اعتماد |
| حس اصلی | Logistics OS / Control Tower / Marketplace |
| رنگ پایه | سرمه‌ای عمیق + سفید/خاکستری روشن |
| لهجه‌ها | آبی روشن، فیروزه‌ای، سبز موفقیت، قرمز iKIA با احتیاط |
| تصویرسازی | dashboard، نقشه، مسیر، کارت وضعیت، timeline |
| حرکت | نرم، کم، حرفه‌ای |
| هدف | تبدیل iKIA از سایت معرفی به پلتفرم لجستیکی قابل اعتماد |

---

## 4. Design Tokens پیشنهادی

```css
:root {
  /* Core Navy */
  --ikia-midnight: #0A1B2E;
  --ikia-navy: #0E2640;
  --ikia-navy-mid: #103A5E;

  /* Brand / Product Blues */
  --ikia-blue: #0B6FB5;
  --ikia-blue-bright: #1F9CE0;
  --ikia-cerulean: #0093BF;

  /* Functional Accents */
  --ikia-green: #15C26B;
  --ikia-orange: #F5A623;
  --ikia-red: #D8202A;

  /* Surfaces */
  --ikia-white: #FFFFFF;
  --ikia-soft: #F5F8FB;
  --ikia-soft-2: #EEF3F8;
  --ikia-border: #D6E0EA;

  /* Text */
  --ikia-text: #0A1B2E;
  --ikia-text-muted: #51637A;
  --ikia-text-on-dark: #E8F0F8;
  --ikia-text-on-dark-muted: #9FB4C9;

  /* Effects */
  --ikia-shadow-card: 0 8px 30px rgba(10, 27, 46, 0.08);
  --ikia-shadow-pop: 0 16px 50px rgba(10, 27, 46, 0.16);
}
```

### قانون رنگ 60/30/10

- 60٪ صفحه: سفید، off-white و soft background.
- 30٪ صفحه: سرمه‌ای عمیق برای Hero، سکشن‌های محصولی و Footer.
- 10٪ صفحه: آبی، سبز، قرمز و نارنجی فقط برای CTA، status، icon و highlight.

---

## 5. تایپوگرافی

### فارسی
- Font: Vazirmatn
- وزن تیترها: 700
- وزن متن: 400 یا 500
- اعداد dashboard ترجیحاً لاتین یا tabular برای خوانایی داده.

### لاتین
- Font: Inter یا Plus Jakarta Sans
- برای code chipها و identifierها: Inter / IBM Plex Mono

### مقیاس پیشنهادی

```css
--fs-hero: clamp(2.6rem, 5vw, 4.25rem);
--fs-h2: clamp(1.9rem, 3.2vw, 2.75rem);
--fs-h3: 1.5rem;
--fs-lead: 1.25rem;
--fs-body: 1rem;
--fs-small: 0.875rem;
--fs-eyebrow: 0.8125rem;
```

### قواعد تایپ
- Hero باید بزرگ، واضح و حداکثر دو خط باشد.
- هر بخش باید eyebrow کوچک داشته باشد.
- متن‌های توضیحی باید کوتاه، مستقیم و محصولی باشند.
- از paragraphهای طولانی در homepage پرهیز شود.

---

## 6. ساختار اصلی صفحه Home

### ترتیب پیشنهادی صفحه

1. Announcement strip
2. Sticky header
3. Dark Hero with product/logistics visual
4. Trust/proof strip
5. Platform modules
6. Product dashboard / control tower section
7. Services / shipment modes
8. Solutions by stakeholder
9. Shipment lifecycle
10. Corridors / global network
11. Industries
12. Metrics / impact
13. Final CTA
14. Footer

### ریتم رنگ
- Hero: dark navy
- Proof: white
- Platform modules: soft background
- Product dashboard: dark navy
- Services: white
- Solutions: soft background
- Lifecycle: dark navy یا product panel
- Corridors: white
- Final CTA: dark navy
- Footer: dark navy

---

## 7. Header و Navigation

### Announcement Strip

بالای header یک نوار باریک قرار بگیرد:

متن پیشنهادی:
> زیرساخت دیجیتال لجستیک، حمل، اسناد و زنجیره تأمین برای بازار ایران و کریدورهای منطقه‌ای

CTA:
> مشاهده توانمندی‌ها ←

استایل:
- ارتفاع کم
- پس‌زمینه سرمه‌ای
- متن روشن
- لینک آبی روشن
- در موبایل دو خطی و جمع‌وجور

### Header اصلی

ویژگی‌ها:
- Sticky
- پس‌زمینه سفید یا glass white
- border-bottom بسیار ظریف
- لوگوی رسمی iKIA
- ارتفاع compact
- hover حرفه‌ای
- دکمه CTA روشن و قابل تشخیص

### Navigation فارسی پیشنهادی

| Label | Anchor |
|---|---|
| پلتفرم | `/#platform` |
| خدمات حمل | `/#marketplace` |
| راهکارها | `/#solutions` |
| کریدورها | `/#corridors` |
| بازار حمل | `/#commodities` |
| اسناد و تطبیق | `/#documents` |
| درباره ما | `/#enterprise-readiness` |

### CTAهای Header
- Primary: ورود به پلتفرم
- Secondary: درخواست همکاری

### مگامنو پیشنهادی برای فاز بعد

#### پلتفرم
- Control Tower
- Freight Marketplace
- Documents & Compliance
- Route Intelligence
- Settlement
- Partner Portal

#### خدمات حمل
- حمل جاده‌ای
- حمل ریلی
- حمل دریایی
- حمل هوایی
- انبارداری
- گمرک و تطبیق

#### راهکارها
- صاحبان کالا
- فورواردرها
- شرکت‌های حمل
- رانندگان
- تأمین‌کنندگان
- مدیران سازمانی

#### منابع
- راهنمای اسناد
- سناریوهای حمل
- API و Integration
- گزارش بازار
- سوالات متداول

---

## 8. Hero

Hero باید مانند محصولی جهانی عمل کند:

### محتوا
- تیتر بزرگ، مستقیم، محصول‌محور.
- زیرتیتر درباره end-to-end visibility، control، documents، route، marketplace.
- دو CTA واضح.

### استایل
- پس‌زمینه سرمه‌ای یا تصویر سینمایی با overlay تیره.
- متن سمت راست در RTL.
- پنل glass محدود برای خوانایی.
- CTA اصلی سبز/آبی، CTA دوم قرمز/outline.
- هیچ کارت آماری شلوغ و تصادفی داخل Hero نباشد.

### نمونه متن پیشنهادی
عنوان:
> سامانه عملیاتی لجستیک برای کنترل حمل، اسناد و زنجیره تأمین

زیرعنوان:
> از ثبت سفارش تا تخصیص ناوگان، رهگیری، اسناد، تطبیق و تسویه؛ همه در یک پلتفرم واحد برای بازار ایران و کریدورهای منطقه‌ای.

CTA:
- درخواست جلسه معرفی
- ورود به پلتفرم

---

## 9. Platform Modules Section

این بخش باید به کاربر بگوید iKIA فقط شرکت حمل نیست، بلکه پلتفرم دارد.

### عنوان
> یک پلتفرم عملیاتی برای کنترل کل زنجیره حمل

### ماژول‌ها

| Code | عنوان فارسی | توضیح |
|---|---|---|
| Control Tower | کنترل‌تاور | دید لحظه‌ای روی سفارش‌ها، ناوگان، وضعیت مسیر و رخدادهای عملیاتی |
| Freight Marketplace | بازار حمل | اتصال صاحبان کالا، شرکت‌های حمل، فورواردرها و تأمین‌کنندگان ظرفیت |
| Documents & Compliance | اسناد و تطبیق | مدیریت بارنامه، بیمه، گواهی‌ها، اظهارنامه و کنترل تطبیق |
| Route Intelligence | هوش مسیر | انتخاب مسیر با توجه به زمان، هزینه، مرز، ترافیک و ریسک |
| Settlement | تسویه و صورتحساب | مدیریت تسویه، کارمزد، صورت‌حساب و وضعیت مالی عملیات |
| Partner Portal | پرتال همکاران | فضای اختصاصی برای راننده، شرکت حمل، تأمین‌کننده و نماینده |

### طراحی کارت‌ها
- Grid 2×3
- کارت سفید روی soft background
- top accent line آبی/فیروزه‌ای
- code chip کوچک لاتین
- آیکون خطی
- CTA text link

---

## 10. Product Dashboard Section

این بخش امضای Flexport-like سایت است. باید حس dashboard واقعی بدهد.

### عناصر UI
- Window chrome
- Shipment ID
- Live chip
- Timeline rail
- Route row
- Compliance row
- Metrics strip
- Notification/status cards

### محتوای نمونه

Shipment ID:
`SH-2026-08471`

Route:
`Tehran → Bandar Abbas`

Chips:
- Live
- North–South Corridor
- Customs OK
- ETA 18h
- 4/4 Docs Approved

Metrics:
- زمان تحویل: 18h
- تطبیق ظرفیت: 94%
- تأخیر فعال: 2

### حالت تاریک
- پس‌زمینه section: `#0A1B2E`
- کارت dashboard: `rgba(255,255,255,0.06)`
- border: `rgba(255,255,255,0.10)`
- text: `#E8F0F8`
- muted: `#9FB4C9`

---

## 11. Shipment Lifecycle

این بخش نباید کارت‌های ساده عمودی باشد. باید مثل یک مسیر عملیات نرم‌افزاری طراحی شود.

### وضعیت‌ها

| English | Persian |
|---|---|
| Draft | پیش‌نویس |
| Ready | آماده |
| Matched | تطبیق |
| Booked | رزرو |
| Dispatched | اعزام |
| In Transit | در مسیر |
| Delivered | تحویل |
| Reconciled | تسویه |

### طراحی
- timeline rail عمودی یا افقی
- نقطه‌های status
- یک state فعال
- route و document و metric کنار timeline
- chips رنگی محدود
- هر state یک توضیح کوتاه

---

## 12. Services / Shipping Modes

بخش خدمات باید با تصویر/slider فعلی ادغام شود و شبیه showcase حرفه‌ای باشد.

### عنوان
> خدمات حمل در یک تجربه عملیاتی یکپارچه

### خدمات
- Road Freight
- Rail Freight
- Ocean Freight
- Air Freight
- Warehousing
- Customs & Compliance

### طراحی
- Slider یا کارت‌های بزرگ تصویری
- overlay تیره بسیار کنترل‌شده
- عنوان و توضیح کوتاه
- CTA کوچک برای مشاهده جزئیات
- از عکس‌های استوک خام پرهیز شود؛ تصاویر باید با رنگ و لوگوی iKIA هماهنگ باشند.

---

## 13. Trust / Proof Section

برای حس enterprise باید proof اضافه شود.

### گزینه‌ها
- نوار لوگوی مشتریان/همکاران آینده
- metrics
- نقل‌قول مشتری
- عددهای operational

نمونه metrics:
- 24/7 visibility
- 4 modes connected
- 8 lifecycle states
- 1 operating system

### هشدار
اگر لوگوی مشتری واقعی نداریم، از placeholderهای ساختگی استفاده نشود. بهتر است بگوییم:
> طراحی‌شده برای شرکت‌های صنعتی، بازرگانی، حمل‌ونقل و فورواردرهای منطقه‌ای.

---

## 14. Corridors / Global Network

iKIA باید از ایران و کریدورها حرف بزند.

### عنوان
> اتصال بازار ایران به کریدورهای منطقه‌ای

### موارد
- کریدور شمال–جنوب
- ترکیه و اروپا
- خلیج فارس
- آسیای میانه
- بنادر جنوبی
- حمل ترکیبی جاده/ریل/دریا

### طراحی
- map-like card
- route lines
- node chips
- corridor status
- dark یا white split section

---

## 15. Industries

### صنایع پیشنهادی
- فولاد و معدن
- نفت و پتروشیمی
- کشاورزی و مواد غذایی
- کالاهای مصرفی
- پروژه‌های صنعتی
- صادرات و واردات

### طراحی
- کارت‌های compact
- آیکون خطی
- توضیح یک‌خطی
- بدون تصویر شلوغ

---

## 16. Final CTA

### عنوان
> زنجیره حمل خود را روی یک پلتفرم واحد ببینید و کنترل کنید

### زیرعنوان
> iKIA Logistics عملیات حمل، بازار ظرفیت، اسناد، رهگیری، تطبیق و تسویه را در یک تجربه دیجیتال برای صاحبان کالا و همکاران لجستیکی یکپارچه می‌کند.

CTA:
- درخواست جلسه معرفی
- شروع همکاری

### استایل
- dark navy
- radial blue accent
- دو یا سه mini product card
- لوگوی iKIA کوچک
- بدون عکس شلوغ

---

## 17. Footer

Footer باید کوتاه، ساختاریافته و چهارستونه باشد.

### ساختار

#### ستون ۱: پلتفرم
- پلتفرم
- کنترل‌تاور
- چرخه عمر محموله
- ماژول‌های عملیاتی
- سیستم عامل لجستیک

#### ستون ۲: خدمات
- خدمات حمل
- حمل جاده‌ای
- حمل ریلی
- حمل دریایی
- حمل هوایی
- گمرک و اسناد

#### ستون ۳: منابع
- راهکارهای صنعتی
- کریدورها
- بازار حمل
- سناریوهای عملیاتی
- گزارش‌ها

#### ستون ۴: شرکت
- درباره ما
- درخواست همکاری
- ورود به پلتفرم
- تماس
- زبان

### پایین Footer
- © 2026 IKIA Logistics
- Privacy
- Terms
- FA / EN

### استایل
- پس‌زمینه `#0A1B2E`
- تیتر ستون‌ها سفید
- لینک‌ها muted
- hover سفید/آبی
- بدون ستون خیلی بلند

---

## 18. Micro-interactions

- hover کارت: translateY(-2px) + shadow
- لینک‌ها: underline یا color shift
- CTA: slight lift
- Mega menu: fade/slide کوتاه
- prefers-reduced-motion رعایت شود
- انیمیشن فقط برای حس premium، نه تزئین زیاد

---

## 19. Responsive / Mobile

### زیر 1024px
- منو به hamburger یا details panel تبدیل شود.
- Gridها تک‌ستونه یا 2 ستونه شوند.
- product dashboard عرض کامل بگیرد.
- Hero متن خوانا و CTAها full-width شوند.
- فوتر 2 ستون و سپس 1 ستون شود.

### RTL
- تمام چیدمان با `dir="rtl"`.
- فلش‌ها در CTA باید `←` باشند.
- آیکون‌های جهت‌دار mirror شوند.
- از logical CSS properties در صورت امکان استفاده شود.

---

## 20. Tailwind Utility Patterns

### Section
```tsx
<section className="py-20 lg:py-28">
  <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
    ...
  </div>
</section>
```

### Dark Section
```tsx
<section className="relative overflow-hidden bg-[#0A1B2E] py-20 text-[#E8F0F8] lg:py-28">
  <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(31,156,224,0.18),transparent_32%),radial-gradient(circle_at_80%_70%,rgba(21,194,107,0.10),transparent_30%)]" />
  <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
    ...
  </div>
</section>
```

### Product Card
```tsx
<div className="rounded-3xl border border-slate-200 bg-white shadow-[0_8px_30px_rgba(10,27,46,0.08)]">
  <div className="h-1 rounded-t-3xl bg-gradient-to-l from-sky-400 via-blue-500 to-cyan-400" />
  <div className="p-6">
    ...
  </div>
</div>
```

### Dark Product Card
```tsx
<div className="rounded-3xl border border-white/10 bg-white/[0.06] p-6 shadow-2xl shadow-black/20 backdrop-blur">
  ...
</div>
```

### Eyebrow
```tsx
<p className="text-xs font-bold uppercase tracking-[0.22em] text-sky-500">
  Control Tower
</p>
```

---

## 21. Implementation Plan for Claude / Front-end Team

### Phase 1
- Audit current homepage sections.
- Preserve working hero and service slider.
- Add/clean design tokens.
- Fix header and footer.

### Phase 2
- Rebuild platform modules.
- Rebuild lifecycle/product dashboard.
- Clean white gaps.
- Add dark/white rhythm.

### Phase 3
- Add proof/trust section.
- Improve corridors and industries.
- Add responsive polish.
- Validate build.

### Validation
- `npm run typecheck`
- `npm run build`
- `bash 23-DATABASE/tests/run.sh`
- `bash scripts/verify-admin-route-guards.sh`

---

## 22. Acceptance Criteria

- Homepage no longer feels like a generic company website.
- It feels like a logistics SaaS / operating system.
- Header is clean, sticky and enterprise-grade.
- Footer is 4-column and controlled.
- Hero is dark, premium and readable.
- Product dashboard section looks like real software.
- Lifecycle is a real operational timeline, not isolated cards.
- Color rhythm follows dark/light alternation.
- No Flexport assets or exact copy are used.
- Root `/` remains static in Next build.
- Mobile layout is clean and RTL-safe.

---

## 23. Claude Prompt

```text
Act as an elite UI/UX director, senior product designer, logistics SaaS product architect, and Next.js/Tailwind front-end engineer.

You must redesign the iKIA Logistics public homepage using the attached Markdown design guide as the primary benchmark. The goal is to achieve Flexport-level UI/UX quality and platform storytelling while using only iKIA identity, original Persian copy, original assets, and existing project components.

Do not copy Flexport logos, images, videos, exact copy, screenshots, or proprietary assets. Use Flexport only as a benchmark for design system logic, navigation structure, dark/light rhythm, product dashboard feeling, and enterprise logistics platform storytelling.

Repository:
`/Users/mostafanourabi/Desktop/iKIA-LOGISTICS`

Frontend path:
`22-SOURCE-CODE/frontend-web`

Primary files to inspect:
- `src/app/(public)/layout.tsx`
- `src/app/(public)/page.tsx`
- `src/app/globals.css`
- `src/styles/tokens.css`
- `src/components/marketing/`

Preserve:
- Existing official iKIA logo
- CC-66D hero image and CTA direction
- CC-66B service slider
- Next.js static rendering for `/`
- Backend, database, auth, admin routes, Supabase and package configuration

Tasks:
1. Audit the current homepage and identify weak sections.
2. Apply the attached color/token system.
3. Rebuild the header and announcement strip.
4. Rebuild the platform modules as a 2×3 product capability grid.
5. Rebuild shipment lifecycle as a dark product-dashboard section.
6. Integrate services/slider into a cleaner product rhythm.
7. Rebuild final CTA as a dark premium conversion block.
8. Rebuild footer as a short, clean 4-column enterprise footer.
9. Remove huge blank gaps and weak brochure-like cards.
10. Keep all anchors valid and RTL-safe.
11. Keep the site mobile-first and responsive.
12. Run validation:
    - `npm run typecheck`
    - `npm run build`
    - `bash 23-DATABASE/tests/run.sh`
    - `bash scripts/verify-admin-route-guards.sh`

Do not commit.
Do not push.
Stop after report with files changed, sections redesigned, validation results, and final `git status -sb`.
```

---

## منابع مطالعه برای تیم

- Flexport official homepage: https://www.flexport.com/
- Flexport Ocean Freight product page: https://www.flexport.com/products/ocean-freight/
- Flexport About page: https://www.flexport.com/company/about-us/
- Flexport Brand / Logo page: https://www.flexport.com/company/logo/
