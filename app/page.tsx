import Link from 'next/link';
import Image from 'next/image';
import { getDailyMeditation, getDailyQuote, getDailyScripture, getPublished } from '@/lib/pb';
import { formatDuration, dateLabel, seasonOf, themeHue } from '@/lib/utils';
import { DailyQuote } from '@/components/home/DailyQuote';
import { BreathWidget } from '@/components/home/BreathWidget';
import { ScriptureCard } from '@/components/home/ScriptureCard';
import { ThemeBadge } from '@/components/content/ThemeBadge';
import { ArrowRight, Headphones, BookOpen, Wind } from 'lucide-react';

export const revalidate = 3600; // ISR: refresh hourly so day changes at midnight

export default async function HomePage() {
  const [meditation, quote, breathwork, scripture] = await Promise.all([
    getDailyMeditation(),
    getDailyQuote(),
    getPublished('HEAL_breathwork', 'sort_order', 'is_published = true').then(r => r?.[0]),
    getDailyScripture(),
  ]);

  const today = new Date();
  const season = seasonOf(today);

  return (
    <div className="relative">
      {/* ── HERO: Today's meditation ───────────────────────────── */}
      <section className={`relative overflow-hidden bg-gradient-to-b ${themeHue(meditation?.theme)}`}>
        <div className="container-wide pt-16 pb-24 md:pt-24 md:pb-32">
          <div className="text-center max-w-2xl mx-auto mb-12 animate-fade-in">
            <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-3">
              {dateLabel(today)} · {season}
            </p>
            <h1 className="serif text-5xl md:text-6xl tracking-tight mb-4">
              A quiet practice
            </h1>
            <p className="serif italic text-xl text-ink/60">
              for the soul that hasn't quite caught up with the day
            </p>
          </div>

          {meditation ? (
            <article className="card-quiet max-w-3xl mx-auto overflow-hidden">
              {meditation.illustration_url && (
                <div className="relative aspect-[2/1] bg-sage-100">
                  <Image
                    src={meditation.illustration_url}
                    alt={meditation.title}
                    fill
                    className="object-cover"
                    priority
                    sizes="(max-width: 768px) 100vw, 768px"
                  />
                </div>
              )}
              <div className="p-8 md:p-12">
                <div className="flex items-center gap-2 mb-4">
                  <ThemeBadge theme={meditation.theme} />
                  <span className="text-xs text-ink/50">·</span>
                  <span className="text-xs text-ink/50">{formatDuration(meditation.duration_seconds)}</span>
                </div>
                <h2 className="serif text-3xl md:text-4xl mb-3">{meditation.title}</h2>
                {meditation.scripture_ref && (
                  <p className="serif italic text-ink/60 mb-6">— {meditation.scripture_ref}</p>
                )}
                {meditation.reflection && (
                  <p className="text-ink/75 leading-relaxed mb-8">{meditation.reflection}</p>
                )}
                <div className="flex flex-wrap gap-3">
                  <Link href={`/meditate/${meditation.slug}`} className="btn-primary">
                    <Headphones size={16} />
                    Begin the meditation
                    <ArrowRight size={16} />
                  </Link>
                  <Link href="/meditate" className="btn-ghost">
                    Browse library
                  </Link>
                </div>
              </div>
            </article>
          ) : (
            <div className="card-quiet max-w-3xl mx-auto p-12 text-center">
              <p className="serif italic text-ink/60">Today's meditation is still being prepared.</p>
              <p className="mt-2 text-sm text-ink/50">Come back in a moment, or browse the library.</p>
            </div>
          )}
        </div>
      </section>

      {/* ── THREE COLUMNS: Quote, Breath, Scripture ─────────────── */}
      <section className="container-wide py-20">
        <div className="grid md:grid-cols-3 gap-6">
          <DailyQuote quote={quote} />
          <BreathWidget practice={breathwork} />
          <ScriptureCard scripture={scripture} />
        </div>
      </section>

      {/* ── ENTRY POINTS ───────────────────────────────────────── */}
      <section className="container-wide pb-24">
        <div className="grid md:grid-cols-3 gap-4">
          <EntryCard href="/meditate" icon={<Headphones size={20} />} title="Meditations" body="A library of guided practices, organised by season and theme." />
          <EntryCard href="/breathe" icon={<Wind size={20} />} title="Breathwork" body="Slow your nervous system with simple breath patterns." />
          <EntryCard href="/scripture" icon={<BookOpen size={20} />} title="Scripture" body="Short passages for reflection, paired with a single question." />
        </div>
      </section>
    </div>
  );
}

function EntryCard({ href, icon, title, body }: { href: string; icon: React.ReactNode; title: string; body: string }) {
  return (
    <Link href={href} className="group card-quiet p-8 hover:scale-[1.01] transition-transform duration-500">
      <div className="text-sage-600 mb-4">{icon}</div>
      <h3 className="serif text-2xl mb-2 group-hover:text-sage-700 transition-colors">{title}</h3>
      <p className="text-ink/60 text-sm leading-relaxed">{body}</p>
      <div className="mt-6 flex items-center gap-1 text-sm text-ink/40 group-hover:text-ink group-hover:gap-2 transition-all">
        Open <ArrowRight size={14} />
      </div>
    </Link>
  );
}
