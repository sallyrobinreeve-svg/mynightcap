import { createClient } from "@/lib/supabase/server";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const q = request.nextUrl.searchParams.get("q");
  if (!q || q.trim().length < 2) {
    return NextResponse.json({ users: [] });
  }

  const searchTerm = `%${q.trim()}%`;
  const { data: profiles, error } = await supabase
    .from("profiles")
    .select("id, display_name, avatar_url")
    .neq("id", user.id)
    .ilike("display_name", searchTerm)
    .limit(20);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const ids = (profiles || []).map((p) => p.id);
  if (ids.length === 0) {
    return NextResponse.json({ users: profiles || [] });
  }

  const { data: following } = await supabase
    .from("follows")
    .select("following_id")
    .eq("follower_id", user.id)
    .in("following_id", ids);

  const followingIds = new Set((following || []).map((f) => f.following_id));

  const users = (profiles || []).map((p) => ({
    ...p,
    isFollowing: followingIds.has(p.id),
  }));

  return NextResponse.json({ users });
}
