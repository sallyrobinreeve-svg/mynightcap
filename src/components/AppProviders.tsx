"use client";

import { OfflineBanner } from "./OfflineBanner";
import { NativeAppShell } from "./NativeAppShell";

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <>
      <NativeAppShell />
      <OfflineBanner />
      {children}
    </>
  );
}
