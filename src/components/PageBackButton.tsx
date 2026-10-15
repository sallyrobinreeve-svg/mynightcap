"use client";

import { useRouter } from "next/navigation";

export function PageBackButton({ fallbackHref }: { fallbackHref: string }) {
  const router = useRouter();

  return (
    <button
      type="button"
      onClick={() => {
        if (window.history.length > 1) {
          router.back();
          return;
        }
        router.push(fallbackHref);
      }}
      className="inline-flex min-h-11 items-center gap-1 rounded-xl px-1 text-sm font-medium text-white transition hover:text-nightcap-accent"
    >
      ← Back
    </button>
  );
}
