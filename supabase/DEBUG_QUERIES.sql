-- ========================================
-- DEBUG & VERIFICATION QUERIES
-- ========================================
-- Run these queries one by one to diagnose login issues

-- ========================================
-- 1. Check if auth.users table has your users
-- ========================================
SELECT id, email, created_at FROM auth.users LIMIT 10;

-- ========================================
-- 2. Check if user_roles table is populated
-- ========================================
SELECT ur.user_id, ur.role, ur.school_id, au.email as auth_email, s.name as school_name
FROM user_roles ur
LEFT JOIN auth.users au ON ur.user_id = au.id
LEFT JOIN schools s ON ur.school_id = s.id
ORDER BY ur.created_at DESC;

-- ========================================
-- 3. Check if schools table has data linked to users
-- ========================================
SELECT s.id, s.user_id, s.name, s.location, au.email
FROM schools s
LEFT JOIN auth.users au ON s.user_id = au.id
ORDER BY s.created_at DESC LIMIT 10;

-- ========================================
-- 4. Check all tables exist and have data
-- ========================================
SELECT 
    'schools' as table_name, COUNT(*) as count FROM schools
UNION ALL
SELECT 'students', COUNT(*) FROM students
UNION ALL
SELECT 'competitions', COUNT(*) FROM competitions
UNION ALL
SELECT 'competition_scores', COUNT(*) FROM competition_scores
UNION ALL
SELECT 'finalists', COUNT(*) FROM finalists
UNION ALL
SELECT 'results', COUNT(*) FROM results
UNION ALL
SELECT 'votes', COUNT(*) FROM votes
UNION ALL
SELECT 'user_roles', COUNT(*) FROM user_roles
UNION ALL
SELECT 'school_verification', COUNT(*) FROM school_verification;

-- ========================================
-- 5. Test if functions work
-- ========================================
-- Replace 'USER_ID_HERE' with an actual user ID from auth.users
SELECT * FROM get_user_role('USER_ID_HERE'::UUID);

-- ========================================
-- 6. Check RLS policies on schools table
-- ========================================
SELECT schemaname, tablename, policyname, permissive, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'schools'
ORDER BY policyname;

-- ========================================
-- 7. Test public read access (should not need auth)
-- ========================================
SELECT id, name, location FROM schools LIMIT 5;

-- ========================================
-- 8. Check if students can be read (public)
-- ========================================
SELECT id, name, school_id FROM students LIMIT 5;

-- ========================================
-- 9. Find a school's user_id to test login
-- ========================================
SELECT id, user_id, name, email, location
FROM schools
LIMIT 1;

-- ========================================
-- 10. Check school verification status
-- ========================================
SELECT sv.id, sv.school_id, s.name, sv.verification_status, sv.created_at
FROM school_verification sv
LEFT JOIN schools s ON sv.school_id = s.id
ORDER BY sv.created_at DESC;

-- ========================================
-- MANUAL DATA INSERTION (if needed for testing)
-- ========================================

-- Insert a test school (replace USERID with actual UUID from auth.users)
-- INSERT INTO schools (user_id, name, email, location, contact_person, phone)
-- VALUES (
--   'USERID_HERE'::UUID,
--   'Test School',
--   'school@test.com',
--   'City, Country',
--   'Principal Name',
--   '+1234567890'
-- )
-- ON CONFLICT DO NOTHING;

-- Create user role for the school
-- INSERT INTO user_roles (user_id, role, school_id)
-- SELECT s.user_id, 'school', s.id
-- FROM schools s
-- WHERE s.user_id = 'USERID_HERE'::UUID
-- ON CONFLICT DO NOTHING;

-- ========================================
-- ADD ADMIN USER (one time setup)
-- ========================================
-- Step 1: Create admin user in Supabase Auth UI first
-- Step 2: Get admin user ID from auth.users
-- Step 3: Run this query:
-- INSERT INTO user_roles (user_id, role)
-- SELECT id, 'admin'
-- FROM auth.users
-- WHERE email = 'admin@example.com'
-- ON CONFLICT DO NOTHING;

-- ========================================
-- IF SCHOOLS ARE IN DATABASE BUT DASHBOARD SHOWS NOTHING
-- ========================================
-- This means the JavaScript is not getting data
-- Check these things in your JS code:

-- 1. Ensure supabase-client.js exists and has correct credentials
-- 2. Check that getSupabase() function is properly initialized
-- 3. Make sure auth.getSession() returns the current user
-- 4. Verify that the school query includes proper error handling
-- 5. Check browser console (F12) for JavaScript errors

-- ========================================
-- QUICK TEST: Insert sample data
-- ========================================

-- Get the first school's ID to use for students
-- SELECT id FROM schools LIMIT 1;

-- Then use that for students:
-- INSERT INTO students (school_id, name, gender, age)
-- VALUES (
--   'SCHOOL_ID_HERE'::UUID,
--   'John Doe',
--   'male',
--   15
-- );
