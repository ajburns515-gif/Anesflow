// AnesFlow Service Worker — v5 (Quick Entry + Reading Tracker + ABA Coverage)
const CACHE_NAME = 'anesflow-v5';
const CDN_CACHE = 'anesflow-cdn-v5';
const PRECACHE_URLS = ['/', '/index.html', '/manifest.json', '/icons/icon-192.svg', '/icons/icon-512.svg'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(c => c.addAll(PRECACHE_URLS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME && k !== CDN_CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // Never intercept Anthropic API calls
  if (url.hostname.includes('anthropic.com')) return;
  // Fonts: network first, cache fallback
  if (url.hostname.includes('fonts.google') || url.hostname.includes('fonts.gstatic')) {
    e.respondWith(fetch(e.request).then(res => {
      caches.open(CDN_CACHE).then(c => c.put(e.request, res.clone()));
      return res;
    }).catch(() => caches.match(e.request)));
    return;
  }
  // CDN scripts: cache first (versioned URLs)
  if (url.hostname.includes('cdnjs.cloudflare.com')) {
    e.respondWith(caches.match(e.request).then(hit => hit || fetch(e.request).then(res => {
      caches.open(CDN_CACHE).then(c => c.put(e.request, res.clone()));
      return res;
    })));
    return;
  }
  // App shell: cache first, network fallback, offline → index.html
  e.respondWith(caches.match(e.request).then(hit => {
    if (hit) return hit;
    return fetch(e.request).then(res => {
      if (res && res.status === 200) caches.open(CACHE_NAME).then(c => c.put(e.request, res.clone()));
      return res;
    }).catch(() => caches.match('/index.html'));
  }));
});
