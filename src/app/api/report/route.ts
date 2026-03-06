import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const body = await req.json();
  const { reported_user_id, entry_id, comment_id, reason } = body;
  if (!reported_user_id) return NextResponse.json({ error: "reported_user_id required" }, { status: 400 });
  if (reported_user_id === user.id) return NextResponse.json({ error: "Cannot report yourself" }, { status: 400 });

  const { error } = await supabase.from("reports").insert({
    reporter_id: user.id,
    reported_user_id,
    entry_id: entry_id || null,
    comment_id: comment_id || null,
    reason: reason || null,
  });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
