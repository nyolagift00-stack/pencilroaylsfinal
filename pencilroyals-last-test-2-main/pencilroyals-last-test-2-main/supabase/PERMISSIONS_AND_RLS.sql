-- ========================================
-- PENCIL ROYAL - PERMISSIONS & ROW LEVEL SECURITY
-- ========================================
-- This file sets up role-based permissions and RLS policies
-- to properly control admin and school access

-- ========================================
-- 1. SCHOOL VERIFICATION TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS school_verification (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL UNIQUE REFERENCES schools(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_id TEXT,
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_verification_school_id ON school_verification(school_id);
CREATE INDEX IF NOT EXISTS idx_verification_user_id ON school_verification(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_status ON school_verification(verification_status);

-- ========================================
-- 2. USER ROLES TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('admin', 'school', 'user')),
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);
CREATE INDEX IF NOT EXISTS idx_user_roles_school_id ON user_roles(school_id);

-- ========================================
-- 2. HELPER FUNCTIONS FOR PERMISSIONS
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
    -- If user is a school, return their school_id from user_roles
    SELECT school_id INTO v_school_id FROM user_roles 
    WHERE user_id = p_user_id AND role = 'school' LIMIT 1;
    
    -- If not found, try to get it from schools table
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
-- 3. ENABLE ROW LEVEL SECURITY ON ALL TABLES
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
-- 4. SCHOOLS TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "admin_view_all_schools" ON schools;
DROP POLICY IF EXISTS "school_view_own_school" ON schools;
DROP POLICY IF EXISTS "school_update_own_school" ON schools;
DROP POLICY IF EXISTS "admin_update_any_school" ON schools;

-- Admin can view all schools
CREATE POLICY "admin_view_all_schools" ON schools
FOR SELECT USING (is_admin(auth.uid()));

-- Schools can view only their own school
CREATE POLICY "school_view_own_school" ON schools
FOR SELECT USING (auth.uid() = user_id);

-- Schools can update only their own school
CREATE POLICY "school_update_own_school" ON schools
FOR UPDATE USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id AND id = (SELECT id FROM schools WHERE user_id = auth.uid()));

-- Admin can update any school
CREATE POLICY "admin_update_any_school" ON schools
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- ========================================
-- 5. STUDENTS TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "admin_view_all_students" ON students;
DROP POLICY IF EXISTS "school_view_own_students" ON students;
DROP POLICY IF EXISTS "school_add_students" ON students;
DROP POLICY IF EXISTS "school_update_own_students" ON students;
DROP POLICY IF EXISTS "school_delete_own_students" ON students;
DROP POLICY IF EXISTS "admin_insert_students" ON students;
DROP POLICY IF EXISTS "admin_update_students" ON students;
DROP POLICY IF EXISTS "admin_delete_students" ON students;

-- Admin can view all students
CREATE POLICY "admin_view_all_students" ON students
FOR SELECT USING (is_admin(auth.uid()));

