'use client';

import { useEffect } from 'react';

export function ServiceWorkerRegister() {
  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!('serviceWorker' in navigator)) return;

    navigator.serviceWorker.register('/sw.js').then(reg => {
      // Pre-cache today's meditation audio + ambient tracks on first load
      // (so they work offline after first visit)
      if (navigator.serviceWorker.controller) {
        // Find ambient audio URLs in the DOM
        const ambientUrls = ['rain', 'ocean', 'forest', 'drone', 'piano', 'whitenoise', 'fire', 'river', 'wind', 'room']
          .map(t => `/audio/ambient-${t}.mp3`);
        // Find any meditation audio that's currently visible/playing
        const playBtn = document.querySelector('[data-audio-src]') as HTMLElement | null;
        const currentAudio = playBtn?.getAttribute('data-audio-src');
        const urls = currentAudio ? [currentAudio, ...ambientUrls] : ambientUrls;
        navigator.serviceWorker.controller.postMessage({
          type: 'PRECACHE_AUDIO',
          urls,
        });
      }
    }).catch(() => {});

    // When SW updates, take control immediately so the new cache is used
    let refreshing = false;
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (refreshing) return;
      refreshing = true;
      window.location.reload();
    });
  }, []);

  return null;
}
