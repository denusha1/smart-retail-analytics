document.querySelectorAll('[data-logout]').forEach(button => button.addEventListener('click', async () => {
  await fetch('/api/logout', {method: 'POST'});
  window.location.assign('/login.html');
}));
