const CACHE_NAME = 'afcm-module1-v1';
const OFFLINE_URLS = ['/', '/index.html', '/me/ticket'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(OFFLINE_URLS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      )
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') {
    return;
  }

  const url = new URL(request.url);

  if (OFFLINE_URLS.includes(url.pathname)) {
    event.respondWith(cacheFirst(request));
    return;
  }

  if (url.origin === self.location.origin && url.pathname.startsWith('/me/ticket')) {
    event.respondWith(networkThenCache(request));
    return;
  }

  if (url.origin === self.location.origin && url.pathname.endsWith('.json')) {
    event.respondWith(networkThenCache(request));
    return;
  }
});

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  if (cached) {
    return cached;
  }
  const response = await fetch(request);
  cache.put(request, response.clone());
  return response;
}

async function networkThenCache(request) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const response = await fetch(request);
    cache.put(request, response.clone());
    return response;
  } catch (error) {
    const cached = await cache.match(request);
    if (cached) {
      return cached;
    }
    throw error;
  }
}
