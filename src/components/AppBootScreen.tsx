"use client";

import { useEffect, useState } from "react";

/** Branded overlay on native — covers the white gap while the remote page loads. */
export function AppBootScreen() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const cap = (window as Window & { Capacitor?: { isNativePlatform?: () => boolean } })
      .Capacitor;
    if (!cap?.isNativePlatform?.()) return;

    setVisible(true);
    document.documentElement.classList.add("native-app");

    const hide = () => {
      window.setTimeout(() => setVisible(false), 150);
    };

    if (document.readyState === "complete") {
      hide();
    } else {
      window.addEventListener("load", hide, { once: true });
    }

    return () => window.removeEventListener("load", hide);
  }, []);

  if (!visible) return null;

  return (
    <div
      className="fixed inset-0 z-[9999] flex flex-col items-center justify-center bg-[#1e1b24] safe-area-pt safe-area-pb safe-area-x"
      aria-hidden="true"
    >
      <p className="font-display text-3xl text-nightcap-accent">NightCapt</p>
      <div className="mt-6 h-8 w-8 animate-spin rounded-full border-2 border-nightcap-accent/30 border-t-nightcap-accent" />
    </div>
  );
}
