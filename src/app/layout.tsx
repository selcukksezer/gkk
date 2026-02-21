// =====================================================
// app/layout.tsx - Kök layout
// Tüm sayfalar için temel HTML yapısı
// =====================================================
import type { Metadata, Viewport } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Gölge Krallık: Kadim Mühür\'ün Çöküşü',
  description: 'Karanlık ortaçağ temalı mobil MMORPG oyunu. İzinsiz işler yürüt, tesis kur, loncalara katıl, PvP savaşlarına gir.',
  manifest: '/manifest.json',
  icons: {
    icon: '/favicon.ico',
    apple: '/apple-touch-icon.png',
  },
  keywords: ['mmorpg', 'mobil oyun', 'ortaçağ', 'rpg', 'türkçe oyun'],
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: 'cover',
  themeColor: '#0a0a0f',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="tr">
      <head>
        {/* Google Fonts – Oyun fontları */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700;900&family=Crimson+Text:ital,wght@0,400;0,600;1,400&family=Inter:wght@300;400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="bg-gk-dark text-white antialiased">
        {children}
      </body>
    </html>
  )
}
