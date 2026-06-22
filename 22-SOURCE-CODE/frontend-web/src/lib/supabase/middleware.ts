import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import type { Database } from "@/types/database";

type CookieToSet = { name: string; value: string; options: CookieOptions };

const WELCOME_PATH = "/welcome";

function shouldBypassWelcomeCheck(pathname: string): boolean {
  return (
    pathname === "/" ||
    pathname === "/login" ||
    pathname === "/welcome" ||
    pathname === "/unauthorized" ||
    pathname.startsWith("/api/") ||
    pathname.startsWith("/_next/")
  );
}

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    return response;
  }

  const supabase = createServerClient<Database>(
    url,
    anonKey,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user && !shouldBypassWelcomeCheck(request.nextUrl.pathname)) {
    const { data: profile } = await supabase
      .schema("identity")
      .from("user_profiles")
      .select("primary_organization_id")
      .eq("id", user.id)
      .maybeSingle();

    const needsWelcome = !profile || !profile.primary_organization_id;
    if (needsWelcome) {
      const redirectUrl = request.nextUrl.clone();
      redirectUrl.pathname = WELCOME_PATH;
      return NextResponse.redirect(redirectUrl);
    }
  }

  return response;
}
