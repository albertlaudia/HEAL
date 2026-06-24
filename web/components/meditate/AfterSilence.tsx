'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { BookMarked, BookOpen, Sparkles, X, Check, ChevronRight } from 'lucide-react';

const PROMPTS = [
  'What stirred in you?',
  'What word or image stayed with you?',
  'What did you hear in the silence?',
  'Where did you sense God, even faintly?',
  'What do you want to carry from this moment?',
];

const VERSES = [
  { ref: 'Psalm 46:10', text: 'Be still, and know that I am God.' },
  { ref: 'Isaiah 30:15', text: 'In quietness and in trust shall be your strength.' },
  { ref: 'Habakkuk 2:20', text: 'The Lord is in his holy temple; let all the earth be silent before him.' },
  { ref: 'Psalm 131:2', text: 'I have calmed and quieted my soul, like a weaned child with its mother.' },
  { ref: '1 Kings 19:12', text: '...and after the earthquake a fire... and after the fire a still small voice.' },
];

export function AfterSilence({
  meditationTitle,
  scriptureRef,
  onClose,
}: {
  meditationTitle: string;
  scriptureRef?: string;
  onClose: () => void;
}) {
  const [phase, setPhase] = useState<'silence' | 'capture'>('silence');
  const [silenceElapsed, setSilenceElapsed] = useState(0);
  const silenceDuration = 15; // 15 seconds of pure silence
  const [promptIdx] = useState(() => Math.floor(Math.random() * PROMPTS.length));
  const [verseIdx] = useState(() => Math.floor(Math.random() * VERSES.length));
  const [journalText, setJournalText] = useState('');
  const [saved, setSaved] = useState(false);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    timerRef.current = setInterval(() => {
      setSilenceElapsed(s => {
        if (s + 0.1 >= silenceDuration) {
          if (timerRef.current) clearInterval(timerRef.current);
          return silenceDuration;
        }
        return s + 0.1;
      });
    }, 100);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, []);

  const handleSave = () => {
    // Save to local journal - the actual save happens in JournalInline
    if (journalText.trim()) {
      const payload = {
        text: journalText.trim(),
        refKind: 'meditation',
        refSlug: meditationTitle,
        refTitle: meditationTitle,
        kind: 'reflection',
        createdAt: new Date().toISOString(),
      };
      try {
        const existing = JSON.parse(localStorage.getItem('heal:pending-journal') || '[]');
        existing.push(payload);
        localStorage.setItem('heal:pending-journal', JSON.stringify(existing));
        setSaved(true);
      } catch {
        // localStorage unavailable
        setSaved(true);
      }
    }
  };

  const silencePct = Math.min(100, (silenceElapsed / silenceDuration) * 100);

  return (
    <div className="fixed inset-0 z-50 bg-bone/97 backdrop-blur-lg flex items-center justify-center p-6 animate-fade-in overflow-y-auto">
      <div className="max-w-xl w-full text-center relative my-auto">
        <button
          onClick={onClose}
          className="absolute -top-2 -right-2 md:top-0 md:right-0 p-2 text-ink/40 hover:text-ink/70"
          aria-label="Close"
        >
          <X size={18} />
        </button>

        {phase === 'silence' ? (
          <div className="space-y-12 py-12">
            <div className="space-y-4">
              <p className="text-xs tracking-[0.4em] uppercase text-sage-700">L · Listen</p>
              <h2 className="serif text-4xl md:text-5xl text-ink/80 font-light">A moment of stillness</h2>
              <p className="serif italic text-ink/50 max-w-md mx-auto">
                The meditation has ended. There is no need to do anything.
                Just let the silence hold you for a moment.
              </p>
            </div>

            {/* Silence breathing circle */}
            <div className="relative w-56 h-56 mx-auto">
              <div
                className="absolute inset-0 rounded-full bg-gradient-to-br from-sage-100 to-sage-200 transition-transform ease-in-out"
                style={{
                  transform: `scale(${silenceElapsed < silenceDuration / 2 ? 1.1 : 0.95})`,
                  transitionDuration: '4s',
                  opacity: 0.4,
                }}
              />
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-center">
                  <p className="serif text-3xl text-ink/70 font-light tabular-nums">
                    {Math.max(0, Math.ceil(silenceDuration - silenceElapsed))}
                  </p>
                  <p className="text-[10px] tracking-widest uppercase text-ink/40 mt-1">seconds</p>
                </div>
              </div>
            </div>

            {/* Progress bar */}
            <div className="max-w-xs mx-auto">
              <div className="h-0.5 bg-ink/10 rounded-full overflow-hidden">
                <div
                  className="h-full bg-sage-500 transition-all duration-100"
                  style={{ width: `${silencePct}%` }}
                />
              </div>
              <button
                onClick={() => setPhase('capture')}
                className="mt-4 text-xs text-ink/40 hover:text-ink/70 underline underline-offset-4"
              >
                Skip to reflection
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-10 py-8 animate-fade-in">
            <div className="space-y-3">
              <p className="text-xs tracking-[0.4em] uppercase text-sage-700">L · Listen</p>
              <h2 className="serif text-3xl md:text-4xl text-ink/80 font-light">
                {PROMPTS[promptIdx]}
              </h2>
            </div>

            {/* A small verse */}
            <div className="card-quiet p-6 max-w-md mx-auto text-left">
              <p className="serif italic text-base text-ink/75 leading-relaxed">
                "{VERSES[verseIdx].text}"
              </p>
              <p className="text-[10px] tracking-widest uppercase text-ink/40 mt-2">
                — {VERSES[verseIdx].ref}
              </p>
            </div>

            {/* Journal capture */}
            {saved ? (
              <div className="card-quiet p-6 max-w-md mx-auto flex items-center gap-3">
                <Check size={18} className="text-sage-600" />
                <p className="text-sm text-ink/70 serif">
                  Saved to your journal.
                </p>
              </div>
            ) : (
              <div className="card-quiet p-5 max-w-md mx-auto">
                <textarea
                  rows={3}
                  placeholder="Write a sentence, a word, a feeling..."
                  value={journalText}
                  onChange={e => setJournalText(e.target.value)}
                  className="w-full bg-transparent resize-none focus:outline-none serif text-base"
                  autoFocus
                />
                <div className="flex justify-end gap-2 mt-2">
                  <button
                    onClick={() => setJournalText('')}
                    className="text-xs text-ink/40 hover:text-ink/60 px-3 py-1.5"
                  >
                    Clear
                  </button>
                  <button
                    onClick={handleSave}
                    disabled={!journalText.trim()}
                    className="btn-pill text-xs disabled:opacity-30"
                  >
                    <BookMarked size={12} />
                    Save
                  </button>
                </div>
              </div>
            )}

            <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
              <Link
                href="/journal"
                className="btn-ghost text-sm"
                onClick={onClose}
              >
                <BookOpen size={14} />
                Open journal
                <ChevronRight size={14} />
              </Link>
              <Link
                href="/meditate"
                className="btn-ghost text-sm"
                onClick={onClose}
              >
                <Sparkles size={14} />
                Another meditation
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
