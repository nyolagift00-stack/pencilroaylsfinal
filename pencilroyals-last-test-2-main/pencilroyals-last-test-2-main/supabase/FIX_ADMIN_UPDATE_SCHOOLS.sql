-- FIX_ADMIN_UPDATE_SCHOOLS.sql
-- Ensures admin can update school approved status

-- Drop existing policies that might block admin updates
DROP POLICY IF EXISTS "admin_update_any_school" ON schools;
DROP POLICY IF EXISTS "users_update_school" ON schools;

-- Create clear admin policy for updating schools
CREATE POLICY "admin_update_schools" ON schools
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin'));

-- Test: Verify admins can update schools
-- SELECT 
--   s.id,
--   s.name,
--   s.approved,
--   EXISTS(SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin') as is_admin
-- FROM schools s
-- LIMIT 5;
