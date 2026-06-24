// Root OG image — used when no per-page image exists
import { ImageResponse } from 'next/og';

export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';
export const runtime = 'nodejs';

export default function OG() {
  return new ImageResponse(
    (
      <div style={{
        width: '100%', height: '100%', background: '#F8F4ED',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
      }}>
        <div style={{ position: 'absolute', top: -150, right: -150, width: 480, height: 480, borderRadius: 9999, border: '1.5px solid #5F7E4E', opacity: 0.15 }} />
        <div style={{ position: 'absolute', bottom: -200, left: -200, width: 600, height: 600, borderRadius: 9999, border: '1.5px solid #5F7E4E', opacity: 0.12 }} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
          <div style={{ width: 80, height: 80, borderRadius: 9999, border: '2px solid #5F7E4E', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ width: 32, height: 32, borderRadius: 9999, background: '#5F7E4E' }} />
          </div>
          <div style={{ fontSize: 96, color: '#2A2622', fontFamily: 'serif', letterSpacing: 8 }}>HEAL</div>
        </div>
        <div style={{ fontSize: 36, color: '#5A5249', fontFamily: 'serif', fontStyle: 'italic', marginTop: 32, textAlign: 'center' }}>
          A quiet practice for a noisy world
        </div>
        <div style={{ fontSize: 22, color: '#5A5249', opacity: 0.7, fontFamily: 'serif', marginTop: 16 }}>
          Daily Christian mindfulness · meditation · breath · scripture · prayer
        </div>
      </div>
    ),
    size
  );
}
