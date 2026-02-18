"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

interface FollowButtonProps {
  userId: string;
  isFollowing: boolean;
}

export function FollowButton({ userId, isFollowing: initialFollowing }: FollowButtonProps) {
  const router = useRouter();
  const [isFollowing, setIsFollowing] = useState(initialFollowing);
  const [loading, setLoading] = useState(false);

  const toggle = async () => {
    setLoading(true);
    try {
      if (isFollowing) {
        await fetch(`/api/friends/follow?userId=${userId}`, { method: "DELETE" });
        setIsFollowing(false);
      } else {
        await fetch("/api/friends/follow", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ userId }),
        });
        setIsFollowing(true);
      }
      router.refresh();
    } finally {
      setLoading(false);
    }
  };

  return (
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
  );
}
