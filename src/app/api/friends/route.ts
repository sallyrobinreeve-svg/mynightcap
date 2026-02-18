import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function GET() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { data: follows, error: followsError } = await supabase
    .from("follows")
    .select("following_id")
    .eq("follower_id", user.id);

  if (followsError) {
    return NextResponse.json({ error: followsError.message }, { status: 500 });
  }

  const ids = (follows || []).map((f) => f.following_id);
  if (ids.length === 0) {
    return NextResponse.json({ friends: [] });
  }

  const { data: profiles, error: profilesError } = await supabase
    .from("profiles")
    .select("id, display_name, avatar_url")
    .in("id", ids);

  if (profilesError) {
    return NextResponse.json({ error: profilesError.message }, { status: 500 });
  }

  return NextResponse.json({ friends: profiles || [] });
}
