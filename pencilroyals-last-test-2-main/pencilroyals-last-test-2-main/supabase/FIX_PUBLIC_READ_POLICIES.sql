-- ========================================
-- QUICK FIX: Enable Public Read Access to Schools
-- ========================================
-- Run this if you see "No approved schools yet" but schools exist in database

-- Drop ALL restrictive school policies that block public access
DROP POLICY IF EXISTS "admin_view_all_schools" ON schools;
DROP POLICY IF EXISTS "school_view_own_school" ON schools;
DROP POLICY IF EXISTS "school_update_own_school" ON schools;
DROP POLICY IF EXISTS "admin_update_any_school" ON schools;
DROP POLICY IF EXISTS "public_read_approved_schools" ON schools;
DROP POLICY IF EXISTS "public_read_all_schools" ON schools;
DROP POLICY IF EXISTS "users_view_own_school" ON schools;
DROP POLICY IF EXISTS "Users can view own school" ON schools;
DROP POLICY IF EXISTS "Users can create school" ON schools;
DROP POLICY IF EXISTS "Users can update own school" ON schools;

-- Make sure RLS is enabled
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;

-- CREATE ONE CLEAR PUBLIC READ POLICY (anyone can see all schools)
CREATE POLICY "public_read_schools" ON schools
FOR SELECT USING (true);

-- Allow authenticated users to insert their own school
CREATE POLICY "authenticated_insert_school" ON schools
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to update their own school
CREATE POLICY "authenticated_update_own_school" ON schools
FOR UPDATE USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to delete their own school
CREATE POLICY "authenticated_delete_own_school" ON schools
FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- Also fix Students, Finalists, Results, Votes
-- ========================================

-- Drop all students policies
DROP POLICY IF EXISTS "admin_view_all_students" ON students;
DROP POLICY IF EXISTS "school_view_own_students" ON students;
DROP POLICY IF EXISTS "school_add_students" ON students;
DROP POLICY IF EXISTS "school_update_own_students" ON students;
DROP POLICY IF EXISTS "school_delete_own_students" ON students;
DROP POLICY IF EXISTS "admin_insert_students" ON students;
DROP POLICY IF EXISTS "admin_update_students" ON students;
DROP POLICY IF EXISTS "admin_delete_students" ON students;
DROP POLICY IF EXISTS "Students are viewable by all" ON students;
DROP POLICY IF EXISTS "School owner can manage students" ON students;
DROP POLICY IF EXISTS "School owner can update students" ON students;
DROP POLICY IF EXISTS "School owner can delete students" ON students;
DROP POLICY IF EXISTS "Allow public read access to students" ON students;

ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- PUBLIC can read all students
CREATE POLICY "public_read_students" ON students
FOR SELECT USING (true);

-- School owner can manage their students
CREATE POLICY "school_manage_students" ON students
FOR INSERT WITH CHECK (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

CREATE POLICY "school_update_students" ON students
FOR UPDATE USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
) WITH CHECK (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

CREATE POLICY "school_delete_students" ON students
FOR DELETE USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Drop all finalists policies
DROP POLICY IF EXISTS "admin_view_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_insert_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_update_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_delete_finalists" ON finalists;
DROP POLICY IF EXISTS "view_finalists" ON finalists;
DROP POLICY IF EXISTS "Finalists are viewable by all" ON finalists;
DROP POLICY IF EXISTS "Allow public read access to finalists" ON finalists;

ALTER TABLE finalists ENABLE ROW LEVEL SECURITY;

-- PUBLIC can read all finalists
CREATE POLICY "public_read_finalists" ON finalists
FOR SELECT USING (true);

-- Drop all results policies
DROP POLICY IF EXISTS "admin_view_results" ON results;
DROP POLICY IF EXISTS "admin_insert_results" ON results;
DROP POLICY IF EXISTS "admin_update_results" ON results;
DROP POLICY IF EXISTS "admin_delete_results" ON results;
DROP POLICY IF EXISTS "view_results" ON results;

ALTER TABLE results ENABLE ROW LEVEL SECURITY;

-- PUBLIC can read all results
CREATE POLICY "public_read_results" ON results
FOR SELECT USING (true);

-- Drop all votes policies
DROP POLICY IF EXISTS "view_votes" ON votes;
DROP POLICY IF EXISTS "admin_view_votes" ON votes;
DROP POLICY IF EXISTS "admin_insert_votes" ON votes;
DROP POLICY IF EXISTS "admin_update_votes" ON votes;
DROP POLICY IF EXISTS "admin_delete_votes" ON votes;

ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- PUBLIC can read all votes
CREATE POLICY "public_read_votes" ON votes
FOR SELECT USING (true);

-- ========================================
-- Drop all competition policies
-- ========================================
DROP POLICY IF EXISTS "admin_view_all_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_insert_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_update_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_delete_competitions" ON competitions;
DROP POLICY IF EXISTS "view_active_competitions" ON competitions;

ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;

-- PUBLIC can read all competitions
CREATE POLICY "public_read_competitions" ON competitions
FOR SELECT USING (true);

-- Drop all competition_scores policies
DROP POLICY IF EXISTS "admin_view_all_scores" ON competition_scores;
DROP POLICY IF EXISTS "school_view_own_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_insert_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_update_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_delete_scores" ON competition_scores;
DROP POLICY IF EXISTS "Scores are viewable by all" ON competition_scores;
DROP POLICY IF EXISTS "School owner can manage scores" ON competition_scores;

ALTER TABLE competition_scores ENABLE ROW LEVEL SECURITY;

-- PUBLIC can read all scores
CREATE POLICY "public_read_scores" ON competition_scores
FOR SELECT USING (true);

-- ========================================
-- VERIFY THE FIX
-- ========================================
-- After running this, test with this query in Supabase:
-- SELECT id, name, location FROM schools LIMIT 5;
-- You should see your schools now!
