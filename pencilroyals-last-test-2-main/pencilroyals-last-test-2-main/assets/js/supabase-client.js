// Supabase client initialization - wrapped to avoid conflicts
(function() {
  const SUPABASE_URL = 'https://tjooofnjwwtgageayezr.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqb29vZm5qd3d0Z2FnZWF5ZXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0NTI1NDIsImV4cCI6MjA4NjAyODU0Mn0.Pg8ldP8qI6e70WNGNzdnAbMmgAlL1rb6w41sGjXFc9Y';

  // Application site origins (must match Supabase CORS / URL settings)
  // Update these if you add more domains or environments
  const APP_SITE_URL = 'https://pencilroyals.com';
  const APP_ORIGINS = [
    'https://pencilroyals.com',
    'https://www.pencilroyals.com',
    'http://localhost:5500',
    'http://127.0.0.1:5500'
  ];

  let sbInstance = null;
  let isReady = false;

  // Wait for Supabase library to load from CDN
  async function waitForSupabaseLib() {
    for (let i = 0; i < 100; i++) {
      if (window.supabase && window.supabase.createClient) {
        return true;
      }
      await new Promise(r => setTimeout(r, 50));
    }
    return false;
  }

  // Initialize Supabase
  window.initSupabase = async function() {
    if (isReady) return sbInstance;
    
    try {
      // Wait for library to load
      const libLoaded = await waitForSupabaseLib();
      if (!libLoaded) {
        throw new Error('Supabase library failed to load from CDN');
      }

      sbInstance = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
      isReady = true;
      // Expose site constants for other scripts (auth redirects, tests)
      window.APP_SITE_URL = APP_SITE_URL;
      window.APP_ORIGINS = APP_ORIGINS;
      console.log('✓ Supabase ready');
      return sbInstance;
    } catch (e) {
      console.error('Supabase init error:', e);
    }
    return null;
  };

  // Get Supabase instance with retry
  window.getSupabase = async function() {
    if (isReady && sbInstance) return sbInstance;
    
    const sb = await window.initSupabase();
    if (sb) return sb;
    
    throw new Error('Supabase failed to initialize');
  };

  // Get current authenticated user
  window.getCurrentUser = async function() {
    try {
      const sb = await window.getSupabase();
      const { data: { user } } = await sb.auth.getUser();
      if (user) return user;

      // Fallback: try cookie-based id (useful when auth session isn't persisted)
      try {
        const id = (document.cookie || '').split(';').map(c => c.trim()).reduce((acc, cur) => {
          if (cur.startsWith('pencil_user_id=')) return decodeURIComponent(cur.split('=')[1]);
          return acc;
        }, null);
        if (id) {
          console.warn('Using cookie fallback for current user id:', id);
          return { id };
        }
      } catch (e) {
        console.warn('Cookie fallback failed:', e);
      }

      return null;
    } catch (e) {
      console.error('Get user error:', e);
      return null;
    }
  };

  // Protect page - redirect to login if not authenticated
  window.protectPage = async function() {
    const user = await window.getCurrentUser();
    if (!user) {
      window.location.href = 'login.html';
      return null;
    }
    return user;
  };

  // Logout function
  window.logout = async function() {
    try {
      const sb = await window.getSupabase();
      await sb.auth.signOut();
    } catch (e) {
      console.error('Logout error:', e);
    }
    // Clear convenience cookies
    try {
      document.cookie = 'pencil_user_id=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
      document.cookie = 'pencil_school_id=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
    } catch (e) {
      console.warn('Failed to clear cookies on logout:', e);
    }
    window.location.href = 'index.html';
  };

  // Try to initialize when ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => window.initSupabase());
  } else {
    window.initSupabase();
  }
})();



