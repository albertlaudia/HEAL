import { NextResponse } from 'next/server';
import { getProgramBySlug } from '@/lib/pb';

export const dynamic = 'force-dynamic';

export async function GET(_req: Request, { params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const program = await getProgramBySlug(slug);
  if (!program) return NextResponse.json({ error: 'not found' }, { status: 404 });
  return NextResponse.json({
    name: program.badge_name,
    affirmation: program.badge_affirmation,
    scriptureRef: program.badge_scripture_ref,
    scriptureText: program.badge_scripture_text,
    imagePath: program.badge_image_path,
  });
}
