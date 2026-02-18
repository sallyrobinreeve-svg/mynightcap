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

  const { data: follows } = await supabase
    .from("follows")
    .select("following_id")
    .eq("follower_id", user.id);

  const friendIds = (follows || []).map((f) => f.following_id);
  const allIds = [user.id, ...friendIds];

  const { data: profiles } = await supabase
    .from("profiles")
    .select("id, display_name, avatar_url")
    .in("id", allIds);

  const { data: stats } = await supabase
    .from("user_stats")
    .select("user_id, total_entries, avg_rating, kiss_count, missions_completed, top_club_visits")
    .in("user_id", allIds);

  const profileMap = new Map((profiles || []).map((p) => [p.id, p]));
  const statsMap = new Map((stats || []).map((s) => [s.user_id, s]));

  const leaderboard = allIds.map((id) => {
    const profile = profileMap.get(id);
    const s = statsMap.get(id);
    return {
      id,
      display_name: profile?.display_name ?? "Unknown",
      avatar_url: profile?.avatar_url ?? null,
      isMe: id === user.id,
      total_entries: s?.total_entries ?? 0,
      avg_rating: s?.avg_rating ?? null,
      kiss_count: s?.kiss_count ?? 0,
      missions_completed: s?.missions_completed ?? 0,
      top_club_visits: s?.top_club_visits ?? 0,
    };
  });

  return NextResponse.json({ leaderboard });
}
