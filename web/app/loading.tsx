'use client';

import { useState, useEffect } from 'react';

const MINDFUL_WORDS = [
  'Settling in…',
  'A breath…',
  'Gathering the day…',
  'Stillness is here…',
  'One moment…',
  'Almost ready…',
  'Softly, slowly…',
  'The room is quiet…',
];

const SCRIPTURE_HINTS = [
  { ref: 'Psalm 46:10', text: 'Be still, and know that I am God.' },
  { ref: 'Isaiah 30:15', text: 'In quietness and in trust shall be your strength.' },
  { ref: 'Habakkuk 2:20', text: 'The Lord is in his holy temple; let all the earth be silent before him.' },
  { ref: 'Psalm 131:2', text: 'I have calmed and quieted my soul, like a weaned child with its mother.' },
];

export default function Loading() {
  const [wordIdx, setWordIdx] = useState(0);
  const [scriptureIdx] = useState(() => Math.floor(Math.random() * SCRIPTURE_HINTS.length));

  useEffect(() => {
    const i = setInterval(() => {
      setWordIdx(w => (w + 1) % MINDFUL_WORDS.length);
    }, 2400);
    return () => clearInterval(i);
  }, []);

  const word = MINDFUL_WORDS[wordIdx];
  const scripture = SCRIPTURE_HINTS[scriptureIdx];

  return (
    <div className="min-h-[60vh] flex items-center justify-center px-6 py-20">
      <div className="text-center max-w-md">
        {/* Breathing circle */}
        <div className="relative w-32 h-32 mx-auto mb-12">
          <div
            className="absolute inset-0 rounded-full bg-gradient-to-br from-sage-200 to-sage-400 animate-breath"
            style={{ animationDuration: '6s', opacity: 0.25 }}
          />
          <div
            className="absolute inset-4 rounded-full bg-gradient-to-br from-sage-300 to-sage-500 animate-breath"
            style={{ animationDuration: '6s', animationDelay: '0.5s', opacity: 0.4 }}
          />
          <div
            className="absolute inset-8 rounded-full bg-gradient-to-br from-sage-400 to-sage-600 animate-breath flex items-center justify-center"
            style={{ animationDuration: '6s', animationDelay: '1s' }}
          />
          <span className="relative text-bone serif text-sm font-light tracking-wider">
            HEAL
          </span>
        </div>

        {/* Mindful word — fades between values */}
        <p
          key={wordIdx}
          className="serif italic text-2xl text-ink/60 mb-8 animate-fade-in"
          style={{ animationDuration: '600ms' }}
        >
          {word}
        </p>

        {/* Three small dots, each delayed */}
        <div className="inline-flex items-center gap-2 mb-10">
          <span className="w-1.5 h-1.5 bg-sage-500 rounded-full animate-pulse" style={{ animationDuration: '1.4s' }} />
          <span className="w-1.5 h-1.5 bg-sage-500 rounded-full animate-pulse" style={{ animationDuration: '1.4s', animationDelay: '0.3s' }} />
          <span className="w-1.5 h-1.5 bg-sage-500 rounded-full animate-pulse" style={{ animationDuration: '1.4s', animationDelay: '0.6s' }} />
        </div>

        {/* Scripture */}
        <p className="serif italic text-ink/50 leading-relaxed max-w-xs mx-auto">
          "{scripture.text}"
        </p>
        <p className="text-[10px] tracking-widest uppercase text-ink/40 mt-2">
          — {scripture.ref}
        </p>
      </div>
    </div>
  );
}
