'use client';

import { useEffect, useRef } from 'react';
import { useAudio } from '@/lib/audio-context';

export function AudioVisualizer({ className = '' }: { className?: string }) {
  const { isPlaying, progress, duration } = useAudio();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rafRef = useRef<number | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Set canvas size
    const resize = () => {
      const dpr = window.devicePixelRatio || 1;
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      canvas.width = w * dpr;
      canvas.height = h * dpr;
      ctx.scale(dpr, dpr);
    };
    resize();
    window.addEventListener('resize', resize);

    let t = 0;
    const draw = () => {
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      ctx.clearRect(0, 0, w, h);

      // Center breathing pulse — large soft circles
      const cx = w / 2;
      const cy = h / 2;
      const baseR = Math.min(w, h) * 0.18;
      const pulseR = baseR + (isPlaying ? Math.sin(t * 0.012) * 30 + 20 : Math.sin(t * 0.004) * 8);

      // Outer soft ring
      const grad = ctx.createRadialGradient(cx, cy, baseR * 0.5, cx, cy, pulseR * 2.5);
      grad.addColorStop(0, 'rgba(180, 195, 175, 0.25)');
      grad.addColorStop(0.5, 'rgba(180, 195, 175, 0.08)');
      grad.addColorStop(1, 'rgba(180, 195, 175, 0)');
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, w, h);

      // Inner soft core
      const core = ctx.createRadialGradient(cx, cy, 0, cx, cy, baseR);
      core.addColorStop(0, 'rgba(220, 200, 170, 0.3)');
      core.addColorStop(1, 'rgba(220, 200, 170, 0)');
      ctx.fillStyle = core;
      ctx.fillRect(0, 0, w, h);

      // Soft wave lines emanating from center
      ctx.lineWidth = 0.5;
      for (let i = 0; i < 4; i++) {
        const phase = t * 0.008 + i * 1.5;
        const r = baseR + 40 + i * 30 + Math.sin(phase) * 8;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(160, 180, 160, ${0.15 - i * 0.03})`;
        ctx.stroke();
      }

      t++;
      rafRef.current = requestAnimationFrame(draw);
    };
    draw();

    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      window.removeEventListener('resize', resize);
    };
  }, [isPlaying]);

  return <canvas ref={canvasRef} className={`absolute inset-0 w-full h-full pointer-events-none ${className}`} />;
}
