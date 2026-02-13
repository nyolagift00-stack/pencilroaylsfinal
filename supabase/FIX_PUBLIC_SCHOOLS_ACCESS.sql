-- ========================================
-- FIX PUBLIC ACCESS TO SCHOOLS
-- ========================================
-- This fixes the issue where public users can't see schools
-- because RLS policies were too restrictive

-- Drop the old restrictive policy that blocks public access
DROP POLICY IF EXISTS "public_read_approved_schools" ON schools;

-- Add policy for public to read APPROVED schools
CREATE POLICY "public_read_approved_schools" ON schools
FOR SELECT USING (approved = true);

-- Alternative: If you want ALL schools visible (not just approved)
-- Uncomment this and comment out the policy above:
-- CREATE POLICY "public_read_all_schools" ON schools
-- FOR SELECT USING (true);

-- ========================================
-- VERIFY THE POLICIES ARE WORKING
-- ========================================
-- Run these queries to check:

-- View all current policies on schools table:
-- SELECT schemaname, tablename, policyname, permissive, roles, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'schools'
-- ORDER BY policyname;

-- Test: Query schools as unauthenticated user (should see approved schools):
-- SELECT id, name, location, approved FROM schools WHERE approved = true LIMIT 5;
