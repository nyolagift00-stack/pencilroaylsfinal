-- ========================================
-- FIX: Create missing user_roles entries for existing schools
-- ========================================
-- If schools already exist but don't have user_roles entries, run this

-- Add user_roles entries for all schools without roles
INSERT INTO user_roles (user_id, role, school_id)
SELECT s.user_id, 'school', s.id
FROM schools s
WHERE s.user_id NOT IN (SELECT user_id FROM user_roles)
ON CONFLICT DO NOTHING;

-- ========================================
-- Verify the fix
-- ========================================
SELECT ur.user_id, ur.role, ur.school_id, au.email, s.name
FROM user_roles ur
LEFT JOIN auth.users au ON ur.user_id = au.id
LEFT JOIN schools s ON ur.school_id = s.id
ORDER BY ur.created_at DESC;
