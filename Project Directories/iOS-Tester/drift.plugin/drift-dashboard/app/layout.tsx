import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Link from "next/link";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Drift — Design Compliance Dashboard",
  description: "Visual QA dashboard for iOS design compliance",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-[#0a0a0a] text-gray-200 min-h-screen`}>
        <nav className="border-b border-neutral-800 px-6 py-3 flex items-center justify-between">
          <div className="flex items-center gap-6">
            <Link href="/" className="text-lg font-semibold text-white tracking-tight">
              Drift
            </Link>
            <Link href="/" className="text-sm text-neutral-400 hover:text-white transition-colors">
              Runs
            </Link>
            <Link href="/settings" className="text-sm text-neutral-400 hover:text-white transition-colors">
              Settings
            </Link>
          </div>
          <span className="text-xs text-neutral-600">v0.1.0</span>
        </nav>
        <main>{children}</main>
      </body>
    </html>
  );
}
