"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, PlusCircle, Images, User } from "lucide-react";

export function BottomNav() {
  const pathname = usePathname();

  const isActive = (path: string) => {
    if (path === "/") return pathname === "/" || pathname === "/feed";
    return pathname.startsWith(path);
  };

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 glass border-t border-white/5 safe-area-pb">
      <div className="mx-auto flex max-w-lg items-center justify-around px-4 py-3">
        <Link
          href="/feed"
          className={`flex flex-col items-center gap-1 rounded-xl px-6 py-2 transition ${
            isActive("/feed") ? "text-nightcap-accent" : "text-nightcap-muted hover:text-white"
          }`}
        >
          <Home size={24} />
          <span className="text-xs font-medium">Feed</span>
        </Link>
        <Link
          href="/entries/new"
          className="flex flex-col items-center gap-1 rounded-2xl bg-nightcap-accent px-6 py-2.5 transition hover:scale-105 hover:shadow-lg hover:shadow-nightcap-accent/30"
        >
          <PlusCircle size={28} className="mb-0.5 text-white" />
          <span className="text-xs font-medium text-white">Create</span>
        </Link>
        <Link
          href="/memories"
          className={`flex flex-col items-center gap-1 rounded-xl px-6 py-2 transition ${
            isActive("/memories") ? "text-nightcap-accent" : "text-nightcap-muted hover:text-white"
          }`}
        >
          <Images size={24} />
          <span className="text-xs font-medium">Memories</span>
        </Link>
        <Link
          href="/profile"
          className={`flex flex-col items-center gap-1 rounded-xl px-6 py-2 transition ${
            isActive("/profile") ? "text-nightcap-accent" : "text-nightcap-muted hover:text-white"
          }`}
        >
          <User size={24} />
          <span className="text-xs font-medium">Profile</span>
        </Link>
      </div>
    </nav>
  );
}
