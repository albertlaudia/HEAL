/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false, // don't leak Next.js
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '**.backblazeb2.com' },
      { protocol: 'https', hostname: 'f004.backblazeb2.com' },
      { protocol: 'https', hostname: 'pocketbase.scaleupcrm.com' },
    ],
  },
  async headers() {
    const isProd = process.env.NODE_ENV === 'production';
    const securityHeaders = [
      { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
      { key: 'X-Content-Type-Options', value: 'nosniff' },
      { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
      { key: 'X-DNS-Prefetch-Control', value: 'on' },
      { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
      // CSP — careful with Firebase + audio + PocketBase
      {
        key: 'Content-Security-Policy',
        value: [
          "default-src 'self'",
          "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.firebaseio.com https://*.googleapis.com https://*.firebaseapp.com", // Next.js needs unsafe-inline for hydration, Firebase SDK
          "style-src 'self' 'unsafe-inline'", // Tailwind inlines styles
          "img-src 'self' data: blob: https: http:",
          "media-src 'self' https://*.backblazeb2.com https://f004.backblazeb2.com https://s3.us-west-004.backblazeb2.com blob:",
          "font-src 'self' data:",
          "connect-src 'self' https://*.firebaseio.com https://*.googleapis.com https://*.firebaseapp.com wss://*.firebaseio.com https://pocketbase.scaleupcrm.com https://identitytoolkit.googleapis.com https://securetoken.googleapis.com",
          "frame-ancestors 'self'",
          "base-uri 'self'",
          "form-action 'self'",
        ].join('; '),
      },
    ];

    if (isProd) {
      securityHeaders.push(
        { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' }
      );
    }

    return [
      {
        source: '/(.*)',
        headers: securityHeaders,
      },
      // Cache static assets aggressively
      {
        source: '/audio/(.*)',
        headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
        ],
      },
      {
        source: '/images/(.*)',
        headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
        ],
      },
      {
        source: '/_next/static/(.*)',
        headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
        ],
      },
    ];
  },
};
export default nextConfig;
