// Schools list logic
async function loadSchools() {
  const sb = await getSupabase();
  // Show all schools (remove approved filter) so the list is visible even
  // if no rows are marked `approved` in the database.
  const { data } = await sb.from('schools').select('*').order('name');
  const list = document.getElementById('schoolList');
  list.innerHTML = '';
  
  if (!data || data.length === 0) {
    list.innerHTML = '<p style="text-align: center; color: #666; padding: 20px;">No approved schools yet.</p>';
    return;
  }
  
  data.forEach(s => {
    const li = document.createElement('li');
    li.style.cursor = 'pointer';
    li.style.transition = 'background 0.2s ease';
    
    const link = document.createElement('a');
    link.href = `profile.html?user=${s.user_id}`;
    link.style.textDecoration = 'none';
    link.style.color = 'inherit';
    link.style.display = 'block';
    link.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div>
          <strong>${s.name}</strong>
          <div style="font-size: 14px; color: #666; margin-top: 4px;">📍 ${s.location || 'Location not specified'}</div>
        </div>
        <span style="color: #1a3c5e; font-weight: 600;">View Profile →</span>
      </div>
    `;
    
    li.appendChild(link);
    
    // Add school detail link
    const detailLink = document.createElement('a');
    detailLink.href = `school-detail.html?school=${s.id}`;
    detailLink.textContent = ' Details';
    detailLink.style.marginLeft = '20px';
    detailLink.style.color = '#e74c3c';
    detailLink.style.fontWeight = '600';
    link.querySelector('div').appendChild(detailLink);
    
    li.addEventListener('mouseenter', () => li.style.background = '#f0f4f8');
    li.addEventListener('mouseleave', () => li.style.background = '');
    
    list.appendChild(li);
  });
}

