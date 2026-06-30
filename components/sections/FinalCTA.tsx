import { Button } from "@/components/ui/Button";
import { PRODUCT_URLS } from "@/content/siteArchitecture";

export function FinalCTA({
  title = "زنجیره حمل خود را روی یک پلتفرم واحد ببینید و کنترل کنید",
  subtitle = "برای هماهنگی حمل، بازار ظرفیت، اسناد، تطبیق، رهگیری و تسویه — یک جریان عملیاتی واحد بسازید.",
}: {
  title?: string;
  subtitle?: string;
}) {
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-ink to-ink-2 text-white">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{ background: "radial-gradient(50% 80% at 80% 0%, rgba(22,163,74,0.22) 0%, transparent 70%)" }}
      />
      <div className="relative mx-auto w-full max-w-6xl px-4 py-20 text-center sm:px-6 lg:px-8 lg:py-24">
        <h2 className="mx-auto max-w-3xl text-3xl font-bold leading-tight md:text-[2.6rem]">{title}</h2>
        <p className="mx-auto mt-5 max-w-2xl text-base leading-8 text-ondark-muted md:text-lg">{subtitle}</p>
        <div className="mt-9 flex flex-wrap justify-center gap-3">
          <Button href={PRODUCT_URLS.start} variant="green" size="lg">
            شروع همکاری
          </Button>
          <Button href={PRODUCT_URLS.platform} variant="outlineLight" size="lg">
            مشاهده پلتفرم
          </Button>
        </div>
      </div>
    </section>
  );
}
