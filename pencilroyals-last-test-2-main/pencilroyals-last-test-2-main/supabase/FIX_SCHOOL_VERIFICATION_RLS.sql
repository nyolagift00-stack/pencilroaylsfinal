-- ========================================
-- FIX: School Verification RLS Policies
-- ========================================
-- Allows schools to insert and update their verification records

-- Drop old policies on school_verification table
DROP POLICY IF EXISTS "schools_view_own_verification" ON school_verification;
DROP POLICY IF EXISTS "schools_update_own_verification" ON school_verification;
DROP POLICY IF EXISTS "schools_insert_own_verification" ON school_verification;
DROP POLICY IF EXISTS "admin_view_all_verifications" ON school_verification;
DROP POLICY IF EXISTS "admin_update_verifications" ON school_verification;

-- Enable RLS if not already enabled
ALTER TABLE school_verification ENABLE ROW LEVEL SECURITY;

-- ========================================
-- SCHOOLS can INSERT their own verification (key fix!)
-- ========================================
CREATE POLICY "schools_insert_own_verification" ON school_verification
FOR INSERT
WITH CHECK (
    -- School can only insert if:
    -- 1. They are the one making the request (auth.uid() = user_id), AND
    -- 2. The school_id matches their own school
    auth.uid() = user_id
    AND school_id IN (SELECT id FROM schools WHERE user_id = auth.uid())
);

-- ========================================
-- SCHOOLS can UPDATE their own verification
-- ========================================
CREATE POLICY "schools_update_own_verification" ON school_verification
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ========================================
-- SCHOOLS can SELECT their own verification
-- ========================================
CREATE POLICY "schools_view_own_verification" ON school_verification
FOR SELECT
USING (auth.uid() = user_id);

-- ========================================
-- ADMIN can view all verifications
-- ========================================
CREATE POLICY "admin_view_all_verifications" ON school_verification
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- ========================================
-- ADMIN can update verifications (approve/reject)
-- ========================================
CREATE POLICY "admin_update_verifications" ON school_verification
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- ========================================
-- VERIFY THE FIX
-- ========================================
-- Run this to check policies:
-- SELECT schemaname, tablename, policyname, permissive, roles 
-- FROM pg_policies 
-- WHERE tablename = 'school_verification'
-- ORDER BY policyname;
