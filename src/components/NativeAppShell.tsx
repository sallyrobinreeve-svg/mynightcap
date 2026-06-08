"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

/**
 * Capacitor: deep links open in-app; Android/iOS back navigates in WebView history.
 */
export function NativeAppShell() {
  const router = useRouter();

  useEffect(() => {
    let removeOpen: (() => void) | undefined;
    let removeBack: (() => void) | undefined;

    void (async () => {
      try {
        const cap = (window as Window & { Capacitor?: { isNativePlatform?: () => boolean } }).Capacitor;
        if (!cap?.isNativePlatform?.()) return;

        // Installed in native builds via Codemagic; optional on web
        // @ts-expect-error Capacitor App plugin — present in iOS shell
        const { App } = await import(/* webpackIgnore: true */ "@capacitor/app");

        const openHandle = await App.addListener("appUrlOpen", ({ url }: { url: string }) => {
          try {
            const parsed = new URL(url);
            const path = `${parsed.pathname}${parsed.search}${parsed.hash}`;
            if (path && path !== "/") {
              if (path.startsWith("/auth/callback")) {
                router.replace(path);
              } else {
                router.push(path);
              }
            }
          } catch {
            // ignore malformed URLs
          }
        });
        removeOpen = () => openHandle.remove();

        const backHandle = await App.addListener("backButton", ({ canGoBack }: { canGoBack: boolean }) => {
          if (canGoBack) {
            window.history.back();
          } else {
            void App.exitApp();
          }
        });
        removeBack = () => backHandle.remove();
      } catch {
        // @capacitor/app not available in browser
      }
    })();

    return () => {
      removeOpen?.();
      removeBack?.();
    };
  }, [router]);

  return null;
}
