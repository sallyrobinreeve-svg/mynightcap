import Link from "next/link";
import Image from "next/image";
import { format } from "date-fns";
import { MessageCircle, Flame } from "lucide-react";

interface EntryCardProps {
  entry: {
    id: string;
    user_id: string;
    date_of_night: string;
    rating: number | null;
    prompts?: Record<string, unknown>;
    profile?: { id: string; display_name: string | null; avatar_url: string | null };
    thumbnailUrl?: string | null;
    reactionCount?: number;
    commentCount?: number;
  };
  currentUserId: string;
}

export function EntryCard({ entry, currentUserId }: EntryCardProps) {
  const isOwn = entry.user_id === currentUserId;
  const mission = entry.prompts?.mission as string | undefined;

  return (
    <Link
      href={`/entries/${entry.id}`}
      className="block glass rounded-2xl hover-lift overflow-hidden transition hover:border-nightcap-accent/30"
    >
      <div className="flex gap-4 p-6">
        <div className="relative w-24 h-24 rounded-xl overflow-hidden bg-nightcap-muted flex-shrink-0">
          {entry.thumbnailUrl ? (
            <Image
              src={entry.thumbnailUrl}
              alt=""
              fill
              className="object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-nightcap-muted text-2xl">
              {entry.rating || "–"}
            </div>
          )}
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-display text-xl text-white">
            {format(new Date(entry.date_of_night), "EEEE, MMM d, yyyy")}
          </p>
          {!isOwn && entry.profile && (
            <Link
              href={`/profile/${entry.profile.id}`}
              onClick={(e) => e.stopPropagation()}
              className="text-nightcap-accent hover:underline text-sm mt-1 block"
            >
              by {entry.profile.display_name || "Anonymous"}
            </Link>
          )}
          {entry.rating && (
            <p className="text-nightcap-pink text-sm mt-1">{entry.rating} / 5 stars</p>
          )}
          {mission && (
            <p className="text-nightcap-muted text-sm mt-1 line-clamp-1">Mission: {mission}</p>
          )}
          <div className="flex gap-4 mt-2 text-nightcap-muted text-sm">
            <span className="flex items-center gap-1">
              <Flame size={14} />
              {entry.reactionCount || 0}
            </span>
            <span className="flex items-center gap-1">
              <MessageCircle size={14} />
              {entry.commentCount || 0}
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}
