import { CreateRfqForm } from "./create-rfq-form";

export default function BuyerNewRfqPage() {
  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ایجاد RFQ جدید</h1>
        <p className="text-sm text-muted-foreground">
          RFQ در حالت پیش‌نویس ایجاد می‌شود. پس از افزودن ردیف‌ها و دعوت تأمین‌کنندگان می‌توانید آن را ارسال کنید.
        </p>
      </div>
      <CreateRfqForm />
    </div>
  );
}
