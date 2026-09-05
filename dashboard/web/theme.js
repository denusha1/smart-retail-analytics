(() => {
  const stylesheet = document.createElement('link'); stylesheet.rel = 'stylesheet'; stylesheet.href = '/theme.css'; document.head.append(stylesheet);
  const saved = localStorage.getItem('retailpulse-theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  if (saved === 'dark' || (!saved && prefersDark)) document.body.classList.add('dark-mode');
  const button = document.createElement('button'); button.className = 'theme-toggle'; button.type = 'button'; button.setAttribute('aria-label', 'Toggle colour mode');
  const render = () => { const dark = document.body.classList.contains('dark-mode'); button.innerHTML = dark ? '<span>☀</span> Light mode' : '<span>◐</span> Dark mode'; };
  button.addEventListener('click', () => { document.body.classList.toggle('dark-mode'); localStorage.setItem('retailpulse-theme', document.body.classList.contains('dark-mode') ? 'dark' : 'light'); render(); });
  render(); document.body.append(button);
})();