-- Schools can view only their own students
CREATE POLICY "school_view_own_students" ON students
FOR SELECT USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Schools can insert students (add new students)
CREATE POLICY "school_add_students" ON students
FOR INSERT WITH CHECK (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Schools can update their own students
CREATE POLICY "school_update_own_students" ON students
FOR UPDATE USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
) WITH CHECK (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Schools can delete their own students
CREATE POLICY "school_delete_own_students" ON students
FOR DELETE USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Admin can insert students
CREATE POLICY "admin_insert_students" ON students
FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Admin can update students
CREATE POLICY "admin_update_students" ON students
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- Admin can delete students
CREATE POLICY "admin_delete_students" ON students
FOR DELETE USING (is_admin(auth.uid()));

-- ========================================
-- 6. COMPETITIONS TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "admin_view_all_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_insert_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_update_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_delete_competitions" ON competitions;
DROP POLICY IF EXISTS "view_active_competitions" ON competitions;

-- Admin can view all competitions
CREATE POLICY "admin_view_all_competitions" ON competitions
FOR SELECT USING (is_admin(auth.uid()));

-- Admin can insert competitions
CREATE POLICY "admin_insert_competitions" ON competitions
FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Admin can update competitions
CREATE POLICY "admin_update_competitions" ON competitions
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- Admin can delete competitions
CREATE POLICY "admin_delete_competitions" ON competitions
FOR DELETE USING (is_admin(auth.uid()));

-- Everyone can view active competitions
CREATE POLICY "view_active_competitions" ON competitions
FOR SELECT USING (status = 'active' OR status = 'completed');

-- ========================================
-- 7. COMPETITION_SCORES TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "admin_view_all_scores" ON competition_scores;
DROP POLICY IF EXISTS "school_view_own_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_insert_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_update_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_delete_scores" ON competition_scores;

-- Admin can view all scores
CREATE POLICY "admin_view_all_scores" ON competition_scores
FOR SELECT USING (is_admin(auth.uid()));

-- Schools can view scores for their own students
CREATE POLICY "school_view_own_scores" ON competition_scores
FOR SELECT USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Admin can insert competition scores
CREATE POLICY "admin_insert_scores" ON competition_scores
FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Admin can update competition scores
CREATE POLICY "admin_update_scores" ON competition_scores
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- Admin can delete competition scores
CREATE POLICY "admin_delete_scores" ON competition_scores
FOR DELETE USING (is_admin(auth.uid()));

-- ========================================
-- 8. FINALISTS TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "admin_view_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_insert_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_update_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_delete_finalists" ON finalists;
DROP POLICY IF EXISTS "view_finalists" ON finalists;

-- Admin can view finalists
CREATE POLICY "admin_view_finalists" ON finalists
FOR SELECT USING (is_admin(auth.uid()));

-- Admin can insert finalists
CREATE POLICY "admin_insert_finalists" ON finalists
FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Admin can update finalists
CREATE POLICY "admin_update_finalists" ON finalists
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- Admin can delete finalists
CREATE POLICY "admin_delete_finalists" ON finalists
FOR DELETE USING (is_admin(auth.uid()));

-- Everyone can view finalists
CREATE POLICY "view_finalists" ON finalists
FOR SELECT USING (true);

-- ========================================
-- 9. RESULTS TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "admin_view_results" ON results;
DROP POLICY IF EXISTS "admin_insert_results" ON results;
DROP POLICY IF EXISTS "admin_update_results" ON results;
DROP POLICY IF EXISTS "admin_delete_results" ON results;
DROP POLICY IF EXISTS "view_results" ON results;

-- Admin can view results
CREATE POLICY "admin_view_results" ON results
FOR SELECT USING (is_admin(auth.uid()));

-- Admin can insert results
CREATE POLICY "admin_insert_results" ON results
FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Admin can update results
CREATE POLICY "admin_update_results" ON results
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- Admin can delete results
CREATE POLICY "admin_delete_results" ON results
FOR DELETE USING (is_admin(auth.uid()));

-- Everyone can view results
CREATE POLICY "view_results" ON results
FOR SELECT USING (true);

-- ========================================
-- 10. VOTES TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "view_votes" ON votes;
DROP POLICY IF EXISTS "admin_view_votes" ON votes;
DROP POLICY IF EXISTS "admin_insert_votes" ON votes;
DROP POLICY IF EXISTS "admin_update_votes" ON votes;
DROP POLICY IF EXISTS "admin_delete_votes" ON votes;

-- Everyone can view votes
CREATE POLICY "view_votes" ON votes
FOR SELECT USING (true);

-- Admin can view votes
CREATE POLICY "admin_view_votes" ON votes
FOR SELECT USING (is_admin(auth.uid()));

-- Admin can insert votes
CREATE POLICY "admin_insert_votes" ON votes
FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Admin can update votes
CREATE POLICY "admin_update_votes" ON votes
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- Admin can delete votes
CREATE POLICY "admin_delete_votes" ON votes
FOR DELETE USING (is_admin(auth.uid()));

-- ========================================
-- 11. USER_ROLES TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "users_view_own_role" ON user_roles;
DROP POLICY IF EXISTS "admin_view_all_roles" ON user_roles;
DROP POLICY IF EXISTS "admin_insert_roles" ON user_roles;
DROP POLICY IF EXISTS "admin_update_roles" ON user_roles;
DROP POLICY IF EXISTS "admin_delete_roles" ON user_roles;

-- Users can view their own role
CREATE POLICY "users_view_own_role" ON user_roles
FOR SELECT USING (auth.uid() = user_id);

-- Admin can view all roles
CREATE POLICY "admin_view_all_roles" ON user_roles
FOR SELECT USING (is_admin(auth.uid()));

-- Admin can insert roles
CREATE POLICY "admin_insert_roles" ON user_roles
FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Admin can update roles
CREATE POLICY "admin_update_roles" ON user_roles
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- Admin can delete roles
CREATE POLICY "admin_delete_roles" ON user_roles
FOR DELETE USING (is_admin(auth.uid()));

-- ========================================
-- 12. SCHOOL_VERIFICATION TABLE RLS POLICIES
-- ========================================

-- Drop old policies if they exist
DROP POLICY IF EXISTS "schools_view_own_verification" ON school_verification;
DROP POLICY IF EXISTS "schools_update_own_verification" ON school_verification;
DROP POLICY IF EXISTS "admin_view_all_verifications" ON school_verification;
DROP POLICY IF EXISTS "admin_update_verifications" ON school_verification;

-- Schools can view their own verification status
CREATE POLICY "schools_view_own_verification" ON school_verification
FOR SELECT USING (auth.uid() = user_id);

-- Schools can update their own verification (submit transaction ID)
CREATE POLICY "schools_update_own_verification" ON school_verification
FOR UPDATE USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Admin can view all verifications
CREATE POLICY "admin_view_all_verifications" ON school_verification
FOR SELECT USING (is_admin(auth.uid()));

-- Admin can update verification status (approve/reject)
CREATE POLICY "admin_update_verifications" ON school_verification
FOR UPDATE USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

-- ========================================
-- 13. SETUP ADMIN USERS (RUN AFTER ADDING AUTH USERS)
-- ========================================
-- Example: Insert admin roles for your admin emails
-- You need to find the user_id from auth.users table first

-- INSERT INTO user_roles (user_id, role)
-- SELECT id, 'admin'
-- FROM auth.users
-- WHERE email IN ('admin@pencilroyal.com', 'admin@test.com', 'ss@gmail.com')
-- ON CONFLICT DO NOTHING;

-- ========================================
-- 14. HELPFUL QUERIES
-- ========================================

-- View all users and their roles
-- SELECT ur.user_id, ur.role, ur.school_id, au.email, s.name as school_name
-- FROM user_roles ur
-- LEFT JOIN auth.users au ON ur.user_id = au.id
-- LEFT JOIN schools s ON ur.school_id = s.id
-- ORDER BY ur.role, au.email;

-- Check a specific user's permissions
-- SELECT 
--     au.email,
--     ur.role,
--     s.name as school_name,
--     get_user_role(au.id) as calculated_role,
--     get_user_school(au.id) as calculated_school_id,
--     is_admin(au.id) as is_admin
-- FROM auth.users au
-- LEFT JOIN user_roles ur ON au.id = ur.user_id
-- LEFT JOIN schools s ON ur.school_id = s.id
-- WHERE au.email = 'YOUR_EMAIL_HERE';

-- View all pending verification requests
-- SELECT sv.id, sv.school_id, s.name, s.user_id, sv.transaction_id, sv.verification_status, sv.created_at
-- FROM school_verification sv
-- LEFT JOIN schools s ON sv.school_id = s.id
-- WHERE sv.verification_status = 'pending'
-- ORDER BY sv.created_at DESC;
