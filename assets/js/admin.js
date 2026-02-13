// Admin logic

// Protect admin page - check permissions before loading dashboard
async function initAdminDashboard() {
  try {
    const isProtected = await protectAdminPage();
    if (!isProtected) return; // User doesn't have admin access
    
    await loadAdminDashboard();
  } catch (err) {
    console.error('Error initializing admin dashboard:', err);
    showAlert('error', 'Error: ' + err.message);
  }
}

async function loadAdminDashboard() {
  const sb = await getSupabase();
  const { count: schools } = await sb.from('schools').select('*', { count: 'exact' });
  const { count: students } = await sb.from('students').select('*', { count: 'exact' });
  const { count: pending } = await sb.from('schools').select('*', { count: 'exact' }).eq('approved', false);
  document.getElementById('totalSchools').textContent = schools;
  document.getElementById('totalStudents').textContent = students;
  document.getElementById('pendingApprovals').textContent = pending;
}

// Initialize on page load
window.addEventListener('load', initAdminDashboard);
