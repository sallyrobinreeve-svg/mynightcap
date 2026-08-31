import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { fetchFeedPage, getFeedAudienceIds } from "@/lib/feed";
import { FeedList } from "@/components/FeedList";
import { MissionsHighlight } from "@/components/MissionsHighlight";
import { BottomNav } from "@/components/BottomNav";
import { NotificationBell } from "@/components/NotificationBell";
import { NeonLogo } from "@/components/NeonLogo";

export default async function FeedPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/signin");
  }

  let feedEntries;
  let initialCursor;
  try {
    const audienceIds = await getFeedAudienceIds(supabase, user.id);
    const page = await fetchFeedPage(supabase, audienceIds, null);
    feedEntries = page.entries;
    initialCursor = page.nextCursor;
  } catch {
    return (
      <div className="min-h-screen bg-nightcap flex items-center justify-center">
        <p className="text-red-400">Failed to load feed</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-nightcap page-with-nav">
      <nav className="glass sticky top-0 z-10 border-b border-white/5 safe-area-pt">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
          <NeonLogo className="text-3xl" />
          <div className="flex items-center gap-2">
            <NotificationBell />
            <div className="hidden md:flex items-center gap-4">
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
        </div>
      </nav>

      <main className="mx-auto max-w-3xl px-4 py-12">
        <h1 className="font-display text-4xl text-white mb-8">Feed</h1>
        <MissionsHighlight />

        {feedEntries.length === 0 ? (
          <div className="glass rounded-2xl p-12 text-center">
            <p className="text-nightcap-muted mb-6">No entries in your feed yet.</p>
            <p className="text-nightcap-muted text-sm mb-6">
              Accept friend requests or add friends — their entries will appear here.
            </p>
            <Link
              href="/friends"
              className="inline-flex rounded-full glass px-6 py-3 font-medium text-white transition hover:border-nightcap-accent/50 mr-3"
            >
              Find friends
            </Link>
            <Link
              href="/entries/new"
              className="inline-flex rounded-full bg-nightcap-accent px-6 py-3 font-medium text-white transition hover:opacity-90"
            >
              Create first entry
            </Link>
          </div>
        ) : (
          <FeedList
            initialEntries={feedEntries}
            initialCursor={initialCursor}
            currentUserId={user.id}
          />
        )}
      </main>
      <BottomNav />
    </div>
  );
}
