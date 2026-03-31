"use client";

import { OfflineBanner } from "./OfflineBanner";

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <>
      <OfflineBanner />
      {children}
    </>
  );
}
