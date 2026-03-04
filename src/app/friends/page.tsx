import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { FriendsSearch } from "@/components/FriendsSearch";
import Image from "next/image";

export default async function FriendsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/signin");
  }

  const { data: follows } = await supabase
    .from("follows")
    .select("following_id")
    .eq("follower_id", user.id);

  const ids = (follows || []).map((f) => f.following_id);
  let friends: { id: string; display_name: string | null; avatar_url: string | null }[] = [];

  if (ids.length > 0) {
    const { data: profiles } = await supabase
      .from("profiles")
      .select("id, display_name, avatar_url")
      .in("id", ids);
    friends = profiles || [];
  }

  return (
    <div className="min-h-screen bg-nightcap">
      <nav className="glass sticky top-0 z-10 border-b border-white/5">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <Link href="/" className="font-display text-2xl text-nightcap-accent">
            NightCapt
          </Link>
          <div className="flex items-center gap-4">
            <Link href="/feed" className="text-nightcap-muted hover:text-white transition">
              Feed
            </Link>
            <Link href="/entries" className="text-nightcap-muted hover:text-white transition">
              Entries
            </Link>
            <Link
              href="/entries/new"
              className="rounded-full bg-nightcap-accent px-5 py-2.5 font-medium text-white transition hover:opacity-90"
            >
              New Entry
            </Link>
          </div>
        </div>
      </nav>

      <main className="mx-auto max-w-2xl px-4 py-12">
        <h1 className="font-display text-4xl text-white mb-8">Friends</h1>

        <section className="mb-10">
          <h2 className="font-display text-xl text-nightcap-accent mb-4">Find friends</h2>
          <p className="text-nightcap-muted text-sm mb-4">
            Search by display name to find and follow people.
          </p>
          <FriendsSearch />
        </section>

        <section>
          <h2 className="font-display text-xl text-nightcap-accent mb-4">
            Following ({friends.length})
          </h2>
          {friends.length === 0 ? (
            <p className="text-nightcap-muted">You&apos;re not following anyone yet. Search above to find friends!</p>
          ) : (
            <div className="space-y-4">
              {friends.map((f) => (
                <Link
                  key={f.id}
                  href={`/profile/${f.id}`}
                  className="block glass rounded-2xl p-4 flex items-center gap-4 transition hover:border-nightcap-accent/30"
                >
                  <div className="relative w-12 h-12 rounded-full overflow-hidden bg-nightcap-muted flex-shrink-0">
                    {f.avatar_url ? (
                      <Image src={f.avatar_url} alt="" fill className="object-cover" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-nightcap-accent font-display text-lg">
                        {(f.display_name || "?")[0].toUpperCase()}
                      </div>
                    )}
                  </div>
                  <span className="text-white font-medium">
                    {f.display_name || "Unknown"}
                  </span>
                </Link>
              ))}
            </div>
          )}
        </section>
      </main>
    </div>
  );
}
