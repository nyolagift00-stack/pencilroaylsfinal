// UI helpers
function showAlert(type, message) {
  const alert = document.createElement('div');
  alert.className = `alert ${type}`;
  alert.textContent = message;
  document.body.appendChild(alert);
  setTimeout(() => alert.remove(), 3000);
}

function showLoader() {
  const loader = document.createElement('div');
  loader.id = 'loader';
  loader.textContent = 'Loading...';
  loader.style.cssText = 'position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.2); z-index: 9999;';
  document.body.appendChild(loader);
}

function hideLoader() {
  const loader = document.getElementById('loader');
  if (loader) loader.remove();
}

// Wait for Supabase to be ready
async function ensureReady() {
  try {
    const sb = await getSupabase();
    return true;
  } catch (e) {
    console.error('ensureReady error:', e);
    throw e;
  }
}
