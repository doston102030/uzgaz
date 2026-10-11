import { readFile } from "fs/promises";
import path from "path";

// The Tizim page copies a setup file's full text for the Supabase SQL Editor.
// Only these files, read from the repo's supabase/ folder next to the panel.
const FILES = new Set(["seller_workflow_setup.sql", "seller_login_setup.sql", "marketplace_setup.sql"]);

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const file = new URL(request.url).searchParams.get("file") ?? "";
  if (!FILES.has(file)) {
    return new Response("Bunday SQL fayl yo'q.", { status: 404 });
  }
  try {
    const sql = await readFile(path.join(process.cwd(), "..", "supabase", file), "utf8");
    return new Response(sql, {
      headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" },
    });
  } catch {
    return new Response(`supabase/${file} topilmadi — loyiha papkasidan oching.`, { status: 404 });
  }
}
