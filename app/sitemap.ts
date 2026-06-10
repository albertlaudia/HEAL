import { MetadataRoute } from 'next';
import { getPublished } from '@/lib/pb';
import { pb } from '@/lib/pb';

const SITE = process.env.NEXT_PUBLIC_SITE_URL || 'https://heal.app';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const now = new Date();

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${SITE}/`, lastModified: now, changeFrequency: 'daily', priority: 1 },
    { url: `${SITE}/meditate`, lastModified: now, changeFrequency: 'daily', priority: 0.9 },
    { url: `${SITE}/breathe`, lastModified: now, changeFrequency: 'monthly', priority: 0.8 },
    { url: `${SITE}/scripture`, lastModified: now, changeFrequency: 'weekly', priority: 0.8 },
    { url: `${SITE}/prayers`, lastModified: now, changeFrequency: 'weekly', priority: 0.8 },
    { url: `${SITE}/praise`, lastModified: now, changeFrequency: 'weekly', priority: 0.8 },
    { url: `${SITE}/essays`, lastModified: now, changeFrequency: 'weekly', priority: 0.7 },
    { url: `${SITE}/about`, lastModified: now, changeFrequency: 'monthly', priority: 0.5 },
  ];

  let dynamicRoutes: MetadataRoute.Sitemap = [];
  try {
    const [meditations, essays, prayers, praise] = await Promise.all([
      getPublished('HEAL_meditations', '-created', 'is_published = true'),
      getPublished('HEAL_essays', '-created', 'is_published = true'),
      getPublished('HEAL_prayers', '-created', 'is_published = true'),
      getPublished('HEAL_praise', '-created', 'is_published = true'),
    ]);

    dynamicRoutes = [
      ...meditations.map((m: any) => ({
        url: `${SITE}/meditate/${m.slug}`,
        lastModified: new Date(m.updated || m.created || now),
        changeFrequency: 'weekly' as const,
        priority: 0.7,
      })),
      ...essays.map((e: any) => ({
        url: `${SITE}/essays/${e.slug}`,
        lastModified: new Date(e.updated || e.published_at || e.created || now),
        changeFrequency: 'monthly' as const,
        priority: 0.6,
      })),
    ];
  } catch (e) {
    // PB unreachable — return static routes only
  }

  return [...staticRoutes, ...dynamicRoutes];
}
