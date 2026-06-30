import type { MetadataRoute } from 'next';
import { getPublished } from '@/lib/pb';

const SITE = (process.env.NEXT_PUBLIC_SITE_URL || 'https://heal.positiveness.club').replace(/\/$/, '');

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${SITE}/`,          changeFrequency: 'daily',  priority: 1.0 },
    { url: `${SITE}/meditate`,  changeFrequency: 'daily',  priority: 0.9 },
    { url: `${SITE}/breathe`,   changeFrequency: 'monthly', priority: 0.8 },
    { url: `${SITE}/scripture`, changeFrequency: 'weekly', priority: 0.7 },
    { url: `${SITE}/prayers`,   changeFrequency: 'weekly', priority: 0.7 },
    { url: `${SITE}/praise`,    changeFrequency: 'weekly', priority: 0.8 },
    { url: `${SITE}/essays`,    changeFrequency: 'weekly', priority: 0.6 },
    { url: `${SITE}/programs`,  changeFrequency: 'weekly', priority: 0.7 },
    { url: `${SITE}/now`,       changeFrequency: 'yearly',  priority: 0.5 },
    { url: `${SITE}/about`,     changeFrequency: 'yearly',  priority: 0.4 },
    { url: `${SITE}/contact`,   changeFrequency: 'yearly',  priority: 0.3 },
    { url: `${SITE}/privacy`,   changeFrequency: 'yearly',  priority: 0.2 },
    { url: `${SITE}/terms`,     changeFrequency: 'yearly',  priority: 0.2 },
    { url: `${SITE}/guidelines`,changeFrequency: 'yearly',  priority: 0.2 },
  ];

  // Dynamic: every published meditation
  let meditationRoutes: MetadataRoute.Sitemap = [];
  try {
    const meditations = await getPublished('HEAL_meditations', '-published_at', 'is_published = true');
    meditationRoutes = (meditations || []).map((m: any) => ({
      url: `${SITE}/meditate/${m.slug}`,
      lastModified: m.updated || m.published_at || undefined,
      changeFrequency: 'monthly',
      priority: 0.6,
    }));
  } catch (err) {
    // PB unreachable — sitemap still works without dynamic routes
    console.warn('sitemap: PB fetch failed, returning static only', err);
  }

  // Dynamic: every published essay
  let essayRoutes: MetadataRoute.Sitemap = [];
  try {
    const essays = await getPublished('HEAL_essays', '-published_at', 'is_published = true');
    essayRoutes = (essays || []).map((e: any) => ({
      url: `${SITE}/essays/${e.slug}`,
      lastModified: e.updated || e.published_at || undefined,
      changeFrequency: 'monthly',
      priority: 0.5,
    }));
  } catch {}

  // Dynamic: every program
  let programRoutes: MetadataRoute.Sitemap = [];
  try {
    const programs = await getPublished('HEAL_programs', '-published_at', 'is_published = true');
    programRoutes = (programs || []).map((p: any) => ({
      url: `${SITE}/programs/${p.slug}`,
      lastModified: p.updated || p.published_at || undefined,
      changeFrequency: 'weekly',
      priority: 0.6,
    }));
  } catch {}

  return [...staticRoutes, ...meditationRoutes, ...essayRoutes, ...programRoutes];
}