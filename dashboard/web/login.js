const form = document.getElementById('login-form');
form.addEventListener('submit', async event => {
  event.preventDefault(); const button = form.querySelector('button'); const error = document.getElementById('login-error'); error.textContent = ''; button.disabled = true; button.textContent = 'Signing in…';
  try { const response = await fetch('/api/login', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({email: document.getElementById('email').value, password: document.getElementById('password').value}) }); const data = await response.json(); if (!response.ok) throw new Error(data.error || 'Unable to sign in'); window.location.assign('/'); }
  catch (err) { error.textContent = err.message; button.disabled = false; button.innerHTML = 'Sign in securely <span>→</span>'; }
});
