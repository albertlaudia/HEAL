'use client';

import { useState, useEffect, useRef } from 'react';
import { Headphones } from 'lucide-react';

const MINDFUL_WORDS = [
  'Listening is coming…',
  'Drawing the words near…',
  'Gathering the voice…',
  'A breath, then we begin…',
  'Pouring the silence in…',
  'The room is preparing…',
  'Settling into the practice…',
  'One moment of stillness…',
];

const SCRIPTURE_HINTS = [
  { ref: 'Psalm 46:10', text: 'Be still, and know that I am God.' },
  { ref: 'Isaiah 30:15', text: 'In quietness and in trust shall be your strength.' },
  { ref: 'Psalm 131:2', text: 'I have calmed and quieted my soul, like a weaned child with its mother.' },
];

export function AudioPreparing({ progress = 0, visible = false, kind = 'meditation' }: { progress?: number; visible?: boolean; kind?: 'meditation' | 'praise' | 'breath' }) {
  const [wordIdx, setWordIdx] = useState(0);
  const [scriptureIdx] = useState(() => Math.floor(Math.random() * SCRIPTURE_HINTS.length));
  const prevVisible = useRef(visible);

  // Reset to first word each time we become visible
  useEffect(() => {
    if (visible && !prevVisible.current) {
      setWordIdx(0);
    }
    prevVisible.current = visible;
  }, [visible]);

  useEffect(() => {
    if (!visible) return;
    const i = setInterval(() => {
      setWordIdx(w => (w + 1) % MINDFUL_WORDS.length);
    }, 2400);
    return () => clearInterval(i);
  }, [visible]);

  if (!visible) return null;

  const word = MINDFUL_WORDS[wordIdx];
  const scripture = SCRIPTURE_HINTS[scriptureIdx];
  const Icon = kind === 'praise' ? Headphones : Headphones;
  const label = kind === 'praise' ? 'Music is preparing' : 'The meditation is preparing';

  return (
    <div className="animate-fade-in space-y-3 py-2" role="status" aria-live="polite">
      <div className="flex items-center gap-2 text-xs text-ink/50">
        <Icon size={12} className="text-sage-600" />
        <span className="tracking-wide">{label}</span>
      </div>

      <p
        key={wordIdx}
        className="serif italic text-lg text-ink/70 animate-fade-in"
        style={{ animationDuration: '600ms' }}
      >
        {word}
      </p>

      {/* Progress */}
      <div className="space-y-1.5">
        <div className="h-0.5 bg-ink/8 rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-sage-400 to-sage-600 transition-all duration-300"
            style={{ width: `${Math.min(100, Math.max(0, progress))}%` }}
          />
        </div>
        {progress > 5 && (
          <p className="text-[10px] tabular-nums text-ink/40">
            {Math.round(progress)}%
          </p>
        )}
      </div>

      {/* Soft scripture reminder */}
      <p className="serif italic text-xs text-ink/35 leading-relaxed max-w-sm">
        "{scripture.text}" <span className="text-ink/25 not-italic">— {scripture.ref}</span>
      </p>
    </div>
  );
}
