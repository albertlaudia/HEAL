'use client';

import Link from 'next/link';
import { ArrowRight, Headphones, BookOpen, Wind, Music, BookHeart } from 'lucide-react';

type Action = {
  href: string;
  icon: React.ReactNode;
  title: string;
  body: string;
  accent: string;
};

const actions: Action[] = [
  {
    href: '/meditate',
    icon: <Headphones size={20} />,
    title: 'Meditate',
    body: "Today's guided practice, 4-8 minutes.",
    accent: 'bg-sage-100 text-sage-700',
  },
  {
    href: '/breathe',
    icon: <Wind size={20} />,
    title: 'Breathe',
    body: 'A 1-3 minute breath ritual, any time.',
    accent: 'bg-cyan-100 text-cyan-700',
  },
  {
    href: '/scripture',
    icon: <BookOpen size={20} />,
    title: 'Read',
    body: 'A short passage and one question.',
    accent: 'bg-amber-100 text-amber-700',
  },
  {
    href: '/prayers',
    icon: <BookHeart size={20} />,
    title: 'Pray',
    body: 'A prayer for what you are facing.',
    accent: 'bg-rose-100 text-rose-700',
  },
  {
    href: '/praise',
    icon: <Music size={20} />,
    title: 'Sing',
    body: 'Worship songs, lyrics + chords.',
    accent: 'bg-indigo-100 text-indigo-700',
  },
];

export function QuickActions() {
  return (
    <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
      {actions.map(a => (
        <Link
          key={a.href}
          href={a.href}
          className="group card-quiet p-5 hover:scale-[1.02] transition-transform duration-500 flex flex-col"
        >
          <div className={`w-10 h-10 rounded-full ${a.accent} flex items-center justify-center mb-3 group-hover:scale-110 transition-transform`}>
            {a.icon}
          </div>
          <h3 className="serif text-lg mb-1">{a.title}</h3>
          <p className="text-xs text-ink/55 leading-relaxed flex-1">{a.body}</p>
          <div className="mt-2 inline-flex items-center gap-1 text-[10px] text-ink/30 group-hover:text-ink/60 group-hover:gap-1.5 transition-all">
            <ArrowRight size={10} />
          </div>
        </Link>
      ))}
    </div>
  );
}
