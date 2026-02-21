import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // Capacitor için static export
  // output: 'export', // Uncomment when building for Capacitor
  images: {
    // remotePatterns dizisini güvenli tutmak için sadece kendi Supabase domain'imize izin veriyoruz
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'znvsyzstmxhqvdkkmgdt.supabase.co',
        pathname: '/storage/v1/object/public/**',
      },
    ],
  },
  experimental: {
    // App Router özellikleri
  },
}

export default nextConfig
