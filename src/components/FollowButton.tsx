"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { fetchOk } from "@/lib/fetch-client";

interface FollowButtonProps {
  userId: string;
  isFollowing: boolean;
}

export function FollowButton({ userId, isFollowing: initialFollowing }: FollowButtonProps) {
  const router = useRouter();
  const [isFollowing, setIsFollowing] = useState(initialFollowing);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const toggle = async () => {
    setLoading(true);
    setError(null);
    try {
      if (isFollowing) {
        const result = await fetchOk(`/api/friends/follow?userId=${userId}`, { method: "DELETE" });
        if (!result.ok) {
          setError(result.message);
          return;
        }
        setIsFollowing(false);
        router.refresh();
      } else {
        const result = await fetchOk("/api/friends/follow", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ userId }),
        });
        if (!result.ok) {
          setError(result.message);
          return;
        }
        setIsFollowing(true);
        router.refresh();
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <button
        type="button"
        onClick={toggle}
        disabled={loading}
        className={`mt-4 rounded-lg px-5 py-2.5 text-sm font-medium transition disabled:opacity-50 ${
          isFollowing
            ? "bg-nightcap-muted text-nightcap-muted"
            : "bg-nightcap-accent text-white hover:opacity-90"
        }`}
      >
        {loading ? "..." : isFollowing ? "Following" : "Follow"}
      </button>
      {error && <p className="text-red-400 text-xs mt-2 max-w-xs">{error}</p>}
    </div>
  );
}
