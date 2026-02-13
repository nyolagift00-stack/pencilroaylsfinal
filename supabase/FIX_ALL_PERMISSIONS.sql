-- ========================================
-- PENCIL ROYAL - CONSOLIDATED PERMISSIONS & RLS FIX
-- ========================================
-- Purpose: Ensure necessary columns exist and restore safe RLS policies
-- so public users can read approved schools while admins and owners
-- retain the ability to manage data.
-- Run this in the Supabase SQL editor (as a project owner).

-- 0) Safety: run inside a transaction if you prefer
BEGIN;

-- 1) Ensure schema fields exist
ALTER TABLE IF EXISTS schools
  ADD COLUMN IF NOT EXISTS approved BOOLEAN DEFAULT false;

ALTER TABLE IF EXISTS schools
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE IF EXISTS students
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2) Helper tables used by permissions (create if missing)
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('admin', 'school', 'user')),
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

-- 3) Permission helper functions (idempotent)
CREATE OR REPLACE FUNCTION get_user_role(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE v_role TEXT;
BEGIN
    SELECT role INTO v_role FROM user_roles WHERE user_id = p_user_id LIMIT 1;
    RETURN COALESCE(v_role, 'user');
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION get_user_school(p_user_id UUID)
RETURNS UUID AS $$
DECLARE v_school_id UUID;
BEGIN
    SELECT school_id INTO v_school_id FROM user_roles WHERE user_id = p_user_id AND role = 'school' LIMIT 1;
    IF v_school_id IS NULL THEN
        SELECT id INTO v_school_id FROM schools WHERE user_id = p_user_id LIMIT 1;
    END IF;
    RETURN v_school_id;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION is_admin(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT get_user_role(p_user_id) = 'admin');
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION owns_school(p_user_id UUID, p_school_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM schools WHERE id = p_school_id AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- 4) Ensure Row Level Security is enabled on tables we manage
ALTER TABLE IF EXISTS schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS students ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS competition_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS finalists ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS results ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS school_verification ENABLE ROW LEVEL SECURITY;

-- 5) SCHOOLS: drop conflicting policies and create clear policies
DROP POLICY IF EXISTS public_read_all_schools ON schools;
DROP POLICY IF EXISTS public_read_approved_schools ON schools;
DROP POLICY IF EXISTS admin_view_all_schools ON schools;
DROP POLICY IF EXISTS school_view_own_school ON schools;
DROP POLICY IF EXISTS school_update_own_school ON schools;
DROP POLICY IF EXISTS admin_update_any_school ON schools;

-- Public users (anonymous or authenticated) can SELECT schools only if approved = true
CREATE POLICY public_read_approved_schools ON schools
  FOR SELECT USING (approved = true);

-- Admins can view all schools
CREATE POLICY admin_view_all_schools ON schools
  FOR SELECT USING (is_admin(auth.uid()));

-- School owners can view their own school
CREATE POLICY school_view_own_school ON schools
  FOR SELECT USING (auth.uid() = user_id);

-- School owners can update their own school
CREATE POLICY school_update_own_school ON schools
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id AND id = (SELECT id FROM schools WHERE user_id = auth.uid()));

-- Admins can update any school
CREATE POLICY admin_update_any_school ON schools
  FOR UPDATE USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid())); 

-- Allow authenticated users to insert a school record for themselves
DROP POLICY IF EXISTS authenticated_insert_school ON schools;
CREATE POLICY authenticated_insert_school ON schools
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6) STUDENTS: ensure admins and owning schools behave correctly
DROP POLICY IF EXISTS public_read_students ON students;
DROP POLICY IF EXISTS admin_view_all_students ON students;
DROP POLICY IF EXISTS school_view_own_students ON students;
DROP POLICY IF EXISTS school_add_students ON students;
DROP POLICY IF EXISTS school_update_own_students ON students;
DROP POLICY IF EXISTS school_delete_own_students ON students;

-- Admins can view all students
CREATE POLICY admin_view_all_students ON students
  FOR SELECT USING (is_admin(auth.uid()));

-- Schools can view their own students
CREATE POLICY school_view_own_students ON students
  FOR SELECT USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Schools can insert students for their school
CREATE POLICY school_add_students ON students
  FOR INSERT WITH CHECK (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Schools can update/delete their own students
CREATE POLICY school_update_own_students ON students
  FOR UPDATE USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
) WITH CHECK (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

CREATE POLICY school_delete_own_students ON students
  FOR DELETE USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- Admin management policies for students
CREATE POLICY admin_insert_students ON students
  FOR INSERT WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_update_students ON students
  FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_delete_students ON students
  FOR DELETE USING (is_admin(auth.uid()));

-- 7) COMPETITIONS
DROP POLICY IF EXISTS view_active_competitions ON competitions;
DROP POLICY IF EXISTS admin_view_all_competitions ON competitions;
DROP POLICY IF EXISTS admin_insert_competitions ON competitions;
DROP POLICY IF EXISTS admin_update_competitions ON competitions;
DROP POLICY IF EXISTS admin_delete_competitions ON competitions;

