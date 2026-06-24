"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export async function signOut() {
  const supabase = await createClient();
  try {
    await supabase.schema("identity").rpc("record_logout");
  } catch {
    // Audit failure must not block sign-out.
  }
  await supabase.auth.signOut();
  revalidatePath("/", "layout");
  redirect("/login");
}
