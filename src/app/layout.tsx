import type { Metadata, Viewport } from "next";
import { Quicksand, DM_Sans } from "next/font/google";
import "./globals.css";
import { EnvGate } from "@/components/EnvGate";
import { AppProviders } from "@/components/AppProviders";

const display = Quicksand({
  weight: ["400", "500", "600", "700"],
  subsets: ["latin"],
  variable: "--font-display",
});

const body = DM_Sans({
  subsets: ["latin"],
  variable: "--font-body",
});

export const metadata: Metadata = {
  title: "NightCapt | Capture the Chaos",
  description: "Record and share your nights out. Spill the tea, lock in the memory, capture the chaos.",
  manifest: "/manifest.webmanifest",
  appleWebApp: {
    capable: true,
    title: "NightCapt",
    statusBarStyle: "black-translucent",
  },
  icons: {
    icon: [
      { url: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/icons/apple-touch-icon.png", sizes: "180x180", type: "image/png" }],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  viewportFit: "cover",
  themeColor: "#1e1b24",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${display.variable} ${body.variable}`} style={{ backgroundColor: "#1e1b24" }}>
      <body className="font-body antialiased playful-bg min-h-screen safe-area-x">
        <EnvGate>
          <AppProviders>{children}</AppProviders>
        </EnvGate>
      </body>
    </html>
  );
}
