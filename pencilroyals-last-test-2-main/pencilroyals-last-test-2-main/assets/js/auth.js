// Auth logic
// Helper function to get Supabase instance
async function getSupabase() {
  const SUPABASE_URL = 'https://tjooofnjwwtgageayezr.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqb29vZm5qd3d0Z2FnZWF5ZXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0NTI1NDIsImV4cCI6MjA4NjAyODU0Mn0.Pg8ldP8qI6e70WNGNzdnAbMmgAlL1rb6w41sGjXFc9Y';
  
  let retries = 0;
  while (retries < 100) {
    if (window.supabase && window.supabase.createClient) {
      return window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    } else if (window.Supabase && window.Supabase.createClient) {
      return window.Supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    }
    await new Promise(r => setTimeout(r, 50));
    retries++;
  }
  throw new Error('Supabase library failed to load');
}

// ========================================
// ROLE-BASED PERMISSION FUNCTIONS
// ========================================

// Get user role from database
async function getUserRole(userId) {
  try {
    const sb = await getSupabase();
    const { data, error } = await sb
      .from('user_roles')
      .select('role')
      .eq('user_id', userId)
      .single();
    
    if (error || !data) {
      console.warn('No role found for user, defaulting to "user":', userId);
      return 'user';
    }
    return data.role;
  } catch (err) {
    console.error('Error getting user role:', err);
    return 'user';
  }
}

// Check if user is admin
async function isUserAdmin(userId) {
  const role = await getUserRole(userId);
  return role === 'admin';
}

// Check if user is a school
async function isUserSchool(userId) {
  const role = await getUserRole(userId);
  return role === 'school';
}

// Get user's school ID
async function getUserSchoolId(userId) {
  try {
    const sb = await getSupabase();
    const { data, error } = await sb
      .from('user_roles')
      .select('school_id')
      .eq('user_id', userId)
      .single();
    
    if (error || !data) {
      // Try to get it from schools table instead
      const { data: schoolData } = await sb
        .from('schools')
        .select('id')
        .eq('user_id', userId)
        .single();
      return schoolData?.id || null;
    }
    return data.school_id;
  } catch (err) {
    console.error('Error getting user school ID:', err);
    return null;
  }
}

// Check if school is verified
async function isSchoolVerified(userId) {
  try {
    console.log('🔍 Checking if school is verified for user:', userId);
    
    const sb = await getSupabase();
    
    // Get school ID
    const schoolId = await getUserSchoolId(userId);
    if (!schoolId) {
      console.log('   ⚠️ No school ID found');
      return false;
    }
    
    console.log('   School ID:', schoolId);
    
    // Check verification status
    const { data, error } = await sb
      .from('school_verification')
      .select('verification_status')
      .eq('school_id', schoolId)
      .single();
    
    if (error) {
      console.log('   Query error:', error.message);
      return false;
    }
    
    const isVerified = data && data.verification_status === 'approved';
    console.log('   Verification status:', data?.verification_status, '- Approved:', isVerified);
    
    return isVerified;
  } catch (err) {
    console.error('❌ Error checking school verification:', err);
    return false;
  }
}

// Get school verification status
async function getSchoolVerificationStatus(userId) {
  try {
    console.log('📋 Getting school verification status for user:', userId);
    
    const sb = await getSupabase();
    
    // Get school ID
    const schoolId = await getUserSchoolId(userId);
    if (!schoolId) {
      console.log('   ⚠️ No school ID found');
      return null;
    }
    
    // Get verification record
    const { data, error } = await sb
      .from('school_verification')
      .select('*')
      .eq('school_id', schoolId)
      .single();
    
    if (error) {
      console.log('   Query error:', error.message);
      return null;
    }
    
    console.log('   Status record found:', data?.verification_status);
    return data;
  } catch (err) {
    console.error('❌ Error getting school verification status:', err);
    return null;
  }
}

// Protect school pages - redirect unverified schools to verification page
async function protectSchoolPage() {
  try {
    console.log('🔐 Protecting school page...');
    
    const user = await getCurrentUser();
    if (!user) {
      console.log('   ⚠️ No user found, redirecting to login');
      window.location.href = 'login.html';
      return false;
    }
    
    console.log('   User:', user.email);
    
    const isSchool = await isUserSchool(user.id);
    console.log('   Is school user:', isSchool);
    
    if (!isSchool) {
      console.log('   ℹ️ Not a school user, allowing access (admin or regular user)');
      return true; // Not a school user, allow access
    }
    
    // Check if verified
    const isVerified = await isSchoolVerified(user.id);
    console.log('   Is verified:', isVerified);
    
    if (!isVerified) {
      console.log('   📍 Redirecting to verification page');
      window.location.href = 'school-verification.html';
      return false;
    }
    
    console.log('   ✅ School verified, allowing access');
    return true;
  } catch (err) {
    console.error('❌ Error protecting school page:', err);
    return false;
  }
}

