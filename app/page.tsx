import Link from 'next/link';
import Image from 'next/image';
import { getDailyMeditation, getDailyQuote, getDailyScripture, getPublished, pb } from '@/lib/pb';
import { formatDuration, dateLabel, seasonOf, themeHue } from '@/lib/utils';
import { DailyQuote } from '@/components/home/DailyQuote';
import { ScriptureCard } from '@/components/home/ScriptureCard';
import { QuickBreath } from '@/components/home/QuickBreath';
import { StreakCounter } from '@/components/home/StreakCounter';
import { TodayAtAGlance } from '@/components/home/TodayAtAGlance';
import { QuickActions } from '@/components/home/QuickActions';
import { FeaturedThisWeek, type FeaturedItem } from '@/components/home/FeaturedThisWeek';
import { ThemeBadge } from '@/components/content/ThemeBadge';
import { ShareButton } from '@/components/content/ShareButton';
import { ArrowRight, Headphones, Sparkles } from 'lucide-react';
import { headers } from 'next/headers';

export const revalidate = 3600;

export default async function HomePage() {
  const [meditation, quote, scripture, praiseSong, recentMeditations, recentEssays, recentPraise] = await Promise.all([
    getDailyMeditation(),
    getDailyQuote(),
    getDailyScripture(),
    pb.collection('HEAL_praise').getFirstListItem('is_published = true').catch(() => null),
    getPublished('HEAL_meditations', '-created', 'is_published = true', 4),
    getPublished('HEAL_essays', '-published_at', 'is_published = true', 2),
    getPublished('HEAL_praise', '-created', 'is_published = true', 2),
  ]);

  // Get breathwork for the quick breath card
  const breathwork = await getPublished('HEAL_breathwork', 'sort_order', 'is_published = true', 1).then(r => r?.[0]).catch(() => null);

  const today = new Date();
  const season = seasonOf(today);
  const h = await headers();
  const proto = h.get('x-forwarded-proto') || 'https';
  const host = h.get('host') || 'heal.app';
  const siteUrl = `${proto}://${host}`;

  // Build "This week" featured items
  const featured: FeaturedItem[] = [
    ...(recentEssays.slice(0, 1).map((e: any) => ({
      kind: 'meditation' as const,
      title: e.title,
      subtitle: e.subtitle,
      href: `/essays/${e.slug}`,
      excerpt: e.excerpt,
    }))),
    ...(recentMeditations.slice(0, 2).map((m: any) => ({
      kind: 'meditation' as const,
      title: m.title,
      subtitle: m.scripture_ref ? `— ${m.scripture_ref}` : undefined,
      href: `/meditate/${m.slug}`,
      excerpt: m.reflection,
      illustration: m.illustration_url || `/images/meditations/illustration-${m.slug}.png`,
      duration: formatDuration(m.duration_seconds),
    }))),
    ...(recentPraise.slice(0, 1).map((p: any) => ({
      kind: 'praise' as const,
      title: p.title,
      subtitle: p.subtitle,
      href: `/praise`,
      excerpt: (p.lyrics || '').split('\n').filter((l: string) => l && !l.startsWith('[')).slice(0, 2).join(' '),
    }))),
  ].filter(Boolean).slice(0, 4);

  return (
    <div className="relative">
      {/* ── HERO: Today's meditation ───────────────────────────── */}
      <section className={`relative overflow-hidden bg-gradient-to-b ${themeHue(meditation?.theme)}`}>
        {/* Decorative breath circle in the background */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full bg-sage-200/20 animate-breath" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[400px] h-[400px] rounded-full bg-sage-300/10 animate-breath" style={{ animationDelay: '1s' }} />
        </div>

        <div className="container-wide pt-12 pb-20 md:pt-20 md:pb-28 relative">
          <TodayAtAGlance />

          {meditation ? (
            <article className="card-quiet max-w-3xl mx-auto overflow-hidden">
              {(meditation.illustration_url || meditation.slug) && (
                <div className="relative aspect-[2/1] bg-sage-100">
                  <Image
                    src={meditation.illustration_url || `/images/meditations/illustration-${meditation.slug}.png`}
                    alt={meditation.title}
                    fill
                    className="object-cover"
                    priority
                    sizes="(max-width: 768px) 100vw, 768px"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent" />
                  <div className="absolute bottom-4 left-4 right-4 text-bone">
                    <p className="text-[10px] tracking-widest uppercase opacity-80 mb-1">Today's meditation</p>
                    <p className="serif text-2xl md:text-3xl">{meditation.title}</p>
                  </div>
                </div>
              )}
              <div className="p-8 md:p-10">
                <div className="flex items-center gap-2 mb-4">
                  <ThemeBadge theme={meditation.theme} />
                  <span className="text-xs text-ink/50">·</span>
                  <span className="text-xs text-ink/50">{formatDuration(meditation.duration_seconds)}</span>
                  <span className="text-xs text-ink/50">·</span>
                  <span className="text-xs text-ink/50">{dateLabel(today)}</span>
                </div>
                {meditation.scripture_ref && (
                  <p className="serif italic text-ink/60 mb-4">— {meditation.scripture_ref}</p>
                )}
                {meditation.reflection && (
                  <p className="text-ink/75 leading-relaxed mb-6 line-clamp-3">{meditation.reflection}</p>
                )}
                <div className="flex flex-wrap items-center gap-3">
                  <Link href={`/meditate/${meditation.slug}`} className="btn-primary">
                    <Headphones size={16} />
                    Begin
                    <ArrowRight size={16} />
                  </Link>
                  <Link href="/meditate" className="btn-ghost">
                    Library
                  </Link>
                  <span className="ml-auto">
                    <ShareButton
                      title={meditation.title}
                      url={`${siteUrl}/meditate/${meditation.slug}`}
                      text={meditation.reflection || meditation.title}
                    />
                  </span>
                </div>
              </div>
            </article>
          ) : (
            <div className="card-quiet max-w-3xl mx-auto p-12 text-center">
              <p className="serif italic text-ink/60">Today's meditation is still being prepared.</p>
            </div>
          )}
        </div>
      </section>

      {/* ── STREAK + QUICK ACTIONS ────────────────────────────── */}
      <section className="container-wide py-10">
        <div className="grid md:grid-cols-3 gap-4">
          <StreakCounter />
          <div className="md:col-span-2">
            <QuickActions />
          </div>
        </div>
      </section>

      {/* ── QUOTE + BREATH + SCRIPTURE ────────────────────────── */}
      <section className="container-wide py-12">
        <div className="grid md:grid-cols-3 gap-6">
          <DailyQuote quote={quote} />
          <QuickBreath />
          <ScriptureCard scripture={scripture} />
        </div>
      </section>

      {/* ── THIS WEEK FEATURED ────────────────────────────────── */}
      {featured.length > 0 && (
        <FeaturedThisWeek items={featured} />
      )}

      {/* ── PRAISE SONG OF THE DAY ────────────────────────────── */}
      {praiseSong && (
        <section className="container-wide py-12">
          <Link href="/praise" className="block group">
            <div className="max-w-4xl mx-auto card-quiet p-8 md:p-10 hover:scale-[1.005] transition-transform relative overflow-hidden">
              <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-100/20 rounded-full -translate-y-1/2 translate-x-1/2 pointer-events-none" />
              <div className="relative flex items-start gap-4">
                <div className="w-14 h-14 rounded-full bg-indigo-50 flex items-center justify-center shrink-0 group-hover:scale-110 transition-transform">
                  <Sparkles size={22} className="text-indigo-700" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-2">
                    <p className="text-xs tracking-widest uppercase text-ink/40">Praise</p>
                    {praiseSong.category && <p className="text-xs text-ink/40">· {praiseSong.category}</p>}
                  </div>
                  <h3 className="serif text-2xl md:text-3xl mb-1 group-hover:text-indigo-700 transition-colors">
                    {praiseSong.title}
                  </h3>
                  {praiseSong.subtitle && (
                    <p className="serif italic text-ink/60 mb-3">{praiseSong.subtitle}</p>
                  )}
                  <p className="text-ink/70 text-sm leading-relaxed line-clamp-2 italic">
                    {(praiseSong.lyrics || '').split('\n').filter((l: string) => l && !l.startsWith('[')).slice(0, 2).join(' ')}
                  </p>
                  <div className="mt-4 flex items-center gap-1 text-sm text-ink/40 group-hover:text-ink group-hover:gap-2 transition-all">
                    Read & sing <ArrowRight size={14} />
                  </div>
                </div>
              </div>
            </div>
          </Link>
        </section>
      )}

      {/* ── FOOTER NOTE: THE PRACTICE ─────────────────────────── */}
      <section className="container-wide py-20">
        <div className="max-w-2xl mx-auto text-center">
          <p className="serif italic text-2xl md:text-3xl text-ink/70 leading-relaxed">
            "Be still, and know that I am God."
          </p>
          <p className="text-xs tracking-widest uppercase text-ink/40 mt-4">— Psalm 46:10</p>
        </div>
      </section>
    </div>
  );
}
