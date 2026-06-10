import type { Metadata, Viewport } from 'next';
import { Cormorant_Garamond, Inter, Caveat } from 'next/font/google';
import './globals.css';
import { Nav } from '@/components/nav/Nav';
import { Footer } from '@/components/nav/Footer';
import { InstallPrompt } from '@/components/pwa/InstallPrompt';
import { ServiceWorkerRegister } from '@/components/pwa/ServiceWorkerRegister';
import { AuthProvider } from '@/lib/auth-store';
import { SessionSync } from '@/components/auth/SessionSync';
import { AudioProvider } from '@/lib/audio-context';
import { MiniPlayer } from '@/components/audio/MiniPlayer';
import { PageTransition } from '@/components/PageTransition';

const inter = Inter({ subsets: ['latin'], variable: '--font-sans', display: 'swap' });
const serif = Cormorant_Garamond({
  subsets: ['latin'],
  variable: '--font-serif',
  weight: ['300', '400', '500', '600'],
  style: ['normal', 'italic'],
  display: 'swap',
});
const hand = Caveat({ subsets: ['latin'], variable: '--font-hand', display: 'swap' });

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'https://heal.example.com'),
  title: { default: 'HEAL — A Quiet Practice', template: '%s · HEAL' },
  description: 'Daily Christian mindfulness. Guided meditations, breathwork, scripture, and prayers for a quieter soul.',
  applicationName: 'HEAL',
  authors: [{ name: 'HEAL' }],
  keywords: ['mindfulness', 'meditation', 'christian meditation', 'prayer', 'breathwork', 'scripture', 'daily devotion'],
  openGraph: {
    type: 'website',
    siteName: 'HEAL',
    title: 'HEAL — A Quiet Practice',
    description: 'Daily Christian mindfulness. A quiet practice for a noisy world.',
  },
  twitter: { card: 'summary_large_image', site: '@heal' },
  manifest: '/manifest.json',
  icons: {
    icon: '/icon.svg',
    apple: '/icon-192.png',
  },
  appleWebApp: { capable: true, statusBarStyle: 'default', title: 'HEAL' },
  formatDetection: { telephone: false },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  themeColor: '#F8F4ED',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${serif.variable} ${hand.variable}`}>
      <body className="min-h-screen bg-bone text-ink font-sans antialiased">
        <AuthProvider>
          <SessionSync />
          <a href="#main" className="sr-only focus:not-sr-only focus:fixed focus:top-4 focus:left-4 focus:z-50 focus:bg-paper focus:px-4 focus:py-2 focus:rounded-full">
            Skip to main content
          </a>
          <AudioProvider>
            <Nav />
            <PageTransition>
              <main id="main" className="min-h-[calc(100vh-160px)]">{children}</main>
            </PageTransition>
            <Footer />
            <MiniPlayer />
            <ServiceWorkerRegister />
            <InstallPrompt />
          </AudioProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
