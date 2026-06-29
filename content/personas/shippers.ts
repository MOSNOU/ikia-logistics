import type { Persona } from "../types";
import { PRODUCT_URLS } from "../navigation";

export const SHIPPERS: Persona = {
  slug: "shippers",
  badge: "برای صاحبان بار",
  icon: "package",
  title: "بار خود را ساده و شفاف بفرستید",
  subtitle: "ثبت بار، قیمت شفاف، انتخاب فورواردر یا کریر و پیگیری تا تحویل.",
  image: "/images/marketing/shippers.webp",
  pains: [
    { title: "قیمت‌گذاری مبهم", desc: "نبود شفافیت قیمت، تصمیم‌گیری را سخت می‌کند." },
    { title: "واسطه‌های متعدد", desc: "زنجیره واسطه‌ها هزینه و زمان را بالا می‌برد." },
    { title: "بی‌خبری از وضعیت", desc: "نبود پیگیری روشن، اعتماد را کاهش می‌دهد." },
  ],
  capabilities: [
    { icon: "register", title: "ثبت بار", desc: "ثبت سریع محموله و الزامات حمل." },
    { icon: "price", title: "قیمت شفاف", desc: "مشاهده شفاف شرایط و قیمت پیشنهادها." },
    { icon: "check", title: "انتخاب حمل‌کننده", desc: "انتخاب فورواردر یا کریر مناسب." },
    { icon: "tracking", title: "ردیابی و تحویل", desc: "پیگیری وضعیت بار تا تحویل نهایی." },
  ],
  steps: [
    { title: "بار را ثبت کنید", desc: "مشخصات محموله را وارد کنید." },
    { title: "پیشنهاد بگیرید", desc: "قیمت‌های شفاف را مقایسه کنید." },
    { title: "انتخاب کنید", desc: "حمل‌کننده مناسب را برگزینید." },
    { title: "تحویل بگیرید", desc: "وضعیت را تا تحویل دنبال کنید." },
  ],
  cta: { label: "ثبت اولین بار", href: PRODUCT_URLS.register },
  seo: {
    title: "راهکار صاحبان بار — iKIA",
    description: "iKIA برای شیپرها: ثبت بار، قیمت شفاف، انتخاب فورواردر/کریر و ردیابی تا تحویل.",
  },
};
