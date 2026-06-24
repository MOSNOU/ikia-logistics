import { CreateShipmentForm } from "./create-shipment-form";

interface PageProps {
  searchParams: Promise<{ contract_id?: string }>;
}

export default async function BuyerNewShipmentPage({ searchParams }: PageProps) {
  const { contract_id: contractId } = await searchParams;

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ایجاد محموله جدید</h1>
        <p className="text-sm text-muted-foreground">
          محموله به یک قرارداد اجرایی متصل می‌شود. شناسه قرارداد اجرایی (UUID) را وارد کنید.
        </p>
      </div>
      <CreateShipmentForm defaultContractId={contractId ?? ""} />
    </div>
  );
}
