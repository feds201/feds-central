import type { Metadata } from "next";
import "./globals.css";
import Link from "next/link";
import { Search, Settings, Home } from "lucide-react";

export const metadata: Metadata = {
  title: "Scout Ops LookUp",
  description: "FRC Team Profiles and Scouting Data",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body suppressHydrationWarning>
        <nav style={{ background: 'var(--surface)', borderBottom: '1px solid var(--border)', padding: '1rem 0' }}>
          <div className="container flex justify-between items-center">
            <div className="flex items-center gap-2">
              <span style={{ fontSize: '1.5rem', fontWeight: 'bold', color: 'var(--primary)' }}>Scout Ops</span>
              <span style={{ fontSize: '1.5rem', fontWeight: '300', color: 'var(--foreground)' }}>LookUp</span>
            </div>
            <div className="flex gap-4">
              <Link href="/" className="flex items-center gap-2" style={{ color: 'var(--foreground)', fontWeight: 500 }}>
                <Home size={18} /> Home
              </Link>
              <Link href="/teams" className="flex items-center gap-2" style={{ color: 'var(--foreground)', fontWeight: 500 }}>
                <Search size={18} /> Teams
              </Link>
              <Link href="/settings" className="flex items-center gap-2" style={{ color: 'var(--foreground)', fontWeight: 500 }}>
                <Settings size={18} /> Settings
              </Link>
            </div>
          </div>
        </nav>
        <main className="container my-8">
          {children}
        </main>
      </body>
    </html>
  );
}