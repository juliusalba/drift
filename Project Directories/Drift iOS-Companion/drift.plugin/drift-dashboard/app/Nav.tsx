"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const links = [
  { href: "/", label: "Runs" },
  { href: "/settings", label: "Settings" },
];

export function Nav() {
  const pathname = usePathname();

  return (
    <nav className="sticky top-0 z-50 border-b border-neutral-800/80 bg-[#0a0a0a]/80 backdrop-blur-md px-6 py-3 flex items-center justify-between">
      <div className="flex items-center gap-6">
        <Link href="/" className="flex items-center gap-2 group">
          <div className="w-6 h-6 rounded-md bg-blue-500 flex items-center justify-center">
            <svg className="w-3.5 h-3.5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="M12 5v14M5 12h14" />
            </svg>
          </div>
          <span className="text-base font-semibold text-white tracking-tight group-hover:text-blue-400 transition-colors">
            Drift
          </span>
        </Link>

        <div className="h-4 w-px bg-neutral-800" />

        <div className="flex items-center gap-1">
          {links.map((link) => {
            const isActive =
              link.href === "/"
                ? pathname === "/" || pathname.startsWith("/runs")
                : pathname === link.href;

            return (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  "px-3 py-1.5 text-sm rounded-md transition-colors",
                  isActive
                    ? "bg-neutral-800 text-white font-medium"
                    : "text-neutral-400 hover:text-white hover:bg-neutral-800/50"
                )}
              >
                {link.label}
              </Link>
            );
          })}
        </div>
      </div>

      <div className="flex items-center gap-3">
        <span className="text-[11px] text-neutral-600 font-mono">v0.1.0</span>
        <div className="w-1.5 h-1.5 rounded-full bg-green-500/60" title="Connected" />
      </div>
    </nav>
  );
}
