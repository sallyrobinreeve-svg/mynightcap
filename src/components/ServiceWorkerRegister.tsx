"use client";

import { useEffect } from "react";

/**
 * Registers the app-shell service worker so the app launches instantly and
 * survives flaky connections. Only runs in production builds — the dev server
 * serves non-hashed assets, so caching there would be confusing.
 */
export function ServiceWorkerRegister() {
  useEffect(() => {
    if (process.env.NODE_ENV !== "production") return;
    if (typeof navigator === "undefined" || !("serviceWorker" in navigator)) return;

    const register = () => {
      navigator.serviceWorker.register("/sw.js").catch(() => {
        // Service worker is a progressive enhancement; ignore failures.
      });
    };

    if (document.readyState === "complete") {
      register();
    } else {
      window.addEventListener("load", register, { once: true });
      return () => window.removeEventListener("load", register);
    }
  }, []);

  return null;
}
