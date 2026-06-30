// HEAL service worker — multi-strategy cache
// - Audio: cache-first (immutable, large, expensive to re-fetch)
// - Images: cache-first with revalidation
// - Fonts / static: cache-first
// - HTML pages: network-first with cache fallback
// - API/data: stale-while-revalidate
// - Cleanup: drop old caches on activate

const CACHE_VERSION = 'heal-v4';
const CACHE_AUDIO = `${CACHE_VERSION}-audio`;
const CACHE_IMAGES = `${CACHE_VERSION}-images`;
const CACHE_STATIC = `${CACHE_VERSION}-static`;
const CACHE_PAGES = `${CACHE_VERSION}-pages`;
const CACHE_DATA = `${CACHE_VERSION}-data`;

const STATIC_ASSETS = [
  '/',
  '/meditate',
  '/breathe',
  '/scripture',
  '/prayers',
  '/praise',
  '/essays',
  '/about',
  '/manifest.json',
  '/icon.svg',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_PAGES)
      .then(c => c.addAll(STATIC_ASSETS).catch(() => {}))
  );
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys
        .filter(k => !k.startsWith(CACHE_VERSION))
        .map(k => caches.delete(k))
    )).then(() => self.clients.claim())
  );
});

const matchCache = async (cacheName, request) => {
  const cache = await caches.open(cacheName);
  return cache.match(request);
};

const putCache = async (cacheName, request, response) => {
  if (!response || response.status !== 200) return;
  const cache = await caches.open(cacheName);
  cache.put(request, response.clone());
};

const isAudio = (url) => /\.(mp3|m4a|wav|ogg)$/i.test(url.pathname);
const isImage = (url) => /\.(png|jpg|jpeg|webp|avif|svg|gif|ico)$/i.test(url.pathname);

// HEAL media is served from a Cloudflare-fronted IIS at resources.positiveness.club
// We want the SW to also cache those responses (same cache-first strategy).
const HEAL_CDN_HOST = 'resources.positiveness.club';
const isHealCdn = (url) => url.hostname === HEAL_CDN_HOST && url.pathname.startsWith('/heal/');
const isStatic = (url) => /\/_next\/static\//.test(url.pathname) || /\.(js|css|woff2?|ttf)$/i.test(url.pathname);
const isData = (url) => /\/api\//.test(url.pathname) || /\/api\/collections\//.test(url.pathname);
const isPage = (url) => url.pathname === '/' || !/\.[a-z0-9]+$/i.test(url.pathname);

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Don't cache other origins (except our own CDN)
  if (url.origin !== self.location.origin && !isHealCdn(url)) return;

  // Audio — cache first, fall back to network, then put in cache
  if (isAudio(url)) {
    e.respondWith(
      caches.open(CACHE_AUDIO).then(async cache => {
        const cached = await cache.match(req);
        if (cached) return cached;
        try {
          const res = await fetch(req);
          if (res.ok) cache.put(req, res.clone());
          return res;
        } catch (err) {
          // Return a tiny silent audio fallback so the player doesn't break
          return new Response(new ArrayBuffer(0), { status: 504, statusText: 'Offline (no cached audio)' });
        }
      })
    );
    return;
  }

  // Images — stale-while-revalidate
  if (isImage(url)) {
    e.respondWith(
      caches.open(CACHE_IMAGES).then(async cache => {
        const cached = await cache.match(req);
        const networkFetch = fetch(req)
          .then(res => { if (res.ok) cache.put(req, res.clone()); return res; })
          .catch(() => cached);
        return cached || networkFetch;
      })
    );
    return;
  }

  // Static assets (JS, CSS, fonts) — cache first
  if (isStatic(url)) {
    e.respondWith(
      caches.open(CACHE_STATIC).then(async cache => {
        const cached = await cache.match(req);
        if (cached) return cached;
        try {
          const res = await fetch(req);
          if (res.ok) cache.put(req, res.clone());
          return res;
        } catch (err) {
          return cached || new Response('', { status: 504 });
        }
      })
    );
    return;
  }

  // Data/API — stale-while-revalidate
  if (isData(url)) {
    e.respondWith(
      caches.open(CACHE_DATA).then(async cache => {
        const cached = await cache.match(req);
        const networkFetch = fetch(req)
          .then(res => { if (res.ok) cache.put(req, res.clone()); return res; })
          .catch(() => cached);
        return cached || networkFetch;
      })
    );
    return;
  }

  // HTML pages — network first, fall back to cache
  if (isPage(url) && req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(res => {
          if (res.ok) {
            const clone = res.clone();
            caches.open(CACHE_PAGES).then(c => c.put(req, clone)).catch(() => {});
          }
          return res;
        })
        .catch(() => caches.match(req).then(r => r || caches.match('/')))
    );
    return;
  }

  // Default — network with cache fallback
  e.respondWith(
    fetch(req).catch(() => caches.match(req))
  );
});

self.addEventListener('message', e => {
  if (e.data?.type === 'PRECACHE_AUDIO') {
    // Listen for messages from the app to pre-cache audio for offline use
    const urls = e.data.urls || [];
    e.waitUntil(
      caches.open(CACHE_AUDIO).then(async cache => {
        for (const url of urls) {
          try {
            const res = await fetch(url);
            if (res.ok) await cache.put(url, res);
          } catch {}
        }
      })
    );
  }
  if (e.data?.type === 'CLEAR_CACHES') {
    e.waitUntil(caches.keys().then(keys => Promise.all(keys.map(k => caches.delete(k)))));
  }
});