CREATE POLICY admin_view_all_competitions ON competitions
  FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY admin_insert_competitions ON competitions
  FOR INSERT WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_update_competitions ON competitions
  FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_delete_competitions ON competitions
  FOR DELETE USING (is_admin(auth.uid()));

-- Everyone can view active/completed competitions
CREATE POLICY view_active_competitions ON competitions
  FOR SELECT USING (status = 'active' OR status = 'completed');

-- 8) COMPETITION_SCORES
DROP POLICY IF EXISTS public_read_scores ON competition_scores;
DROP POLICY IF EXISTS admin_view_all_scores ON competition_scores;
DROP POLICY IF EXISTS school_view_own_scores ON competition_scores;

CREATE POLICY admin_view_all_scores ON competition_scores
  FOR SELECT USING (is_admin(auth.uid()));

CREATE POLICY school_view_own_scores ON competition_scores
  FOR SELECT USING (
    school_id = (SELECT id FROM schools WHERE user_id = auth.uid())
);

CREATE POLICY admin_insert_scores ON competition_scores
  FOR INSERT WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_update_scores ON competition_scores
  FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_delete_scores ON competition_scores
  FOR DELETE USING (is_admin(auth.uid()));

-- 9) FINALISTS (public viewable)
DROP POLICY IF EXISTS view_finalists ON finalists;
CREATE POLICY view_finalists ON finalists
  FOR SELECT USING (true);

CREATE POLICY admin_view_finalists ON finalists
  FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY admin_insert_finalists ON finalists
  FOR INSERT WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_update_finalists ON finalists
  FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_delete_finalists ON finalists
  FOR DELETE USING (is_admin(auth.uid()));

-- 10) RESULTS (public viewable)
DROP POLICY IF EXISTS view_results ON results;
CREATE POLICY view_results ON results
  FOR SELECT USING (true);

CREATE POLICY admin_view_results ON results
  FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY admin_insert_results ON results
  FOR INSERT WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_update_results ON results
  FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_delete_results ON results
  FOR DELETE USING (is_admin(auth.uid()));

-- 11) VOTES (public viewable for counts but restrict inserts)
DROP POLICY IF EXISTS view_votes ON votes;
CREATE POLICY view_votes ON votes
  FOR SELECT USING (true);

CREATE POLICY admin_view_votes ON votes
  FOR SELECT USING (is_admin(auth.uid()));

CREATE POLICY admin_insert_votes ON votes
  FOR INSERT WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_update_votes ON votes
  FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_delete_votes ON votes
  FOR DELETE USING (is_admin(auth.uid()));

-- 12) USER_ROLES & SCHOOL_VERIFICATION policies
DROP POLICY IF EXISTS users_view_own_role ON user_roles;
CREATE POLICY users_view_own_role ON user_roles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY admin_view_all_roles ON user_roles FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY admin_insert_roles ON user_roles FOR INSERT WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_update_roles ON user_roles FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));
CREATE POLICY admin_delete_roles ON user_roles FOR DELETE USING (is_admin(auth.uid()));

DROP POLICY IF EXISTS schools_view_own_verification ON school_verification;
DROP POLICY IF EXISTS schools_update_own_verification ON school_verification;
DROP POLICY IF EXISTS admin_view_all_verifications ON school_verification;
DROP POLICY IF EXISTS admin_update_verifications ON school_verification;

CREATE POLICY schools_view_own_verification ON school_verification FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY schools_update_own_verification ON school_verification FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY admin_view_all_verifications ON school_verification FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY admin_update_verifications ON school_verification FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));

-- 13) Finalize
COMMIT;

-- ========================================
-- VERIFICATION QUERY (run after applying):
-- SELECT id, name, approved FROM schools ORDER BY created_at DESC LIMIT 50;
-- If you want to mark existing schools approved (careful):
-- UPDATE schools SET approved = true WHERE approved IS DISTINCT FROM true;
-- ========================================
-- Notes:
-- - This script keeps admin and owner protections intact while allowing
--   public SELECT of schools only when `approved = true`.
-- - If you prefer public visibility of ALL schools, change the policy
--   "public_read_approved_schools" to: FOR SELECT USING (true);
-- - Run the verification query then test from the frontend.
-- ========================================
