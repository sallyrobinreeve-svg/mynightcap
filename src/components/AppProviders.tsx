"use client";

import { OfflineBanner } from "./OfflineBanner";
import { NativeAppShell } from "./NativeAppShell";
import { AppBootScreen } from "./AppBootScreen";
import { ServiceWorkerRegister } from "./ServiceWorkerRegister";

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <>
      <AppBootScreen />
      <NativeAppShell />
      <ServiceWorkerRegister />
      <OfflineBanner />
      {children}
    </>
  );
}
