import type { SupabaseClient } from "@supabase/supabase-js";
import { acceptedFriendIdsFromRows } from "@/lib/friends";

export const FEED_PAGE_SIZE = 15;

export interface FeedCursor {
  date: string;
  id: string;
}

export interface FeedEntry {
  id: string;
  user_id: string;
  date_of_night: string;
  rating: number | null;
  prompts: Record<string, unknown>;
  created_at: string;
  profile?: { id: string; display_name: string | null; avatar_url: string | null };
  thumbnailUrl: string | null;
  reactionCount: number;
  commentCount: number;
}

export interface FeedPage {
  entries: FeedEntry[];
  nextCursor: FeedCursor | null;
}

/**
 * The set of user IDs whose entries belong in `userId`'s feed: the user
 * themselves plus accepted friends, excluding anyone they've blocked.
 * Row-level security further restricts which of those entries are visible
 * (own + public + friends-only), so visibility is enforced in the database.
 */
export async function getFeedAudienceIds(
  supabase: SupabaseClient,
  userId: string
): Promise<string[]> {
  const [{ data: blocked }, { data: friendRows }] = await Promise.all([
    supabase.from("blocks").select("blocked_id").eq("blocker_id", userId),
    supabase
      .from("follows")
      .select("follower_id, following_id, status")
      .eq("status", "accepted")
      .or(`follower_id.eq.${userId},following_id.eq.${userId}`),
  ]);

  const blockedIds = new Set((blocked || []).map((b) => b.blocked_id));
  const friendIds = acceptedFriendIdsFromRows(friendRows || [], userId);

  const audience = new Set<string>([userId]);
  friendIds.forEach((id) => {
    if (!blockedIds.has(id)) audience.add(id);
  });
  return Array.from(audience);
}

/**
 * Fetch a single page of feed entries using keyset pagination on
 * (date_of_night desc, id desc). Only the entries for this page are enriched
 * with profile, thumbnail and reaction/comment counts, so the work stays
 * bounded regardless of how many total entries exist.
 */
export async function fetchFeedPage(
  supabase: SupabaseClient,
  audienceIds: string[],
  cursor: FeedCursor | null,
  limit: number = FEED_PAGE_SIZE
): Promise<FeedPage> {
  if (audienceIds.length === 0) {
    return { entries: [], nextCursor: null };
  }

  let query = supabase
    .from("entries")
    .select("id, user_id, date_of_night, rating, prompts, created_at")
    .in("user_id", audienceIds)
    .order("date_of_night", { ascending: false })
    .order("id", { ascending: false })
    .limit(limit);

  if (cursor) {
    query = query.or(
      `date_of_night.lt.${cursor.date},and(date_of_night.eq.${cursor.date},id.lt.${cursor.id})`
    );
  }

  const { data: rows, error } = await query;
  if (error) throw error;

  const entries = rows || [];
  if (entries.length === 0) {
    return { entries: [], nextCursor: null };
  }

  const entryIds = entries.map((e) => e.id);
  const userIds = Array.from(new Set(entries.map((e) => e.user_id)));

  const [{ data: profiles }, { data: photos }, { data: reactions }, { data: comments }] =
    await Promise.all([
      supabase.from("profiles").select("id, display_name, avatar_url").in("id", userIds),
      supabase.from("photos").select("entry_id, type, url").in("entry_id", entryIds),
      supabase.from("reactions").select("entry_id").in("entry_id", entryIds),
      supabase.from("comments").select("entry_id").in("entry_id", entryIds),
    ]);

  const profileMap = new Map((profiles || []).map((p) => [p.id, p]));

  const photoMap = new Map<string, string>();
  (photos || []).forEach((p) => {
    if ((p.type === "favourite" || p.type === "outfit") && !photoMap.has(p.entry_id)) {
      photoMap.set(p.entry_id, p.url);
    }
  });

  const reactionCountMap = new Map<string, number>();
  (reactions || []).forEach((r) => {
    reactionCountMap.set(r.entry_id, (reactionCountMap.get(r.entry_id) || 0) + 1);
  });

  const commentCountMap = new Map<string, number>();
  (comments || []).forEach((c) => {
    commentCountMap.set(c.entry_id, (commentCountMap.get(c.entry_id) || 0) + 1);
  });

  const feedEntries: FeedEntry[] = entries.map((e) => ({
    id: e.id,
    user_id: e.user_id,
    date_of_night: e.date_of_night,
    rating: e.rating,
    prompts: (e.prompts as Record<string, unknown>) || {},
    created_at: e.created_at,
    profile: profileMap.get(e.user_id),
    thumbnailUrl: photoMap.get(e.id) || null,
    reactionCount: reactionCountMap.get(e.id) || 0,
    commentCount: commentCountMap.get(e.id) || 0,
  }));

  const last = entries[entries.length - 1];
  const nextCursor =
    entries.length === limit ? { date: last.date_of_night, id: last.id } : null;

  return { entries: feedEntries, nextCursor };
}
