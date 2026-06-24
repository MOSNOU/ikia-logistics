import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import type { ContractPreparationDetail } from "@/types/database";
import { PreparationStatusActions } from "./preparation-status-actions";
import { AddPartyForm } from "./add-party-form";
import { UpsertClauseForm } from "./upsert-clause-form";
import { RemoveClauseButton } from "./remove-clause-button";

interface Props {
  detail: ContractPreparationDetail;
  audience: "buyer" | "supplier" | "admin";
}

export function PreparationView({ detail, audience }: Props) {
  const { preparation, parties, clauses, events } = detail;
  const editable = audience === "buyer" && (preparation.status === "draft" || preparation.status === "under_review");
  const canMoveToReview = audience === "buyer" && preparation.status === "draft";
  const canMarkReady = audience === "buyer" && preparation.status === "under_review";
  const canPromote = audience === "buyer" && preparation.status === "ready_for_contract";
  const canCancel =
    audience === "buyer" &&
    (preparation.status === "draft" ||
      preparation.status === "under_review" ||
      preparation.status === "ready_for_contract");

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{preparation.title}</h1>
          <p className="text-sm text-muted-foreground">
            <span className="font-mono text-xs">{preparation.preparation_code}</span>
            {" · "}
            <Badge variant="muted">phase: preparation</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{preparation.status}</Badge>
          </p>
        </div>
        {audience === "buyer" ? (
          <PreparationStatusActions
            preparationId={preparation.id}
            canMoveToReview={canMoveToReview}
            canMarkReady={canMarkReady}
            canPromote={canPromote}
            canCancel={canCancel}
          />
        ) : null}
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <div className="text-muted-foreground">RFQ</div>
            <div className="font-mono text-xs">{preparation.request_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">پیشنهاد</div>
            <div className="font-mono text-xs">{preparation.offer_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">تأمین‌کننده</div>
            <div className="font-mono text-xs">{preparation.supplier_id}</div>
          </div>
          <div>
            <div className="text-muted-foreground">نوع قرارداد</div>
            <div>{preparation.contract_type ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">ارز</div>
            <div>{preparation.currency ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">اینکوترم</div>
            <div>{preparation.incoterm ?? "—"}</div>
          </div>
          {preparation.payment_terms_text ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">شرایط پرداخت</div>
              <div>{preparation.payment_terms_text}</div>
            </div>
          ) : null}
          {preparation.delivery_terms_text ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">شرایط تحویل</div>
              <div>{preparation.delivery_terms_text}</div>
            </div>
          ) : null}
          {preparation.internal_notes ? (
            <div className="md:col-span-3">
              <div className="text-muted-foreground">یادداشت داخلی</div>
              <div>{preparation.internal_notes}</div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      <div>
        <h2 className="text-lg font-semibold mb-3">طرف‌ها ({parties?.length ?? 0})</h2>
        {!parties || parties.length === 0 ? (
          <TableEmpty>طرفی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نام</TableHead>
                  <TableHead>نوع</TableHead>
                  <TableHead>نقش</TableHead>
                  <TableHead>امضاکننده</TableHead>
                  <TableHead>ترتیب امضا</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {parties.map((p) => (
                  <TableRow key={p.id}>
                    <TableCell>{p.display_name}</TableCell>
                    <TableCell><Badge variant="outline">{p.party_type}</Badge></TableCell>
                    <TableCell>{p.role_title ?? "—"}</TableCell>
                    <TableCell>{p.is_required_signer ? "بله" : "خیر"}</TableCell>
                    <TableCell>{p.signing_order ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
        {editable ? (
          <div className="mt-4">
            <h3 className="text-sm font-medium mb-2">افزودن طرف</h3>
            <AddPartyForm preparationId={preparation.id} />
          </div>
        ) : null}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">بندها ({clauses?.length ?? 0})</h2>
        {!clauses || clauses.length === 0 ? (
          <TableEmpty>بندی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع</TableHead>
                  <TableHead>عنوان</TableHead>
                  <TableHead>متن</TableHead>
                  <TableHead>ضروری</TableHead>
                  <TableHead>ترتیب</TableHead>
                  {editable ? <TableHead>عملیات</TableHead> : null}
                </TableRow>
              </TableHeader>
              <TableBody>
                {clauses.map((c) => (
                  <TableRow key={c.id}>
                    <TableCell><Badge variant="outline">{c.clause_type}</Badge></TableCell>
                    <TableCell>{c.title_fa ?? c.title_en ?? "—"}</TableCell>
                    <TableCell className="text-xs max-w-md truncate">{c.body_fa ?? c.body_en ?? "—"}</TableCell>
                    <TableCell>{c.is_required ? "بله" : "خیر"}</TableCell>
                    <TableCell>{c.sort_order ?? "—"}</TableCell>
                    {editable ? (
                      <TableCell>
                        <RemoveClauseButton clauseId={c.id} preparationId={preparation.id} />
                      </TableCell>
                    ) : null}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
        {editable ? (
          <div className="mt-4">
            <h3 className="text-sm font-medium mb-2">افزودن / به‌روزرسانی بند</h3>
            <UpsertClauseForm preparationId={preparation.id} />
          </div>
        ) : null}
      </div>

      {events && events.length > 0 ? (
        <div>
          <h2 className="text-lg font-semibold mb-3">رویدادها ({events.length})</h2>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>از</TableHead>
                  <TableHead>به</TableHead>
                  <TableHead>دلیل</TableHead>
                  <TableHead>کاربر</TableHead>
                  <TableHead>زمان</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {events.map((e) => (
                  <TableRow key={e.id}>
                    <TableCell className="text-xs">{e.from_status ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.to_status ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.reason ?? "—"}</TableCell>
                    <TableCell className="font-mono text-xs">{e.actor_user_id ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.created_at}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </div>
      ) : null}

      <div>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/contracts">بازگشت به فهرست</Link>
        </Button>
      </div>
    </div>
  );
}
