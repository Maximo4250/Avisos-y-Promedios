(() => {
  let propuesta;
  const boton = document.getElementById('instalar');
  const independiente = () => matchMedia('(display-mode: standalone)').matches;
  window.addEventListener('beforeinstallprompt', e => {
    e.preventDefault(); propuesta = e;
    if (!independiente()) boton.style.display = 'block';
  });
  boton.addEventListener('click', async () => {
    if (!propuesta) return;
    boton.style.display = 'none';
    await propuesta.prompt();
    await propuesta.userChoice;
    propuesta = null;
  });
  window.addEventListener('appinstalled', () => { boton.style.display = 'none'; });
  window.addEventListener('flutter-first-frame', () => document.getElementById('cargando')?.remove());
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('ap-sw.js', {scope:'./'}).catch(console.warn);
  }
})();
