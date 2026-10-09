/* Mi Espacio — service worker
   Hace dos cosas:
   1) Que la web se pueda INSTALAR como aplicación (con icono propio).
   2) Que funcione SIN INTERNET con la última copia que ya viste:
      la página y los datos se guardan solos al abrirlos. */
const CACHE = "miespacio-2026-10-09";
const ESENV = ["./", "./index.html", "./manifest.webmanifest",
  "./icono-192.png", "./icono-180.png", "./icono.png", "./MiEspacio-QR.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ESENV)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys().then(k => Promise.all(k.filter(x => x !== CACHE).map(x => caches.delete(x))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const u = new URL(e.request.url);
  /* la nube (api.github.com) nunca se cachea: guardar y borrar va en vivo */
  if(e.request.method !== "GET" || u.origin !== location.origin) return;

  const esDato = /registro\.csv|papelera\.json|filtros\.json/.test(u.pathname);
  if(esDato || e.request.mode === "navigate"){
    /* datos y página: primero la nube; si no hay internet → la copia guardada */
    e.respondWith(
      fetch(e.request).then(r => {
        const copia = r.clone();
        caches.open(CACHE).then(c => c.put(e.request, copia));
        return r;
      }).catch(() => caches.match(e.request, {ignoreSearch:true})
        .then(x => x || caches.match("./index.html")))
    );
    return;
  }
  /* iconos y demás: primero lo guardado */
  e.respondWith(
    caches.match(e.request).then(x => x || fetch(e.request).then(r => {
      const copia = r.clone();
      caches.open(CACHE).then(c => c.put(e.request, copia));
      return r;
    }))
  );
});
