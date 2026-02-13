-- ========================================
-- PENCIL ROYAL - COMPLETE WORKING SETUP
-- ========================================
-- Run this ENTIRE file to reset and set up everything from scratch
-- This includes all tables, functions, policies, and ready-to-use queries

-- ========================================
-- STEP 1: DROP EVERYTHING (FRESH START)
-- ========================================
DROP TABLE IF EXISTS votes CASCADE;
DROP TABLE IF EXISTS results CASCADE;
DROP TABLE IF EXISTS finalists CASCADE;
DROP TABLE IF EXISTS competition_scores CASCADE;
DROP TABLE IF EXISTS competitions CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS schools CASCADE;
DROP TABLE IF EXISTS school_verification CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS org_assets CASCADE;
DROP TABLE IF EXISTS org_info CASCADE;

DROP FUNCTION IF EXISTS get_user_role CASCADE;
DROP FUNCTION IF EXISTS get_user_school CASCADE;
DROP FUNCTION IF EXISTS is_admin CASCADE;
DROP FUNCTION IF EXISTS owns_school CASCADE;
DROP FUNCTION IF EXISTS get_student_counts CASCADE;
DROP FUNCTION IF EXISTS get_top_students CASCADE;
DROP FUNCTION IF EXISTS get_school_finalists CASCADE;
DROP FUNCTION IF EXISTS get_school_profile CASCADE;
DROP FUNCTION IF EXISTS get_competition_leaderboard CASCADE;
DROP FUNCTION IF EXISTS get_all_schools_summary CASCADE;

-- ========================================
-- STEP 2: CREATE MAIN TABLES
-- ========================================

-- SCHOOLS TABLE
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    location TEXT,
    profile_pic TEXT,
    contact_person TEXT,
    phone TEXT,
    approved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_school_name CHECK (name != '')
);

-- STUDENTS TABLE
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    age INTEGER CHECK (age >= 5 AND age <= 30),
    profile_pic TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_student_name CHECK (name != '')
);

-- COMPETITIONS TABLE
CREATE TABLE competitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('internal', 'national')) DEFAULT 'internal',
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    status TEXT CHECK (status IN ('upcoming', 'active', 'completed')) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- COMPETITION SCORES TABLE
CREATE TABLE competition_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    score INTEGER CHECK (score >= 0 AND score <= 100),
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    rank INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- FINALISTS TABLE
CREATE TABLE finalists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    score INTEGER,
    status TEXT CHECK (status IN ('qualified', 'competing', 'finished')) DEFAULT 'qualified',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RESULTS TABLE
CREATE TABLE results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    competition_id UUID REFERENCES competitions(id) ON DELETE CASCADE,
    rank INTEGER,
    score INTEGER,
    total_students INTEGER,
    boys_count INTEGER,
    girls_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- VOTES TABLE
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    voter_id UUID,
    competition_id UUID REFERENCES competitions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_vote CHECK (voter_id IS NOT NULL)
);