// Protect admin pages - redirect non-admins away
async function protectAdminPage() {
  try {
    console.log('🔐 Protecting admin page...');
    
    const user = await getCurrentUser();
    if (!user) {
      console.log('   ⚠️ No user found, redirecting to login');
      window.location.href = 'login.html';
      return false;
    }
    
    console.log('   User:', user.email);
    
    const isAdmin = await isUserAdmin(user.id);
    console.log('   Is admin:', isAdmin);
    
    if (!isAdmin) {
      console.log('   ❌ Access denied - not admin');
      document.body.innerHTML = `
        <div style="max-width: 600px; margin: 50px auto; padding: 30px; background: #ffe6e6; border-radius: 8px; border-left: 4px solid #dc3545;">
          <h2 style="color: #dc3545; margin: 0 0 15px 0;">❌ Access Denied</h2>
          <p style="color: #666; margin: 10px 0;">
            You do not have permission to access this page. Admin access is required.
          </p>
          <p style="color: #666; margin: 10px 0;">
            <strong>Your email:</strong> ${user.email}
          </p>
          <button onclick="logout()" style="margin-top: 20px; padding: 10px 20px; background: #dc3545; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600;">
            Logout
          </button>
        </div>
      `;
      return false;
    }
    
    console.log('   ✅ Admin access granted');
    return true;
  } catch (err) {
    console.error('❌ Error protecting admin page:', err);
    return false;
  }
}



async function login(email, password) {
  showLoader();
  try {
    const sb = await getSupabase();
    const { data, error } = await sb.auth.signInWithPassword({ email, password });
    hideLoader();
    if (error) {
      console.error('Login error:', error);
      showAlert('error', error.message);
      const loader = document.getElementById('loadingStatus');
      if (loader) loader.style.display = 'none';
      return false;
    }
    console.log('Login successful, user:', data.user.email);
    showAlert('success', 'Logged in successfully!');

    // Set long-lived cookies (10 years) with user and school ids for client convenience
    try {
      function setCookie(name, value, days) {
        const expires = new Date(Date.now() + days * 864e5).toUTCString();
        document.cookie = name + '=' + encodeURIComponent(value) + '; expires=' + expires + '; path=/';
      }
      // Try to find the user's school and persist both ids
      try {
        const { data: school } = await sb.from('schools').select('id').eq('user_id', data.user.id).single();
        if (school && school.id) setCookie('pencil_school_id', school.id, 3650);
      } catch (e) {
        console.warn('Could not fetch school for cookie set:', e?.message || e);
      }
      setCookie('pencil_user_id', data.user.id, 3650);
      // Also store ids in localStorage as a more reliable fallback across origins
      try {
        localStorage.setItem('pencil_user_id', data.user.id);
        if (typeof school !== 'undefined' && school && school.id) localStorage.setItem('pencil_school_id', school.id);
      } catch (e) {
        console.warn('localStorage set failed:', e?.message || e);
      }
    } catch (e) {
      console.warn('Cookie set failed:', e?.message || e);
    }

    // Check user role from database
    const userRole = await getUserRole(data.user.id);
    console.log('User role:', userRole);

    setTimeout(async () => {
      if (userRole === 'admin') {
        console.log('✅ Admin detected, redirecting to admin panel');
        window.location.href = 'admin-panel.html';
      } else if (userRole === 'school') {
        // Check if school is verified
        const isVerified = await isSchoolVerified(data.user.id);
        if (!isVerified) {
          console.log('⏳ School not verified, redirecting to verification page');
          window.location.href = 'school-verification.html';
        } else {
          console.log('✅ School verified, redirecting to dashboard');
          window.location.href = `profile.html?user=${data.user.id}`;
        }
      } else if (data.user && data.user.id) {
        window.location.href = `profile.html?user=${data.user.id}`;
      } else {
        window.location.href = 'profile.html';
      }
    }, 1500);
    return true;
  } catch (err) {
    hideLoader();
    console.error('Login exception:', err);
    showAlert('error', 'Login failed: ' + err.message);
    const loader = document.getElementById('loadingStatus');
    if (loader) loader.style.display = 'none';
    return false;
  }
}

async function signup(email, password) {
  showLoader();
  try {
    const sb = await getSupabase();
    const redirectBase = (window.APP_SITE_URL || window.location.origin);
    const redirectTo = redirectBase + '/profile.html';
    const { data, error } = await sb.auth.signUp({ email, password }, { redirectTo });
    hideLoader();
    if (error) {
      console.error('Signup error:', error);
      showAlert('error', 'Signup failed: ' + error.message);
      const loader = document.getElementById('loadingStatus');
      if (loader) loader.style.display = 'none';
      return null;
    }
    console.log('Signup successful, user:', data.user);
    showAlert('success', 'Account created! Setting up profile...');
    return data.user;
  } catch (err) {
    hideLoader();
    console.error('Signup exception:', err);
    showAlert('error', 'Signup failed: ' + err.message);
    const loader = document.getElementById('loadingStatus');
    if (loader) loader.style.display = 'none';
    return null;
  }
}

async function saveSchoolProfile(userId, name, location, profilePic = null) {
  try {
    const sb = await getSupabase();
    // Return the inserted school row so callers can get the new school ID immediately
    const { data, error } = await sb.from('schools')
      .insert({ user_id: userId, name, location, approved: false, profile_pic: profilePic })
      .select()
      .single();
    if (error || !data) {
      console.error('Profile save error:', error);
      showAlert('error', 'Profile save failed: ' + (error?.message || 'unknown'));
      return null;
    }
    console.log('Profile saved successfully', data);
    
    // IMPORTANT: Also create the user_roles entry so the user can login
    const { error: roleError } = await sb.from('user_roles')
      .insert({ 
        user_id: userId, 
        role: 'school',
        school_id: data.id 
      });
    
    if (roleError) {
      console.error('Error creating user role:', roleError);
      // Don't fail completely - school was created, just role might have issues
      showAlert('warning', 'School created but role setup had issues. You may need to contact admin.');
    } else {
      console.log('✅ User role created successfully');
    }
    
    return data;
  } catch (err) {
    console.error('Profile save exception:', err);
    showAlert('error', 'Profile save failed: ' + err.message);
    return null;
  }
}
