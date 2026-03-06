import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { blocked_id } = await req.json();
  if (!blocked_id) return NextResponse.json({ error: "blocked_id required" }, { status: 400 });
  if (blocked_id === user.id) return NextResponse.json({ error: "Cannot block yourself" }, { status: 400 });

  const { error } = await supabase.from("blocks").insert({
    blocker_id: user.id,
    blocked_id,
  });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}

export async function DELETE(req: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { searchParams } = new URL(req.url);
  const blocked_id = searchParams.get("blocked_id");
  if (!blocked_id) return NextResponse.json({ error: "blocked_id required" }, { status: 400 });

  const { error } = await supabase
    .from("blocks")
    .delete()
    .eq("blocker_id", user.id)
    .eq("blocked_id", blocked_id);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