-- USER ROLES TABLE (FOR ADMIN/SCHOOL DISTINCTION)
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('admin', 'school', 'user')),
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SCHOOL VERIFICATION TABLE
CREATE TABLE school_verification (
    id UUID PRIMARY KEY DEFAULT gen_random_UUID(),
    school_id UUID NOT NULL UNIQUE REFERENCES schools(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_id TEXT,
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- OPTIONAL: Organization Assets Table
CREATE TABLE org_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_type TEXT NOT NULL,
    original_filename TEXT,
    public_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- OPTIONAL: Organization Info Table
CREATE TABLE org_info (
    id INT PRIMARY KEY DEFAULT 1,
    about_text TEXT,
    mission_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- STEP 3: CREATE INDEXES
-- ========================================
CREATE INDEX idx_schools_user_id ON schools(user_id);
CREATE INDEX idx_schools_name ON schools(name);
CREATE INDEX idx_students_school_id ON students(school_id);
CREATE INDEX idx_students_gender ON students(gender);
CREATE INDEX idx_competitions_school_id ON competitions(school_id);
CREATE INDEX idx_competition_scores_competition_id ON competition_scores(competition_id);
CREATE INDEX idx_competition_scores_student_id ON competition_scores(student_id);
CREATE INDEX idx_competition_scores_school_id ON competition_scores(school_id);
CREATE INDEX idx_competition_scores_gender ON competition_scores(gender);
CREATE INDEX idx_finalists_competition_id ON finalists(competition_id);
CREATE INDEX idx_finalists_student_id ON finalists(student_id);
CREATE INDEX idx_finalists_school_id ON finalists(school_id);
CREATE INDEX idx_finalists_gender ON finalists(gender);
CREATE INDEX idx_results_school_id ON results(school_id);
CREATE INDEX idx_results_competition_id ON results(competition_id);
CREATE INDEX idx_votes_student_id ON votes(student_id);
CREATE INDEX idx_votes_competition_id ON votes(competition_id);
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);
CREATE INDEX idx_user_roles_school_id ON user_roles(school_id);
CREATE INDEX idx_school_verification_school_id ON school_verification(school_id);
CREATE INDEX idx_school_verification_user_id ON school_verification(user_id);

-- ========================================
-- STEP 4: CREATE HELPER FUNCTIONS
-- ========================================

-- Function to get user's role
CREATE OR REPLACE FUNCTION get_user_role(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_role TEXT;
BEGIN
    SELECT role INTO v_role FROM user_roles WHERE user_id = p_user_id LIMIT 1;
    RETURN COALESCE(v_role, 'user');
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get user's school_id
CREATE OR REPLACE FUNCTION get_user_school(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_school_id UUID;
BEGIN
    SELECT school_id INTO v_school_id FROM user_roles 
    WHERE user_id = p_user_id AND role = 'school' LIMIT 1;
    
    IF v_school_id IS NULL THEN
        SELECT id INTO v_school_id FROM schools WHERE user_id = p_user_id LIMIT 1;
    END IF;
    
    RETURN v_school_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT get_user_role(p_user_id) = 'admin');
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to check if user owns the school
CREATE OR REPLACE FUNCTION owns_school(p_user_id UUID, p_school_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM schools 
        WHERE id = p_school_id AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- ========================================
-- STEP 5: UTILITY FUNCTIONS
-- ========================================

CREATE OR REPLACE FUNCTION get_student_counts(p_school_id UUID)
RETURNS TABLE (
    total_students INTEGER,
    boys_count INTEGER,
    girls_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_students,
        COUNT(*) FILTER (WHERE gender = 'male')::INTEGER as boys_count,
        COUNT(*) FILTER (WHERE gender = 'female')::INTEGER as girls_count
    FROM students
    WHERE school_id = p_school_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_top_students(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    student_id UUID,
    student_name TEXT,
    school_id UUID,
    school_name TEXT,
    gender TEXT,
    avg_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.school_id,
        sch.name,
        s.gender,
        AVG(cs.score)::NUMERIC as avg_score
    FROM students s
    JOIN schools sch ON s.school_id = sch.id
    LEFT JOIN competition_scores cs ON s.id = cs.student_id
    GROUP BY s.id, s.name, s.school_id, sch.name, s.gender
    ORDER BY avg_score DESC NULLS LAST
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_school_finalists(p_school_id UUID)
RETURNS TABLE (
    student_id UUID,
    student_name TEXT,
    gender TEXT,
    score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.student_id,
        s.name,
        f.gender,
        f.score
    FROM finalists f
    JOIN students s ON f.student_id = s.id
    WHERE f.school_id = p_school_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_school_profile(p_school_id UUID)
RETURNS TABLE (
    school_id UUID,
    school_name TEXT,
    location TEXT,
    contact_person TEXT,
    phone TEXT,
    profile_pic TEXT,
    total_students INTEGER,
    boys_count INTEGER,
    girls_count INTEGER,
    approved BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.location,
        s.contact_person,
        s.phone,
        s.profile_pic,
        COUNT(st.id)::INTEGER,
        COUNT(st.id) FILTER (WHERE st.gender = 'male')::INTEGER,
        COUNT(st.id) FILTER (WHERE st.gender = 'female')::INTEGER,
        s.approved
    FROM schools s
    LEFT JOIN students st ON s.id = st.school_id
    WHERE s.id = p_school_id
    GROUP BY s.id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_competition_leaderboard(p_competition_id UUID)
RETURNS TABLE (
    rank INTEGER,
    student_name TEXT,
    school_name TEXT,
    gender TEXT,
    score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cs.rank,
        st.name,
        sch.name,
        cs.gender,
        cs.score
    FROM competition_scores cs
    JOIN students st ON cs.student_id = st.id
    JOIN schools sch ON cs.school_id = sch.id
    WHERE cs.competition_id = p_competition_id
    ORDER BY cs.rank ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_all_schools_summary()
RETURNS TABLE (
    school_id UUID,
    school_name TEXT,
    location TEXT,
    profile_pic TEXT,
    total_students INTEGER,
    boys_count INTEGER,
    girls_count INTEGER,
    approved BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.location,
        s.profile_pic,
        COUNT(st.id)::INTEGER,
        COUNT(st.id) FILTER (WHERE st.gender = 'male')::INTEGER,
        COUNT(st.id) FILTER (WHERE st.gender = 'female')::INTEGER,
        s.approved
    FROM schools s
    LEFT JOIN students st ON s.id = st.school_id
    GROUP BY s.id, s.name, s.location, s.profile_pic, s.approved
    ORDER BY s.name;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- STEP 6: ENABLE ROW LEVEL SECURITY
-- ========================================

ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE competition_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE finalists ENABLE ROW LEVEL SECURITY;
ALTER TABLE results ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_verification ENABLE ROW LEVEL SECURITY;

-- ========================================
-- STEP 7: DROP ALL OLD POLICIES (CLEAN SLATE)
-- ========================================

DROP POLICY IF EXISTS "admin_view_all_schools" ON schools;
DROP POLICY IF EXISTS "school_view_own_school" ON schools;
DROP POLICY IF EXISTS "school_update_own_school" ON schools;
DROP POLICY IF EXISTS "admin_update_any_school" ON schools;
DROP POLICY IF EXISTS "Allow public read access to schools" ON schools;
DROP POLICY IF EXISTS "Allow authenticated users to insert schools" ON schools;
DROP POLICY IF EXISTS "Allow users to update their own school" ON schools;
DROP POLICY IF EXISTS "Allow users to delete their own school" ON schools;
DROP POLICY IF EXISTS "public_read_approved_schools" ON schools;
DROP POLICY IF EXISTS "public_read_all_schools" ON schools;
DROP POLICY IF EXISTS "public_read_schools" ON schools;
DROP POLICY IF EXISTS "authenticated_insert_school" ON schools;
DROP POLICY IF EXISTS "authenticated_update_own_school" ON schools;
DROP POLICY IF EXISTS "authenticated_delete_own_school" ON schools;

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
DROP POLICY IF EXISTS "public_read_students" ON students;
DROP POLICY IF EXISTS "school_manage_students" ON students;
DROP POLICY IF EXISTS "school_update_students" ON students;
DROP POLICY IF EXISTS "school_delete_students" ON students;

DROP POLICY IF EXISTS "admin_view_all_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_insert_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_update_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_delete_competitions" ON competitions;
DROP POLICY IF EXISTS "view_active_competitions" ON competitions;
DROP POLICY IF EXISTS "public_read_competitions" ON competitions;

DROP POLICY IF EXISTS "admin_view_all_scores" ON competition_scores;
DROP POLICY IF EXISTS "school_view_own_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_insert_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_update_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_delete_scores" ON competition_scores;
DROP POLICY IF EXISTS "Scores are viewable by all" ON competition_scores;
DROP POLICY IF EXISTS "School owner can manage scores" ON competition_scores;
DROP POLICY IF EXISTS "public_read_scores" ON competition_scores;

DROP POLICY IF EXISTS "admin_view_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_insert_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_update_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_delete_finalists" ON finalists;
DROP POLICY IF EXISTS "view_finalists" ON finalists;
DROP POLICY IF EXISTS "Finalists are viewable by all" ON finalists;
DROP POLICY IF EXISTS "Allow public read access to finalists" ON finalists;

DROP POLICY IF EXISTS "admin_view_results" ON results;
DROP POLICY IF EXISTS "admin_insert_results" ON results;
DROP POLICY IF EXISTS "admin_update_results" ON results;
DROP POLICY IF EXISTS "admin_delete_results" ON results;
DROP POLICY IF EXISTS "view_results" ON results;

DROP POLICY IF EXISTS "view_votes" ON votes;
DROP POLICY IF EXISTS "admin_view_votes" ON votes;
DROP POLICY IF EXISTS "admin_insert_votes" ON votes;
DROP POLICY IF EXISTS "admin_update_votes" ON votes;
DROP POLICY IF EXISTS "admin_delete_votes" ON votes;

DROP POLICY IF EXISTS "users_view_own_role" ON user_roles;
DROP POLICY IF EXISTS "admin_view_all_roles" ON user_roles;
DROP POLICY IF EXISTS "admin_insert_roles" ON user_roles;
DROP POLICY IF EXISTS "admin_update_roles" ON user_roles;
DROP POLICY IF EXISTS "admin_delete_roles" ON user_roles;

DROP POLICY IF EXISTS "schools_view_own_verification" ON school_verification;
DROP POLICY IF EXISTS "schools_update_own_verification" ON school_verification;
DROP POLICY IF EXISTS "schools_insert_own_verification" ON school_verification;
DROP POLICY IF EXISTS "admin_view_all_verifications" ON school_verification;
DROP POLICY IF EXISTS "admin_update_verifications" ON school_verification;

-- ========================================
-- STEP 8: CREATE NEW CLEAN POLICIES - SCHOOLS
-- ========================================

-- Public can read all schools
CREATE POLICY "public_read_schools" ON schools
FOR SELECT USING (true);

-- Authenticated users can insert their own school
CREATE POLICY "users_insert_school" ON schools
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own school
CREATE POLICY "users_update_school" ON schools
FOR UPDATE USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Users can delete their own school
CREATE POLICY "users_delete_school" ON schools
FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- STEP 9: CREATE NEW CLEAN POLICIES - STUDENTS
-- ========================================

-- Public can read all students
CREATE POLICY "public_read_students" ON students
FOR SELECT USING (true);

-- Authenticated users can insert students in their school
CREATE POLICY "users_insert_students" ON students
FOR INSERT WITH CHECK (
    school_id IN (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Authenticated users can update students in their school
CREATE POLICY "users_update_students" ON students
FOR UPDATE USING (
    school_id IN (SELECT id FROM schools WHERE user_id = auth.uid())
)
WITH CHECK (
    school_id IN (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Authenticated users can delete students in their school
CREATE POLICY "users_delete_students" ON students
FOR DELETE USING (
    school_id IN (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- ========================================
-- STEP 10: CREATE NEW CLEAN POLICIES - OTHER TABLES
-- ========================================

-- PUBLIC can read all competitions
CREATE POLICY "public_read_competitions" ON competitions
FOR SELECT USING (true);

-- PUBLIC can read all competition scores
CREATE POLICY "public_read_scores" ON competition_scores
FOR SELECT USING (true);

-- PUBLIC can read all finalists
CREATE POLICY "public_read_finalists" ON finalists
FOR SELECT USING (true);

-- PUBLIC can read all results
CREATE POLICY "public_read_results" ON results
FOR SELECT USING (true);

-- PUBLIC can read all votes
CREATE POLICY "public_read_votes" ON votes
FOR SELECT USING (true);

-- Users can view their own role
CREATE POLICY "users_view_own_role" ON user_roles
FOR SELECT USING (auth.uid() = user_id);

-- Schools can view their own verification
CREATE POLICY "schools_view_verification" ON school_verification
FOR SELECT USING (auth.uid() = user_id);

-- ========================================
-- STEP 11: HELPFUL DEBUGGING QUERIES
-- ========================================

-- Query 1: See all users and their roles
-- SELECT ur.user_id, ur.role, ur.school_id, au.email, s.name as school_name
-- FROM user_roles ur
-- LEFT JOIN auth.users au ON ur.user_id = au.id
-- LEFT JOIN schools s ON ur.school_id = s.id
-- ORDER BY ur.role, au.email;

-- Query 2: See all schools
-- SELECT id, user_id, name, location, approved FROM schools ORDER BY name;

-- Query 3: See all students with their school
-- SELECT s.id, s.name, s.gender, sch.name as school_name 
-- FROM students s
-- JOIN schools sch ON s.school_id = sch.id
-- ORDER BY sch.name, s.name;

-- Query 4: See all competitions
-- SELECT id, name, type, status FROM competitions ORDER BY created_at DESC;

-- Query 5: See competition scores with student and school names
-- SELECT cs.id, st.name as student, sch.name as school, cs.score, cs.rank
-- FROM competition_scores cs
-- JOIN students st ON cs.student_id = st.id
-- JOIN schools sch ON cs.school_id = sch.id
-- ORDER BY cs.score DESC;

-- Query 6: See finalists
-- SELECT f.id, st.name as student, sch.name as school, f.gender, f.score
-- FROM finalists f
-- JOIN students st ON f.student_id = st.id
-- JOIN schools sch ON f.school_id = sch.id
-- ORDER BY sch.name;

-- ========================================
-- STEP 12: HOW TO SET UP ADMIN USERS
-- ========================================

-- AFTER creating an admin user in Supabase Auth, run this:
-- INSERT INTO user_roles (user_id, role)
-- SELECT id, 'admin' FROM auth.users WHERE email = 'admin@pencilroyal.com'
-- ON CONFLICT DO NOTHING;

-- ========================================
-- STEP 13: HOW TO LINK SCHOOL TO USER
-- ========================================

-- AFTER a school registers, run this to create the user_roles entry:
-- INSERT INTO user_roles (user_id, role, school_id)
-- SELECT s.user_id, 'school', s.id FROM schools s
-- WHERE s.user_id = 'USER_ID_HERE' AND NOT EXISTS (
--     SELECT 1 FROM user_roles WHERE user_id = s.user_id
-- );

-- ========================================
-- SETUP COMPLETE
-- ========================================
-- Your database is now ready!
-- - All tables created ✓
-- - All functions created ✓
-- - RLS enabled with public read policies ✓
-- - Ready for login/authentication ✓
