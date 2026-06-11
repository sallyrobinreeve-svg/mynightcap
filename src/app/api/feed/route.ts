import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import {
  FEED_PAGE_SIZE,
  fetchFeedPage,
  getFeedAudienceIds,
  type FeedCursor,
} from "@/lib/feed";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const cursorDate = searchParams.get("cursorDate");
  const cursorId = searchParams.get("cursorId");
  const cursor: FeedCursor | null =
    cursorDate && cursorId ? { date: cursorDate, id: cursorId } : null;

  try {
    const audienceIds = await getFeedAudienceIds(supabase, user.id);
    const page = await fetchFeedPage(supabase, audienceIds, cursor, FEED_PAGE_SIZE);
    return NextResponse.json(page);
  } catch {
    return NextResponse.json({ error: "Failed to load feed" }, { status: 500 });
  }
}
