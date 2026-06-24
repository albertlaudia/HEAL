'use client';

import { useEffect, useState } from 'react';
import { Award } from 'lucide-react';
import { getAllBadges, type BadgeRecord } from '@/lib/programs-client';
import type { HEALProgram } from '@/lib/pb';
import { BadgesCollectionClient, LockedBadgesList } from './BadgesCollectionClient';

export function BadgesFullPage({ programs }: { programs: HEALProgram[] }) {
  const [earnedSlugs, setEarnedSlugs] = useState<string[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
    getAllBadges()
      .then((badges) => setEarnedSlugs(badges.map((b) => b.programSlug)))
      .catch(() => {});
  }, [programs]);

  if (!hydrated) {
    return (
      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {[1, 2, 3, 4, 5, 6].map((i) => (
          <div key={i} className="animate-pulse aspect-[3/4] rounded-2xl bg-ink/5" />
        ))}
      </div>
    );
  }

  return (
    <>
      <BadgesCollectionClient programs={programs} />
      {programs.length > 0 && (
        <section className="mt-20 max-w-5xl mx-auto">
          <h2 className="serif text-2xl text-ink mb-4">Badges still to earn</h2>
          <p className="text-ink/65 text-sm mb-6">
            These badges are waiting for you, on the other side of a program. Take your time.
          </p>
          <LockedBadgesList programs={programs} earnedSlugs={earnedSlugs} />
        </section>
      )}
    </>
  );
}
