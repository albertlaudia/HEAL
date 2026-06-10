import { MetadataRoute } from 'next';

const SITE = process.env.NEXT_PUBLIC_SITE_URL || 'https://heal.app';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow: ['/api/', '/admin/'] },
    ],
    sitemap: `${SITE}/sitemap.xml`,
    host: SITE,
  };
}
