import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Nav } from "./Nav";

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
        <Nav />
        <main>{children}</main>
      </body>
    </html>
  );
}
