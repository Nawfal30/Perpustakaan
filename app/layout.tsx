import type { Metadata } from "next";
import "./globals.css";
import { AppShell } from "@/components/app-shell";

export const metadata: Metadata = {
  title: "Pustaka Bersama — Sistem Manajemen Perpustakaan",
  description: "Sistem manajemen koleksi, anggota, sirkulasi, reservasi, dan denda untuk komunitas.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="id"><body><AppShell>{children}</AppShell></body></html>;
}
