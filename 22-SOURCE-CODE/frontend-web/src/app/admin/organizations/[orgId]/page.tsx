import Link from "next/link";
import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getAdminOrganization } from "@/lib/admin/list-organizations";
import { listMembershipsForOrg } from "@/lib/admin/list-memberships";
import { ROLE_LABELS_FA, type Role } from "@/lib/permissions/roles";

interface PageProps {
  params: Promise<{ orgId: string }>;
}

export default async function AdminOrganizationDetailPage({ params }: PageProps) {
  const { orgId } = await params;
  const [org, members] = await Promise.all([
    getAdminOrganization(orgId),
    listMembershipsForOrg(orgId),
  ]);
  if (!org) notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold">{org.nameFa}</h1>
          <p className="text-sm text-muted-foreground">{org.nameEn} · {org.code}</p>
        </div>
        <Button asChild>
          <Link href={`/admin/organizations/${org.id}/members/new`}>افزودن عضو</Link>
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>اطلاعات سازمان</CardTitle>
          <CardDescription>Organization summary</CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-4 text-sm">
          <Field label="نوع"><Badge variant="outline">{org.type}</Badge></Field>
          <Field label="وضعیت"><Badge variant="outline">{org.status}</Badge></Field>
          <Field label="کد کشور">{org.countryCode}</Field>
          <Field label="تننت" mono>{org.tenantId}</Field>
          <Field label="شناسه" mono>{org.id}</Field>
          <Field label="ایجاد شده در">{new Date(org.createdAt).toLocaleString("fa-IR")}</Field>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>اعضا</CardTitle>
          <CardDescription>{members.length} عضو فعال</CardDescription>
        </CardHeader>
        <CardContent>
          {members.length === 0 ? (
            <TableEmpty>هنوز عضوی اضافه نشده است.</TableEmpty>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کاربر</TableHead>
                  <TableHead>نقش</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>پیوسته در</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {members.map((m) => (
                  <TableRow key={m.membershipId}>
                    <TableCell>
                      <Link
                        href={`/admin/users/${m.userId}`}
                        className="font-mono text-xs underline"
                      >
                        {m.userId.slice(0, 8)}…
                      </Link>
                    </TableCell>
                    <TableCell>
                      {m.roleCode ? ROLE_LABELS_FA[m.roleCode as Role] : "—"}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">{m.status}</Badge>
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {m.joinedAt ? new Date(m.joinedAt).toLocaleString("fa-IR") : "—"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function Field({ label, children, mono }: { label: string; children: React.ReactNode; mono?: boolean }) {
  return (
    <div className="space-y-1">
      <p className="text-xs text-muted-foreground">{label}</p>
      <div className={mono ? "font-mono text-xs" : ""}>{children}</div>
    </div>
  );
}
