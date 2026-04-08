import type { Metadata } from "next";
import { Geist } from "next/font/google";
import "./globals.css";
import Sidebar from "@/components/Sidebar";
import { getSession } from "@/lib/session";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Sirius Edu - Panel del Profesor",
  description: "Sistema educativo para comunidades rurales de Colombia",
};

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession();

  return (
    <html lang="es" className={`${geistSans.variable} h-full antialiased light`} data-theme="light">
      <body className="min-h-full bg-gray-50 text-gray-900">
        {session ? (
          <div className="flex min-h-screen">
            <Sidebar teacherName={session.teacher_name} schoolName={session.school_name} />
            <main className="flex-1 p-6 md:p-8">{children}</main>
          </div>
        ) : (
          <main className="min-h-screen">{children}</main>
        )}
      </body>
    </html>
  );
}
