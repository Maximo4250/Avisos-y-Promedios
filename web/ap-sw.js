// Sustituido por tool/preparar_web.py al generar una publicación.
self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
