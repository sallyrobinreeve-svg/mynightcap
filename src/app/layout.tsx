import type { Metadata } from "next";
import { Quicksand, DM_Sans } from "next/font/google";
import "./globals.css";

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
  title: "NightCap | Capture the Chaos",
  description: "Record and share your nights out. Spill the tea, lock in the memory, capture the chaos.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${display.variable} ${body.variable}`}>
      <body className="font-body antialiased playful-bg min-h-screen">{children}</body>
    </html>
  );
}
