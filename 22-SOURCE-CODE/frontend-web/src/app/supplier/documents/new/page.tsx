import { AddDocumentForm } from "./add-document-form";

export default function SupplierAddDocumentPage() {
  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">افزودن مدرک</h1>
        <p className="text-sm text-muted-foreground">
          فقط فراداده — مرجع خارجی (لینک) می‌توانید وارد کنید. در فاز بعدی بارگذاری فایل اضافه می‌شود.
        </p>
      </div>
      <AddDocumentForm />
    </div>
  );
}
