import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// The panel has no accounts of its own, so the hosted copy sits behind browser
// Basic Auth: any login, password = ADMIN_PASSWORD. Locally (`next dev`, no
// VERCEL env) nothing changes. On Vercel without the variable the panel stays
// closed instead of silently opening up.
export function proxy(request: NextRequest) {
  const password = process.env.ADMIN_PASSWORD;
  if (!password) {
    if (!process.env.VERCEL) return NextResponse.next();
    return new NextResponse("ADMIN_PASSWORD sozlanmagan.", { status: 503 });
  }

  if (safeEqual(basicAuthPassword(request), password)) return NextResponse.next();

  return new NextResponse("Kirish uchun parol kerak.", {
    status: 401,
    headers: { "WWW-Authenticate": 'Basic realm="Gaz & Energiya admin", charset="UTF-8"' },
  });
}

function basicAuthPassword(request: NextRequest): string {
  const header = request.headers.get("authorization") ?? "";
  if (!header.startsWith("Basic ")) return "";
  try {
    const decoded = atob(header.slice(6));
    return decoded.slice(decoded.indexOf(":") + 1);
  } catch {
    return "";
  }
}

// Constant-time, so response timing doesn't leak how much of the password matched.
function safeEqual(a: string, b: string): boolean {
  let diff = a.length ^ b.length;
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    diff |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  }
  return diff === 0;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|sw.js).*)"],
};
