"""Después de flutter build web --base-href /Avisos-y-Promedios/app/ --pwa-strategy=none."""
from pathlib import Path
import hashlib, json, shutil
p=Path(__file__).resolve().parents[1]
source=p/'build/web'
assert (source/'main.dart.js').exists(), 'Primero compilá la app web.'
out=p/'build/publicacion_web'
out.mkdir(parents=True,exist_ok=True)
shutil.copy2(p/'distribucion/index.html',out/'index.html')
shutil.copytree(source,out/'app',dirs_exist_ok=True)
(out/'.nojekyll').touch()
app=out/'app'
files=sorted(f for f in app.rglob('*') if f.is_file() and f.name not in ('ap-sw.js','flutter_service_worker.js'))
version=hashlib.sha256(b''.join(hashlib.sha256(f.read_bytes()).digest() for f in files)).hexdigest()[:16]
# Sólo recursos estáticos propios. Nunca cachear Firebase ni datos de cuentas.
resources=['./'+f.relative_to(app).as_posix() for f in files]
worker="""const CACHE = 'ap-REEMPLAZAR_VERSION';
const RECURSOS = REEMPLAZAR_RECURSOS;
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(c => c.addAll(RECURSOS)));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k.startsWith('ap-') && k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  const base = new URL(self.registration.scope);
  if (event.request.method !== 'GET' || url.origin !== base.origin || !url.pathname.startsWith(base.pathname)) return;
  // Cada recurso pertenece a esta versión; una nueva instalación se activa al cerrar las ventanas anteriores.
  const key = event.request.mode === 'navigate' ? new URL('index.html', base).href : event.request;
  event.respondWith(caches.open(CACHE).then(async c => (await c.match(key)) || fetch(event.request)));
});
""".replace('REEMPLAZAR_VERSION',version).replace('REEMPLAZAR_RECURSOS',json.dumps(resources))
(app/'ap-sw.js').write_text(worker,encoding='utf-8')
print('Publicación preparada en',out)
