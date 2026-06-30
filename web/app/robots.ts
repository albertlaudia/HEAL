import type { MetadataRoute } from 'next';

const SITE = (process.env.NEXT_PUBLIC_SITE_URL || 'https://heal.positiveness.club').replace(/\/$/, '');

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      // Allow everything for regular crawlers
      {
        userAgent: '*',
        allow: '/',
        disallow: [
          '/api/',        // API routes
          '/journal',     // user-private content (redirects to signin if not authed)
          '/history',     // user-private
          '/favorites',   // user-private
        ],
      },
      // Block AI training crawlers explicitly
      {
        userAgent: ['GPTBot', 'CCBot', 'ClaudeBot', 'Google-Extended', 'Applebot-Extended', 'anthropic-ai'],
        disallow: '/',
      },
    ],
    sitemap: `${SITE}/sitemap.xml`,
    host: SITE,
  };
}