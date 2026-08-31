"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { EntryCard } from "@/components/EntryCard";
import type { FeedCursor, FeedEntry } from "@/lib/feed";

interface FeedListProps {
  initialEntries: FeedEntry[];
  initialCursor: FeedCursor | null;
  currentUserId: string;
}

export function FeedList({ initialEntries, initialCursor, currentUserId }: FeedListProps) {
  const [entries, setEntries] = useState<FeedEntry[]>(initialEntries);
  const [cursor, setCursor] = useState<FeedCursor | null>(initialCursor);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const sentinelRef = useRef<HTMLDivElement | null>(null);
  const seenIds = useRef(new Set(initialEntries.map((e) => e.id)));

  const loadMore = useCallback(async () => {
    if (loading || !cursor) return;
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({ cursorDate: cursor.date, cursorId: cursor.id });
      const res = await fetch(`/api/feed?${params.toString()}`);
      if (!res.ok) throw new Error("Failed to load more");
      const page: { entries: FeedEntry[]; nextCursor: FeedCursor | null } = await res.json();

      const fresh = page.entries.filter((e) => !seenIds.current.has(e.id));
      fresh.forEach((e) => seenIds.current.add(e.id));

      setEntries((prev) => [...prev, ...fresh]);
      setCursor(page.nextCursor);
    } catch {
      setError("Couldn't load more entries. Tap to retry.");
    } finally {
      setLoading(false);
    }
  }, [cursor, loading]);

  useEffect(() => {
    const node = sentinelRef.current;
    if (!node || !cursor) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting) loadMore();
      },
      { rootMargin: "400px" }
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [cursor, loadMore]);

  return (
    <div className="space-y-4">
      {entries.map((entry) => (
        <EntryCard key={entry.id} entry={entry} currentUserId={currentUserId} />
      ))}

      {cursor && <div ref={sentinelRef} aria-hidden="true" className="h-px w-full" />}

      {loading && (
        <div className="flex justify-center py-6">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-nightcap-accent/30 border-t-nightcap-accent" />
        </div>
      )}

      {error && (
        <button
          onClick={loadMore}
          className="w-full rounded-xl glass py-3 text-sm text-nightcap-accent transition hover:border-nightcap-accent/50"
        >
          {error}
        </button>
      )}

      {!cursor && !loading && entries.length > 0 && (
        <p className="py-6 text-center text-sm text-nightcap-muted">You&apos;re all caught up.</p>
      )}
    </div>
  );
}
