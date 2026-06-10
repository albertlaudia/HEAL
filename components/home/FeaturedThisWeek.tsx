'use client';

import Link from 'next/link';
import Image from 'next/image';
import { ArrowRight, BookOpen, Music, Wind, BookHeart } from 'lucide-react';

type Item = {
  kind: 'meditation' | 'scripture' | 'prayer' | 'praise' | 'breathwork';
  title: string;
  subtitle?: string;
  href: string;
  excerpt?: string;
  illustration?: string;
  duration?: string;
  icon?: React.ReactNode;
};

const KIND_STYLES: Record<Item['kind'], { tag: string; accent: string; icon: React.ReactNode }> = {
  meditation: { tag: 'Meditation', accent: 'text-sage-700', icon: <BookHeart size={12} /> },
  scripture: { tag: 'Scripture', accent: 'text-amber-700', icon: <BookOpen size={12} /> },
  prayer: { tag: 'Prayer', accent: 'text-rose-700', icon: <BookHeart size={12} /> },
  praise: { tag: 'Praise', accent: 'text-indigo-700', icon: <Music size={12} /> },
  breathwork: { tag: 'Breath', accent: 'text-cyan-700', icon: <Wind size={12} /> },
};

export function FeaturedThisWeek({ items }: { items: Item[] }) {
  if (!items.length) return null;

  return (
    <section className="container-wide py-16">
      <div className="flex items-end justify-between mb-8">
        <div>
          <p className="text-xs tracking-[0.3em] uppercase text-ink/50 mb-2">This week</p>
          <h2 className="serif text-3xl md:text-4xl">From the practice</h2>
        </div>
      </div>
      <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {items.slice(0, 4).map((item, i) => {
          const style = KIND_STYLES[item.kind];
          return (
            <Link
              key={i}
              href={item.href}
              className="group card-quiet overflow-hidden flex flex-col hover:scale-[1.01] transition-transform duration-500"
            >
              {item.illustration && (
                <div className="relative aspect-[3/2] bg-sage-100">
                  <Image
                    src={item.illustration}
                    alt={item.title}
                    fill
                    className="object-cover"
                    sizes="(max-width: 640px) 50vw, 25vw"
                  />
                </div>
              )}
              <div className="p-5 flex-1 flex flex-col">
                <div className={`flex items-center gap-1.5 text-[10px] tracking-widest uppercase ${style.accent} mb-2`}>
                  {style.icon}
                  <span>{style.tag}</span>
                  {item.duration && <span className="text-ink/40">· {item.duration}</span>}
                </div>
                <h3 className="serif text-lg leading-tight mb-1 group-hover:text-sage-700 transition-colors">
                  {item.title}
                </h3>
                {item.subtitle && (
                  <p className="serif italic text-ink/55 text-xs mb-2 line-clamp-1">{item.subtitle}</p>
                )}
                {item.excerpt && (
                  <p className="text-ink/65 text-xs leading-relaxed line-clamp-3 flex-1">
                    {item.excerpt}
                  </p>
                )}
                <div className="mt-3 inline-flex items-center gap-1 text-xs text-ink/40 group-hover:text-ink group-hover:gap-2 transition-all">
                  Open <ArrowRight size={12} />
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </section>
  );
}

export type { Item as FeaturedItem };
