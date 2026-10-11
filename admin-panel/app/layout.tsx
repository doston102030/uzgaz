import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { AdminShell } from "@/components/Shell";
import { StaleServiceWorkerCleanup } from "@/components/StaleServiceWorkerCleanup";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Gaz & Energiya — Admin panel",
  description: "Andijon viloyati gaz va energiya marketpleysi uchun boshqaruv paneli.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uz" className={`${geistSans.variable} ${geistMono.variable} h-full`}>
      <body className="flex h-full min-h-screen bg-background font-sans antialiased">
        <StaleServiceWorkerCleanup />
        <AdminShell>{children}</AdminShell>
      </body>
    </html>
  );
}
