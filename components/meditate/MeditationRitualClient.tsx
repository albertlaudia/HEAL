'use client';

import { useState, useEffect, useRef } from 'react';
import Image from 'next/image';
import { ThemeBadge } from '@/components/content/ThemeBadge';
import { MeditationPlayer } from '@/components/meditate/MeditationPlayer';
import { SaveButton } from '@/components/content/SaveButton';
import { ShareButton } from '@/components/content/ShareButton';
import { JournalInline } from '@/components/content/JournalInline';
import { BeginRitual } from '@/components/meditate/BeginRitual';
import { AfterSilence } from '@/components/meditate/AfterSilence';
import { formatDuration } from '@/lib/utils';
import { ArrowLeft, ArrowRight, Play, Heart } from 'lucide-react';
import Link from 'next/link';

type Track = { title: string; audioUrl: string; duration?: number; illustrationUrl?: string };

export function MeditationRitualClient({ m, shareUrl, prev, next }: { m: any; shareUrl: string; prev: any; next: any }) {
  const [ritualOpen, setRitualOpen] = useState(false);
  const [silenceOpen, setSilenceOpen] = useState(false);
  const [audioStarted, setAudioStarted] = useState(false);
  const [showBeginCTA, setShowBeginCTA] = useState(true);
  const afterSilenceTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const audioUrl = m.audio_url || (m.slug ? `/audio/meditations/audio-${m.slug}.mp3` : undefined);
  const hasAudio = !!audioUrl;

  // Listen for meditation ended event — open silence moment
  useEffect(() => {
    const onEnded = (e: Event) => {
      const t = (e as CustomEvent).detail;
      if (t?.title === m.title) {
        // Small delay so the player can settle
        afterSilenceTimer.current = setTimeout(() => setSilenceOpen(true), 400);
      }
    };
    window.addEventListener('heal:meditation-ended', onEnded as EventListener);
    return () => {
      window.removeEventListener('heal:meditation-ended', onEnded as EventListener);
      if (afterSilenceTimer.current) clearTimeout(afterSilenceTimer.current);
    };
  }, [m.title]);

  const handleBegin = () => {
    if (!hasAudio) {
      // No audio — just start the meditation view
      setShowBeginCTA(false);
      return;
    }
    setRitualOpen(true);
  };

  const handleRitualComplete = () => {
    setRitualOpen(false);
    setAudioStarted(true);
    setShowBeginCTA(false);
    // Trigger the player to start
    window.dispatchEvent(new CustomEvent('heal:start-meditation', { detail: { slug: m.slug } }));
  };

  const handleRitualSkip = () => {
    setRitualOpen(false);
    setAudioStarted(true);
    setShowBeginCTA(false);
    window.dispatchEvent(new CustomEvent('heal:start-meditation', { detail: { slug: m.slug } }));
  };

  return (
    <article className="container-wide py-12">
      <Link href="/meditate" className="inline-flex items-center gap-2 text-sm text-ink/60 hover:text-ink mb-8">
        <ArrowLeft size={14} /> Library
      </Link>

      <header className="max-w-2xl mx-auto text-center mb-12">
        <div className="flex items-center justify-center gap-2 mb-4">
          <ThemeBadge theme={m.theme} />
          {m.season && <span className="text-xs text-ink/50 uppercase tracking-wider">· {m.season}</span>}
          {m.duration_seconds ? <span className="text-xs text-ink/50">· {formatDuration(m.duration_seconds)}</span> : null}
        </div>
        <h1 className="serif text-4xl md:text-5xl mb-4">{m.title}</h1>
        {m.scripture_ref && (
          <p className="serif italic text-ink/60">— {m.scripture_ref}</p>
        )}
      </header>

      {(m.illustration_url || m.slug) && (
        <div className="relative max-w-3xl mx-auto aspect-[3/2] rounded-2xl overflow-hidden mb-12 bg-sage-100">
          <Image
            src={m.illustration_url || `/images/meditations/illustration-${m.slug}.png`}
            alt={m.title}
            fill
            className="object-cover"
            priority
          />
          {showBeginCTA && hasAudio && !audioStarted && (
            <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-black/20 to-transparent flex items-end justify-center pb-8">
              <button
                onClick={handleBegin}
                className="group flex flex-col items-center gap-2 px-8 py-4 bg-bone rounded-full hover:scale-105 active:scale-95 transition-all shadow-2xl"
              >
                <span className="text-xs tracking-[0.3em] uppercase text-ink/50">A small ritual first</span>
                <span className="flex items-center gap-2 text-ink">
                  <Play size={16} className="fill-ink" />
                  <span className="serif text-lg">Begin with H.E.A.L.</span>
                </span>
              </button>
            </div>
          )}
        </div>
      )}

      {/* If user has not started the audio, show a "Begin" CTA above the player */}
      {showBeginCTA && hasAudio && !audioStarted && !m.illustration_url && !m.slug && (
        <div className="max-w-2xl mx-auto mb-8 text-center">
          <button onClick={handleBegin} className="btn-primary">
            <Play size={16} className="fill-current" />
            Begin with H.E.A.L.
          </button>
        </div>
      )}

      {/* The player — visible always, but is dimmed until ritual completes */}
      <div className={showBeginCTA && hasAudio && !audioStarted ? 'opacity-50 pointer-events-none' : 'opacity-100 transition-opacity duration-700'}>
        <MeditationPlayer
          title={m.title}
          audioUrl={m.audio_url}
          fallbackSlug={m.slug}
          duration={m.duration_seconds}
          body={m.body}
          prayer={m.prayer}
          scriptureRef={m.scripture_ref}
          scriptureText={m.scripture_text}
          reflection={m.reflection}
          illustrationUrl={m.illustration_url}
        />
      </div>

      {/* After-silence moment */}
      {silenceOpen && (
        <AfterSilence
          meditationTitle={m.title}
          scriptureRef={m.scripture_ref}
          onClose={() => setSilenceOpen(false)}
        />
      )}

      {/* Ritual modal */}
      {ritualOpen && (
        <BeginRitual
          scriptureRef={m.scripture_ref}
          scriptureText={m.scripture_text}
          onComplete={handleRitualComplete}
          onSkip={handleRitualSkip}
        />
      )}

      {m.scripture_text && (
        <section className="max-w-2xl mx-auto mt-16 p-8 md:p-12 bg-paper border border-ink/5 rounded-2xl">
          <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">Scripture</p>
          <blockquote className="serif text-2xl leading-relaxed text-ink/85">
            "{m.scripture_text}"
          </blockquote>
          <p className="mt-4 serif italic text-ink/60">— {m.scripture_ref}</p>
        </section>
      )}

      {m.reflection && (
        <section className="max-w-2xl mx-auto mt-12">
          <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">For reflection</p>
          <p className="serif text-xl leading-relaxed text-ink/80 italic">{m.reflection}</p>
        </section>
      )}

      <div className="max-w-2xl mx-auto mt-12 flex flex-wrap gap-3">
        <SaveButton
          kind="meditation"
          slug={m.slug}
          title={m.title}
          subtitle={m.scripture_ref}
          illustration_url={m.illustration_url}
        />
        <ShareButton
          title={m.title}
          text={`"${m.reflection || m.title}" — HEAL`}
          url={shareUrl}
        />
      </div>

      <section className="max-w-2xl mx-auto mt-12">
        <p className="text-xs tracking-widest uppercase text-ink/40 mb-4">Your journal</p>
        <JournalInline refKind="meditation" refSlug={m.slug} refTitle={m.title} />
      </section>

      <nav className="max-w-2xl mx-auto mt-16 pt-12 border-t border-ink/5 flex justify-between text-sm">
        {prev ? (
          <Link href={`/meditate/${prev.slug}`} className="text-ink/60 hover:text-ink flex items-center gap-2">
            <ArrowLeft size={14} /> {prev.title}
          </Link>
        ) : <span />}
        {next ? (
          <Link href={`/meditate/${next.slug}`} className="text-ink/60 hover:text-ink flex items-center gap-2">
            {next.title} <ArrowRight size={14} />
          </Link>
        ) : <span />}
      </nav>
    </article>
  );
}
