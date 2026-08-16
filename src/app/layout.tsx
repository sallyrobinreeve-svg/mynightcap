import type { Metadata, Viewport } from "next";
import { Inter, Yellowtail } from "next/font/google";
import "./globals.css";
import { EnvGate } from "@/components/EnvGate";
import { AppProviders } from "@/components/AppProviders";

const body = Inter({
  subsets: ["latin"],
  variable: "--font-body",
});

const script = Yellowtail({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-script",
});

export const metadata: Metadata = {
  title: "NightCapt | Every Good Night Deserves a Recap",
  description: "The social diary for nights out. Remember the night, relive the debrief, and turn nights out into lasting memories with friends.",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  viewportFit: "cover",
  themeColor: "#000000",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${body.variable} ${script.variable}`} style={{ backgroundColor: "#000000" }}>
      <body className="font-body antialiased playful-bg min-h-screen safe-area-x">
        <EnvGate>
          <AppProviders>{children}</AppProviders>
        </EnvGate>
      </body>
    </html>
  );
}
