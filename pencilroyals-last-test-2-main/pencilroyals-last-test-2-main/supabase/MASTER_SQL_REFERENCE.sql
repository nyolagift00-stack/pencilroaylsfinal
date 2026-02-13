-- ========================================
-- PENCIL ROYAL - MASTER SQL REFERENCE
-- ========================================
-- All SQL commands you need in one place
-- Pick the section that matches your need

-- ========================================
-- OPTION 1: COMPLETE FRESH START
-- ========================================
-- Best if starting from scratch
-- File: supabase/COMPLETE_WORKING_SETUP.sql
-- Copy the ENTIRE file and run it once in your Supabase SQL Editor

-- ========================================
-- OPTION 2: FIX EXISTING DATABASE
-- ========================================
-- If you already have data and just need to fix user_roles

-- Create missing user_roles entries for existing schools
INSERT INTO user_roles (user_id, role, school_id)
SELECT s.user_id, 'school', s.id
FROM schools s
WHERE s.user_id NOT IN (SELECT user_id FROM user_roles)
ON CONFLICT DO NOTHING;

-- Verify the fix worked:
SELECT ur.user_id, ur.role, au.email, s.name
FROM user_roles ur
LEFT JOIN auth.users au ON ur.user_id = au.id
LEFT JOIN schools s ON ur.school_id = s.id
ORDER BY ur.created_at DESC;

-- ========================================
-- OPTION 3: SETUP ADMIN USER (ONE TIME)
-- ========================================
-- First create admin user in Supabase Auth UI
-- Then run this SQL with the admin's actual user ID

INSERT INTO user_roles (user_id, role)
VALUES ('PASTE_ADMIN_USER_ID_HERE'::UUID, 'admin');

-- Verify:
SELECT ur.user_id, ur.role, au.email
FROM user_roles ur
LEFT JOIN auth.users au ON ur.user_id = au.id
WHERE ur.role = 'admin';

-- ========================================
-- OPTION 4: SETUP SCHOOL USER (ONE TIME)
-- ========================================
-- First create school user in Supabase Auth UI
-- Then run this SQL

-- Create school entry
INSERT INTO schools (user_id, name, location, contact_person, phone)
VALUES (
  'PASTE_SCHOOL_USER_ID_HERE'::UUID,
  'Test School Name',
  'City, Country',
  'Principal Name',
  '+1234567890'
)
RETURNING id;

-- Use the returned ID (copy it) and run:
INSERT INTO user_roles (user_id, role, school_id)
VALUES (
  'PASTE_SCHOOL_USER_ID_HERE'::UUID,
  'school',
  'PASTE_SCHOOL_ID_HERE'::UUID
);

-- ========================================
-- OPTION 5: ADD SAMPLE DATA FOR TESTING
-- ========================================
-- Get a school ID first (run this):
SELECT id, name FROM schools LIMIT 1;

-- Then use the ID:
-- Add students to a school
INSERT INTO students (school_id, name, gender, age)
VALUES
  ('SCHOOL_ID_HERE'::UUID, 'John Doe', 'male', 15),
  ('SCHOOL_ID_HERE'::UUID, 'Jane Smith', 'female', 16),
  ('SCHOOL_ID_HERE'::UUID, 'Bob Johnson', 'male', 14),
  ('SCHOOL_ID_HERE'::UUID, 'Alice Williams', 'female', 15),
  ('SCHOOL_ID_HERE'::UUID, 'Charlie Brown', 'male', 16);

-- Create a competition
INSERT INTO competitions (name, type, status)
VALUES ('National Competition 2026', 'national', 'active')
RETURNING id;

-- Add competition scores (use the returned competition ID)
INSERT INTO competition_scores (competition_id, student_id, school_id, score, gender)
VALUES
  ('COMP_ID'::UUID, 'STUDENT_ID_1'::UUID, 'SCHOOL_ID'::UUID, 85, 'male'),
  ('COMP_ID'::UUID, 'STUDENT_ID_2'::UUID, 'SCHOOL_ID'::UUID, 92, 'female'),
  ('COMP_ID'::UUID, 'STUDENT_ID_3'::UUID, 'SCHOOL_ID'::UUID, 78, 'male');

-- ========================================
-- OPTION 6: DEBUG - Check Everything
-- ========================================

