import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { format } from "date-fns";
import { DeleteEntryButton } from "@/components/DeleteEntryButton";

export default async function EntriesPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/signin");
  }

  const { data: entries, error } = await supabase
    .from("entries")
    .select("id, date_of_night, rating, created_at")
    .eq("user_id", user.id)
    .order("date_of_night", { ascending: false });

  if (error) {
    return (
      <div className="min-h-screen bg-nightcap flex items-center justify-center">
        <p className="text-red-400">Failed to load entries</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-nightcap">
      <nav className="glass sticky top-0 z-10 border-b border-white/5">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <Link href="/" className="font-display text-2xl text-nightcap-accent">
            NightCap
          </Link>
          <div className="flex items-center gap-4">
            <Link
              href="/entries/new"
              className="rounded-full bg-nightcap-accent px-5 py-2.5 font-medium text-white transition hover:opacity-90"
            >
              New Entry
            </Link>
            <Link href="/feed" className="text-nightcap-muted hover:text-white transition">
              Feed
            </Link>
            <Link href="/friends" className="text-nightcap-muted hover:text-white transition">
              Friends
            </Link>
            <Link href="/" className="text-nightcap-muted hover:text-white transition">
              Home
            </Link>
          </div>
        </div>
      </nav>

      <main className="mx-auto max-w-3xl px-4 py-12">
        <h1 className="font-display text-4xl text-white mb-8">Your entries</h1>

        {!entries?.length ? (
          <div className="glass rounded-2xl p-12 text-center">
            <p className="text-nightcap-muted mb-6">No entries yet. Log your first night out!</p>
            <Link
              href="/entries/new"
              className="inline-flex rounded-full bg-nightcap-accent px-6 py-3 font-medium text-white transition hover:opacity-90"
            >
              Create first entry
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {entries.map((entry) => (
              <div
                key={entry.id}
                className="glass rounded-2xl p-6 text-left transition hover:border-nightcap-accent/30"
              >
                <Link href={`/entries/${entry.id}`} className="block">
                <div className="flex justify-between items-start">
                  <div>
                    <p className="font-display text-xl text-white">
                      {format(new Date(entry.date_of_night), "EEEE, MMM d, yyyy")}
                    </p>
                    <p className="text-nightcap-muted text-sm mt-1">
                      {entry.rating
                        ? `${entry.rating} / 5 stars`
                        : "No rating"}
                    </p>
                  </div>
                  <span className="text-nightcap-muted text-sm">
                    {format(new Date(entry.created_at), "MMM d")}
                  </span>
                </div>
                </Link>
                <div className="mt-3 flex gap-4">
                  <Link
                    href={`/entries/${entry.id}/edit`}
                    className="text-nightcap-accent text-sm hover:underline"
                  >
                    Edit
                  </Link>
                  <DeleteEntryButton entryId={entry.id} variant="text" />
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
