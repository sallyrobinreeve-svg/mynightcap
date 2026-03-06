import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { EntryCard } from "@/components/EntryCard";
import { MissionsHighlight } from "@/components/MissionsHighlight";
import { BottomNav } from "@/components/BottomNav";

export default async function FeedPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/signin");
  }

  const { data: blocked } = await supabase
    .from("blocks")
    .select("blocked_id")
    .eq("blocker_id", user.id);
  const blockedIds = new Set((blocked || []).map((b) => b.blocked_id));

  const { data: entries, error } = await supabase
    .from("entries")
    .select("id, user_id, date_of_night, rating, prompts, created_at")
    .order("date_of_night", { ascending: false })
    .limit(50);

  if (error) {
    return (
      <div className="min-h-screen bg-nightcap flex items-center justify-center">
        <p className="text-red-400">Failed to load feed</p>
      </div>
    );
  }

  const userIds = Array.from(new Set((entries || []).map((e) => e.user_id)));
  const { data: profiles } = await supabase
    .from("profiles")
    .select("id, display_name, avatar_url")
    .in("id", userIds);

  const profileMap = new Map((profiles || []).map((p) => [p.id, p]));

  const entryIds = (entries || []).map((e) => e.id);
  const { data: photos } = await supabase
    .from("photos")
    .select("entry_id, type, url")
    .in("entry_id", entryIds);

  const photoMap = new Map<string, string>();
  (photos || []).forEach((p) => {
    if ((p.type === "favourite" || p.type === "outfit") && !photoMap.has(p.entry_id)) {
      photoMap.set(p.entry_id, p.url);
    }
  });

  const { data: reactions } = await supabase
    .from("reactions")
    .select("entry_id, type")
    .in("entry_id", entryIds);

  const reactionCountMap = new Map<string, number>();
  (reactions || []).forEach((r) => {
    reactionCountMap.set(r.entry_id, (reactionCountMap.get(r.entry_id) || 0) + 1);
  });

  const { data: commentCounts } = await supabase
    .from("comments")
    .select("entry_id")
    .in("entry_id", entryIds);

  const commentCountMap = new Map<string, number>();
  (commentCounts || []).forEach((c) => {
    commentCountMap.set(c.entry_id, (commentCountMap.get(c.entry_id) || 0) + 1);
  });

  const filteredEntries = (entries || []).filter((e) => !blockedIds.has(e.user_id));
  const feedEntries = filteredEntries.map((e) => ({
    ...e,
    profile: profileMap.get(e.user_id),
    thumbnailUrl: photoMap.get(e.id) || null,
    reactionCount: reactionCountMap.get(e.id) || 0,
    commentCount: commentCountMap.get(e.id) || 0,
  }));

  return (
    <div className="min-h-screen bg-nightcap pb-24">
      <nav className="glass sticky top-0 z-10 border-b border-white/5">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <Link href="/" className="font-display text-2xl text-nightcap-accent">
            NightCapt
          </Link>
          <div className="flex items-center gap-4">
            <Link
              href="/entries/new"
              className="rounded-full bg-nightcap-accent px-5 py-2.5 font-medium text-white transition hover:opacity-90"
            >
              New Entry
            </Link>
            <Link href="/friends" className="text-nightcap-muted hover:text-white transition">
              Friends
            </Link>
            <Link href="/entries" className="text-nightcap-muted hover:text-white transition">
              Entries
            </Link>
            <Link href="/profile" className="text-nightcap-muted hover:text-white transition">
              Profile
            </Link>
          </div>
        </div>
      </nav>

      <main className="mx-auto max-w-3xl px-4 py-12">
        <h1 className="font-display text-4xl text-white mb-8">Feed</h1>
        <MissionsHighlight />

        {feedEntries.length === 0 ? (
          <div className="glass rounded-2xl p-12 text-center">
            <p className="text-nightcap-muted mb-6">No entries in your feed yet.</p>
            <p className="text-nightcap-muted text-sm mb-6">
              Follow friends or create your own entry to get started!
            </p>
            <Link
              href="/entries/new"
              className="inline-flex rounded-full bg-nightcap-accent px-6 py-3 font-medium text-white transition hover:opacity-90"
            >
              Create first entry
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {feedEntries.map((entry) => (
              <EntryCard key={entry.id} entry={entry} currentUserId={user.id} />
            ))}
          </div>
        )}
      </main>
      <BottomNav />
    </div>
  );
}