-- 1. See all auth users
SELECT id, email, created_at FROM auth.users LIMIT 10;

-- 2. See all user roles
SELECT ur.user_id, ur.role, ur.school_id, au.email, s.name as school_name
FROM user_roles ur
LEFT JOIN auth.users au ON ur.user_id = au.id
LEFT JOIN schools s ON ur.school_id = s.id
ORDER BY ur.role, au.email;

-- 3. See all schools with users
SELECT s.id, s.user_id, s.name, s.location, au.email
FROM schools s
LEFT JOIN auth.users au ON s.user_id = au.id
ORDER BY s.name;

-- 4. Count records in each table
SELECT 'schools' as table_name, COUNT(*) as count FROM schools
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
ORDER BY table_name;

-- 5. Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles
FROM pg_policies
WHERE tablename IN ('schools', 'students', 'competitions')
ORDER BY tablename, policyname;

-- 6. Test public read access (should work without auth)
SELECT id, name, location FROM schools LIMIT 5;

-- ========================================
-- OPTION 7: RESET/CLEANUP
-- ========================================
-- CAREFUL: This deletes all data!

-- Reset everything (drop all tables)
DROP TABLE IF EXISTS votes CASCADE;
DROP TABLE IF EXISTS results CASCADE;
DROP TABLE IF EXISTS finalists CASCADE;
DROP TABLE IF EXISTS competition_scores CASCADE;
DROP TABLE IF EXISTS competitions CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS schools CASCADE;
DROP TABLE IF EXISTS school_verification CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;

-- Then run COMPLETE_WORKING_SETUP.sql to rebuild

-- ========================================
-- OPTION 8: USEFUL QUERIES
-- ========================================

-- Get school with student count
SELECT 
  s.id, 
  s.name, 
  s.location, 
  COUNT(st.id) as student_count
FROM schools s
LEFT JOIN students st ON s.id = st.school_id
GROUP BY s.id, s.name, s.location
ORDER BY s.name;

-- Get top 10 students by average score
SELECT 
  st.name as student_name,
  s.name as school_name,
  st.gender,
  COUNT(cs.id) as competitions,
  AVG(cs.score) as avg_score
FROM students st
JOIN schools s ON st.school_id = s.id
LEFT JOIN competition_scores cs ON st.id = cs.student_id
GROUP BY st.id, st.name, s.name, st.gender
ORDER BY avg_score DESC
LIMIT 10;

-- Get competition results with rankings
SELECT 
  cs.rank,
  st.name as student_name,
  s.name as school_name,
  cs.gender,
  cs.score,
  cs.created_at
FROM competition_scores cs
JOIN students st ON cs.student_id = st.id
JOIN schools s ON cs.school_id = s.id
ORDER BY cs.rank ASC;

-- Get all finalists by school
SELECT 
  s.name as school_name,
  st.name as student_name,
  f.gender,
  f.score,
  f.status
FROM finalists f
JOIN students st ON f.student_id = st.id
JOIN schools s ON f.school_id = s.id
ORDER BY s.name, f.gender;

-- ========================================
-- OPTION 9: HELPER FUNCTION CALLS
-- ========================================
-- After running COMPLETE_WORKING_SETUP.sql, you can use these:

-- Get student counts for a school
SELECT * FROM get_student_counts('SCHOOL_ID_HERE'::UUID);

-- Get top 10 students overall
SELECT * FROM get_top_students(10);

-- Get top 5 students
SELECT * FROM get_top_students(5);

-- Get school profile with stats
SELECT * FROM get_school_profile('SCHOOL_ID_HERE'::UUID);

-- Get all schools with student counts
SELECT * FROM get_all_schools_summary();

-- Get finalists for a school
SELECT * FROM get_school_finalists('SCHOOL_ID_HERE'::UUID);

-- Get competition leaderboard
SELECT * FROM get_competition_leaderboard('COMPETITION_ID_HERE'::UUID);

-- ========================================
-- SUMMARY
-- ========================================
-- 
-- Step 1: Run COMPLETE_WORKING_SETUP.sql (one time)
-- Step 2: Setup Admin User with Option 3
-- Step 3: Setup Test School with Option 4
-- Step 4: Test login (should work now!)
-- Step 5: Add sample data with Option 5 if needed
-- Step 6: Use debug queries (Option 6) to verify
--
-- ========================================
