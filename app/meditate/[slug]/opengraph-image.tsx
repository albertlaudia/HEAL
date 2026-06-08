// Dynamic OG image — beautiful branded card per meditation
// Renders at /meditate/<slug>/opengraph-image (Next 15 file convention)
// Twitter/Facebook/LinkedIn scrapers will pick this up automatically
import { ImageResponse } from 'next/og';
import { getBySlug, getPublished } from '@/lib/pb';

export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';
export const runtime = 'nodejs';
// Always re-render in case we update an illustration
export const dynamic = 'force-dynamic';

const THEME_COLORS: Record<string, { bg: string; accent: string; fg: string }> = {
  calm:       { bg: '#E1E9DC', accent: '#5F7E4E', fg: '#2D3D24' },
  gratitude:  { bg: '#F4E7C8', accent: '#A87825', fg: '#634214' },
  'let-go':   { bg: '#E5E8F0', accent: '#475679', fg: '#1E2742' },
  love:       { bg: '#F1E0D0', accent: '#A57B5B', fg: '#5A3922' },
  focus:      { bg: '#E5E8F0', accent: '#475679', fg: '#1E2742' },
  stillness:  { bg: '#F2F5F0', accent: '#5F7E4E', fg: '#2D3D24' },
  courage:    { bg: '#F4E7C8', accent: '#A87825', fg: '#634214' },
  rest:       { bg: '#F5F6F9', accent: '#6B7BA0', fg: '#1E2742' },
};

export default async function OG({ params }: { params: { slug: string } }) {
  const m: any = await getBySlug('HEAL_meditations', params.slug);
  if (!m) {
    return new ImageResponse(
      (
        <div style={{ width: '100%', height: '100%', background: '#F8F4ED', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ fontSize: 64, color: '#2A2622', fontFamily: 'serif' }}>HEAL</div>
        </div>
      ),
      size
    );
  }

  const palette = THEME_COLORS[m.theme] || THEME_COLORS.calm;
  const reflection = (m.reflection || '').slice(0, 220);
  const scriptureRef = m.scripture_ref || '';
  const day = m.day_of_year || '';

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          background: palette.bg,
          display: 'flex',
          flexDirection: 'column',
          padding: '72px 80px',
          position: 'relative',
        }}
      >
        {/* Decorative concentric circles */}
        <div style={{ position: 'absolute', top: -120, right: -120, display: 'flex' }}>
          <div style={{ width: 360, height: 360, borderRadius: 9999, border: `2px solid ${palette.accent}`, opacity: 0.18 }} />
        </div>
        <div style={{ position: 'absolute', bottom: -180, left: -180, display: 'flex' }}>
          <div style={{ width: 480, height: 480, borderRadius: 9999, border: `1.5px solid ${palette.accent}`, opacity: 0.15 }} />
        </div>

        {/* HEAL logo top-left */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, position: 'relative' }}>
          <div style={{ display: 'flex', width: 56, height: 56, borderRadius: 9999, border: `1.5px solid ${palette.accent}`, alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ display: 'flex', width: 22, height: 22, borderRadius: 9999, background: palette.accent }} />
          </div>
          <div style={{ fontSize: 36, color: palette.fg, fontFamily: 'serif', letterSpacing: 6 }}>HEAL</div>
        </div>

        {/* Theme + day badge */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginTop: 48, position: 'relative' }}>
          <div style={{
            display: 'flex',
            padding: '8px 18px',
            borderRadius: 9999,
            background: palette.accent,
            color: '#FFFFFF',
            fontSize: 18,
            letterSpacing: 3,
            textTransform: 'uppercase',
          }}>
            {m.theme || 'meditation'}
          </div>
          {day ? (
            <div style={{ fontSize: 18, color: palette.fg, opacity: 0.6, letterSpacing: 2 }}>
              DAY {day} · {Math.round((m.duration_seconds || 0) / 60) || 5} MIN
            </div>
          ) : null}
        </div>

        {/* Title */}
        <div
          style={{
            display: 'flex',
            fontSize: 76,
            color: palette.fg,
            fontFamily: 'serif',
            lineHeight: 1.05,
            marginTop: 36,
            maxWidth: 1040,
            position: 'relative',
          }}
        >
          {m.title}
        </div>

        {/* Reflection */}
        {reflection ? (
          <div
            style={{
              display: 'flex',
              fontSize: 28,
              color: palette.fg,
              opacity: 0.78,
              fontFamily: 'serif',
              fontStyle: 'italic',
              lineHeight: 1.4,
              marginTop: 28,
              maxWidth: 980,
              position: 'relative',
            }}
          >
            "{reflection}{reflection.length >= 220 ? '…' : ''}"
          </div>
        ) : null}

        {/* Footer: scripture + URL */}
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', marginTop: 'auto', position: 'relative' }}>
          {scriptureRef ? (
            <div style={{ display: 'flex', fontSize: 24, color: palette.fg, opacity: 0.7, fontFamily: 'serif', fontStyle: 'italic' }}>
              — {scriptureRef}
            </div>
          ) : <div />}
          <div style={{ display: 'flex', fontSize: 22, color: palette.fg, opacity: 0.6, fontFamily: 'serif' }}>
            heal.app / meditate / {m.slug}
          </div>
        </div>
      </div>
    ),
    { ...size, fonts: [] }
  );
}
