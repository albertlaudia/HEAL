import Link from 'next/link';
import Image from 'next/image';
import { getDailyMeditation, getDailyQuote, getDailyScripture, getDailyPraise, getPublished, getCalendarCoord } from '@/lib/pb';
import { formatDuration, dateLabel, seasonOf, themeHue } from '@/lib/utils';
import { QuickBreath } from '@/components/home/QuickBreath';
import { TodayAtAGlance } from '@/components/home/TodayAtAGlance';
import { YearCycleBadge } from '@/components/home/YearCycleBadge';
import { ContinueProgram } from "@/components/home/ContinueProgram";
import { HealPrinciples } from "@/components/home/HealPrinciples";
import { WelcomeOverlay, WelcomePill } from "@/components/home/WelcomeOverlay";
import { ArrowRight } from 'lucide-react';
import { headers } from 'next/headers';

export const revalidate = 3600;

export async function generateMetadata() {
  const coord = getCalendarCoord();
  return {
    title: `HEAL — A quiet practice, Day ${coord.dayOfYear}`,
    description: `A daily Christian mindfulness practice. Day ${coord.dayOfYear} of the cycle.`,
  };
}

export default async function HomePage() {
  const coord = getCalendarCoord();

  // Resolve every data call independently. If PB is unreachable or a
  // collection is missing, we still render the page with empty/placeholder
  // data rather than letting Promise.all reject and break the whole page.
  const safeGet = <T,>(p: Promise<T>, fallback: T): Promise<T> =>
    p.catch((e) => { if (typeof console !== 'undefined') console.warn('home data fetch failed:', e?.message); return fallback; });

  const [meditation, quote, scripture, praiseSong, recentMeditations, recentEssays, recentPraise] = await Promise.all([
    safeGet(getDailyMeditation(coord), null as any),
    safeGet(getDailyQuote(coord), null as any),
    safeGet(getDailyScripture(coord), null as any),
    safeGet(getDailyPraise(coord), null as any),
    safeGet(getPublished('HEAL_meditations', '-id', 'is_published = true', 6), [] as any[]),
    safeGet(getPublished('HEAL_essays', '-published_at', 'is_published = true', 3), [] as any[]),
    safeGet(getPublished('HEAL_praise', '-id', 'is_published = true', 3), [] as any[]),
  ]);

  const today = new Date();
  const season = seasonOf(today);
  const h = await headers();
  const proto = h.get('x-forwarded-proto') || 'https';
  const host = h.get('host') || 'heal.app';
  const siteUrl = `${proto}://${host}`;

  // A single soft "from the practice" rail — recent meditations, essays, and praise.
  const recentItems: { kind: 'meditation' | 'essay' | 'praise'; title: string; subtitle?: string; href: string; excerpt?: string; illustration?: string }[] = [
    ...recentMeditations.slice(0, 3).map((m: any) => ({
      kind: 'meditation' as const,
      title: m.title,
      subtitle: m.scripture_ref ? `— ${m.scripture_ref}` : undefined,
      href: `/meditate/${m.slug}`,
      excerpt: m.reflection,
      illustration: m.illustration_url || `/images/meditations/illustration-${m.slug}.png`,
    })),
    ...recentEssays.slice(0, 1).map((e: any) => ({
      kind: 'essay' as const,
      title: e.title,
      subtitle: e.subtitle,
      href: `/essays/${e.slug}`,
      excerpt: e.excerpt,
    })),
    ...recentPraise.slice(0, 1).map((p: any) => ({
      kind: 'praise' as const,
      title: p.title,
      subtitle: p.subtitle,
      href: `/praise`,
      excerpt: p.description,
    })),
  ];

  return (
    <>
    <WelcomeOverlay />
    <WelcomePill />
    <div className="relative">
      {/* ── OPENING — no labels, no system-y markers ─────────────── */}
      <section className="relative">
        {/* Soft background tint — chosen by meditation theme, very low intensity */}
        <div className={`absolute inset-0 bg-gradient-to-b ${themeHue(meditation?.theme)} pointer-events-none`} />

        <div className="container-wide pt-14 pb-16 md:pt-24 md:pb-24 relative">
          {/* Whisper-soft day marker, top-right corner of the page instead of centered */}
          <div className="flex justify-end mb-10 md:mb-14 animate-fade-in">
            <YearCycleBadge
              yearCycle={coord.yearCycle}
              dayOfYear={coord.dayOfYear}
              label={coord.label}
              compact
            />
          </div>

          <TodayAtAGlance />

          {/* Today's meditation — the front-and-center piece. Less chrome, more invitation. */}
          {meditation && (
            <article className="max-w-2xl mx-auto mt-12 md:mt-16 animate-fade-in">
              <p className="serif italic text-ink/55 mb-3 text-center text-sm">today's practice</p>
              <Link
                href={`/meditate/${meditation.slug}`}
                className="block group"
              >
                <h2 className="serif text-4xl md:text-5xl lg:text-6xl text-center mb-3 leading-tight group-hover:text-sage-800 transition-colors">
                  {meditation.title}
                </h2>
                {meditation.scripture_ref && (
                  <p className="serif italic text-ink/55 text-center mb-6">— {meditation.scripture_ref}</p>
                )}
                {meditation.reflection && (
                  <p className="serif text-lg md:text-xl text-ink/70 text-center leading-relaxed max-w-xl mx-auto mb-8">
                    {meditation.reflection.split('. ').slice(0, 2).join('. ')}.
                  </p>
                )}
                <div className="flex items-center justify-center gap-2 text-sm text-ink/45 group-hover:text-ink group-hover:gap-3 transition-all">
                  <span>{formatDuration(meditation.duration_seconds)}</span>
                  <span className="w-1 h-1 rounded-full bg-ink/30" />
                  <span className="serif italic">Press play. Begin.</span>
                  <ArrowRight size={14} className="opacity-0 group-hover:opacity-100 transition-opacity" />
                </div>
              </Link>
            </article>
          )}
        </div>
      </section>

      {/* ── H.E.A.L. — the framework. The whole point of being here. */}
      <HealPrinciples />

      {/* ── A QUICK RESET — 90s on-ramp ─────────────────────────── */}
      <section className="container-wide py-12 md:py-16">
        <div className="max-w-2xl mx-auto text-center">
          <p className="serif italic text-ink/65 text-lg mb-3">If you have 90 seconds.</p>
          <p className="text-ink/55 mb-6">A full H.E.A.L. round. Pause, breathe, read one line, breathe again. That's the whole thing.</p>
          <Link
            href="/now"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-ink text-bone hover:bg-ink/85 hover:scale-[1.02] transition-all"
          >
            Begin the 90-second ritual
            <ArrowRight size={14} />
          </Link>
        </div>
      </section>

      {/* ── BREATH — a quiet place to breathe ───────────────────── */}
      <section className="container-wide pb-16">
        <div className="max-w-md mx-auto">
          <QuickBreath />
        </div>
      </section>

      {/* ── A WORD + A VERSE — quiet pair ────────────────────────── */}
      <section className="container-wide py-16 border-t border-ink/8">
        <div className="grid md:grid-cols-2 gap-12 md:gap-16 max-w-4xl mx-auto">
          {quote && (
            <div>
              <p className="serif italic text-ink/45 text-xs tracking-[0.3em] uppercase mb-4">a word</p>
              <blockquote className="serif text-2xl md:text-3xl leading-snug text-ink/85 mb-4">
                "{quote.text}"
              </blockquote>
              {quote.attribution && (
                <p className="text-sm text-ink/45 serif italic">— {quote.attribution}</p>
              )}
            </div>
          )}
          {scripture && (
            <div>
              <p className="serif italic text-ink/45 text-xs tracking-[0.3em] uppercase mb-4">a verse</p>
              <p className="serif text-2xl md:text-3xl leading-snug text-ink/85 mb-4">
                "{scripture.text}"
              </p>
              <p className="text-sm text-ink/45 serif italic">— {scripture.reference}</p>
              {scripture.reflection_prompt && (
                <p className="mt-4 text-sm text-ink/55 leading-relaxed">
                  <span className="serif italic">Carry this:</span> {scripture.reflection_prompt}
                </p>
              )}
            </div>
          )}
        </div>
      </section>

      {/* ── FROM THE PRACTICE — recent meditations, essays, praise ──── */}
      {recentItems.length > 0 && (
        <section className="container-wide py-16">
          <div className="flex items-end justify-between mb-10 max-w-5xl mx-auto">
            <div>
              <p className="serif italic text-ink/45 text-xs tracking-[0.3em] uppercase mb-3">lately</p>
              <h2 className="serif text-3xl md:text-4xl">From the practice</h2>
            </div>
          </div>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl mx-auto">
            {recentItems.slice(0, 6).map((item, i) => (
              <Link
                key={i}
                href={item.href}
                className="group flex flex-col"
              >
                {item.illustration && (
                  <div className="relative aspect-[3/2] rounded-xl overflow-hidden mb-4 bg-sage-50">
                    <Image
                      src={item.illustration}
                      alt={item.title}
                      fill
                      className="object-cover group-hover:scale-[1.02] transition-transform duration-700"
                      sizes="(max-width: 640px) 100vw, 33vw"
                    />
                  </div>
                )}
                <p className="serif italic text-ink/45 text-xs mb-1">{item.kind}</p>
                <h3 className="serif text-lg md:text-xl leading-tight mb-1 group-hover:text-sage-800 transition-colors">
                  {item.title}
                </h3>
                {item.subtitle && (
                  <p className="serif italic text-ink/55 text-sm mb-2">{item.subtitle}</p>
                )}
                {item.excerpt && (
                  <p className="text-ink/65 text-sm leading-relaxed line-clamp-3">
                    {item.excerpt}
                  </p>
                )}
              </Link>
            ))}
          </div>
        </section>
      )}

      {/* ── CONTINUE A PROGRAM — gentle nudge if mid-program ─────── */}
      <ContinueProgram />

      {/* ── CLOSING — a word for the road ───────────────────────── */}
      <section className="container-wide py-20 md:py-28">
        <div className="max-w-2xl mx-auto text-center">
          <p className="serif italic text-2xl md:text-3xl text-ink/70 leading-relaxed">
            "Be still, and know that I am God."
          </p>
          <p className="serif italic text-sm text-ink/45 mt-4">— Psalm 46:10</p>
        </div>
      </section>
    </div>
    </>
  );
}