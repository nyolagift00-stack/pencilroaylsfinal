// Students logic
const DEADLINE = new Date('2026-10-02T00:00:00Z');

async function loadStudents(schoolId) {
  const sb = await getSupabase();
  const { data } = await sb.from('students').select('*').eq('school_id', schoolId);
  const list = document.getElementById('studentList');
  list.innerHTML = '';
  if (!data || data.length === 0) {
    list.innerHTML = '<p style="color: #666;">No students registered yet.</p>';
  } else {
    data.forEach(s => {
      const li = document.createElement('li');
      li.textContent = `${s.name} (${s.gender})`;
      const editBtn = document.createElement('button');
      editBtn.textContent = 'Edit';
      editBtn.onclick = () => {
        document.getElementById('studentId').value = s.id;
        document.getElementById('name').value = s.name;
        document.getElementById('gender').value = s.gender;
      };
      li.appendChild(editBtn);
      list.appendChild(li);
    });
  }
  document.getElementById('studentCount').textContent = data ? data.length : 0;
  const boys = data ? data.filter(s => s.gender === 'male').length : 0;
  const girls = data ? data.filter(s => s.gender === 'female').length : 0;
  document.getElementById('studentStats').textContent = `Boys: ${boys} / Girls: ${girls}`;
}

async function handleStudentSubmit(e) {
  e.preventDefault();
  if (new Date() > DEADLINE) return showAlert('error', 'Deadline passed');

  showLoader();
  try {
    const user = await getCurrentUser();
    const sb = await getSupabase();
    
    // Get the user's school
    const { data: school } = await sb.from('schools').select('id').eq('user_id', user.id).single();
    if (!school) {
      hideLoader();
      showAlert('error', 'School not found');
      return;
    }
    
    const id = document.getElementById('studentId').value;
    const name = document.getElementById('name').value.trim();
    const gender = document.getElementById('gender').value;

    if (!name) {
      hideLoader();
      showAlert('error', 'Student name required');
      return;
    }

    let error;
    if (id) {
      const result = await sb.from('students').update({ name, gender }).eq('id', id);
      error = result.error;
    } else {
      const result = await sb.from('students').insert({ school_id: school.id, name, gender });
      error = result.error;
    }

    hideLoader();
    
    if (error) {
      showAlert('error', 'Save failed: ' + error.message);
    } else {
      showAlert('success', 'Student saved successfully!');
      e.target.reset();
      document.getElementById('studentId').value = '';
      // Reload the students list to show updated data
      setTimeout(() => {
        loadStudents(school.id);
      }, 300);
    }
  } catch (error) {
    hideLoader();
    console.error('Error:', error);
    showAlert('error', 'Error: ' + error.message);
  }
}

// Initialize page (with delay for script loading)
setTimeout(() => {
  protectPage().then(async (user) => {
    try {
      const sb = await getSupabase();
      const { data: school } = await sb.from('schools').select('id').eq('user_id', user.id).single();
      if (school) {
        loadStudents(school.id);
        // Setup form listener AFTER page is loaded
        document.getElementById('studentForm').addEventListener('submit', handleStudentSubmit);
      }
    } catch (err) {
      console.error('Init error:', err);
      showAlert('error', 'Error loading page');
    }
  });
}, 500);
