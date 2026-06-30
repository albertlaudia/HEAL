'use client';

import Link from 'next/link';
import Image from 'next/image';
import { ChevronRight, Award } from 'lucide-react';
import { cdnUrl } from '@/lib/utils';
import type { HEALProgram } from '@/lib/pb';

const themeColors: Record<string, { accent: string; soft: string }> = {
  rose: { accent: 'text-rose-700', soft: 'bg-rose-50' },
  teal: { accent: 'text-teal-700', soft: 'bg-teal-50' },
  amber: { accent: 'text-amber-700', soft: 'bg-amber-50' },
  sage: { accent: 'text-sage-700', soft: 'bg-sage-50' },
  indigo: { accent: 'text-indigo-700', soft: 'bg-indigo-50' },
  'muted-blue': { accent: 'text-sky-700', soft: 'bg-sky-50' },
  'warm-cream': { accent: 'text-orange-800', soft: 'bg-orange-50' },
};

export function ProgramCard({ program }: { program: HEALProgram }) {
  const colors = themeColors[program.theme_color] || themeColors.sage;
  const badgeSrc = program.badge_image_path
    ? cdnUrl(program.illustration_url || program.badge_image_path)
    : null;

  return (
    <Link
      href={`/programs/${program.slug}`}
      className="group block card-quiet overflow-hidden transition-transform hover:-translate-y-0.5"
    >
      <div className={`relative aspect-[3/2] overflow-hidden ${colors.soft}`}>
        {badgeSrc ? (
          <Image
            src={badgeSrc}
            alt={program.title}
            fill
            sizes="(max-width: 768px) 100vw, 50vw"
            className="object-cover"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center">
            <Award className={`opacity-20 ${colors.accent}`} size={64} />
          </div>
        )}
        <div className="absolute top-4 left-4">
          <span className={`text-[10px] tracking-[0.25em] uppercase font-medium px-2.5 py-1 rounded-full bg-bone/90 ${colors.accent}`}>
            {program.duration_label}
          </span>
        </div>
        {program.badge_name && (
          <div className="absolute top-4 right-4">
            <div className="flex items-center gap-1.5 text-[10px] tracking-[0.2em] uppercase font-medium px-2.5 py-1 rounded-full bg-bone/90 text-sage-700">
              <Award size={11} />
              Badge
            </div>
          </div>
        )}
      </div>

      <div className="p-6">
        <h3 className="serif text-2xl text-ink mb-2 group-hover:text-sage-800 transition-colors">
          {program.title}
        </h3>
        <p className={`serif italic text-sm mb-3 ${colors.accent}`}>{program.tagline}</p>
        <p className="text-ink/65 text-sm leading-relaxed line-clamp-3 mb-4">
          {program.description}
        </p>
        <div className="flex items-center justify-between pt-4 border-t border-ink/5">
          <span className="text-xs text-ink/50 tracking-wide">
            {program.step_count} steps · {program.badge_name ? `earn "${program.badge_name}"` : 'complete to finish'}
          </span>
          <span className={`text-sm font-medium inline-flex items-center gap-1 group-hover:translate-x-0.5 transition-transform ${colors.accent}`}>
            Begin
            <ChevronRight size={14} />
          </span>
        </div>
      </div>
    </Link>
  );
}
