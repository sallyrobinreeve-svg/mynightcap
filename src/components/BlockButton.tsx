"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

interface BlockButtonProps {
  userId: string;
  displayName?: string | null;
}

export function BlockButton({ userId, displayName }: BlockButtonProps) {
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleBlock = async () => {
    if (!confirm(`Block ${displayName || "this user"}? Their content will be removed from your feed.`)) return;
    setLoading(true);
    try {
      const res = await fetch("/api/block", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ blocked_id: userId }),
      });
      if (res.ok) {
        router.refresh();
        router.push("/feed");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      onClick={handleBlock}
      disabled={loading}
      className="mt-2 text-sm text-red-400 hover:text-red-300 disabled:opacity-50"
    >
      {loading ? "Blocking..." : "Block user"}
    </button>
  );
}
