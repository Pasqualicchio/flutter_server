const CACHE_NAME = 'photo-logger-cache-v1';
const urlsToCache = [
  '/',
  '/upload-advanced-ui',
  '/static/bootstrap.min.css',
  '/static/bootstrap.bundle.min.js',
  '/static/apple-touch-icon.png',
  '/manifest.json',
];

// Pre-caching delle risorse durante l'installazione
self.addEventListener('install', function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('Cache aperto');
      return cache.addAll(urlsToCache);  // Aggiungi tutte le URL al cache
    })
  );
});

// Aggiorna la cache quando cambia una versione del service worker
self.addEventListener('activate', function (event) {
  const cacheWhitelist = [CACHE_NAME];  // Mantieni solo il cache della versione corrente
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (!cacheWhitelist.includes(cacheName)) {
            console.log('Cache eliminato:', cacheName);
            return caches.delete(cacheName);  // Elimina i vecchi cache
          }
        })
      );
    })
  );
});

// Intercetta le richieste di rete
self.addEventListener('fetch', function (event) {
  event.respondWith(
    caches.match(event.request).then((response) => {
      // Se la risorsa è nella cache, restituiscila
      if (response) {
        return response;
      }
      
      // Se la risorsa non è nella cache, effettuare una richiesta di rete
      return fetch(event.request).catch(() => {
        // Se la rete non è disponibile, fornisci una pagina di fallback
        if (event.request.url.includes('.html')) {
          return caches.match('/offline.html');  // Fallback se il file è HTML
        }
        return null;  // Restituisci null per le altre risorse (come immagini, CSS, ecc.)
      });
    })
  );
});
