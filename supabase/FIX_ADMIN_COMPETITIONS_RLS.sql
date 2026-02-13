-- ========================================
-- FIX: Allow Admin to Insert Competitions
-- ========================================
-- Admins need INSERT permission on competitions table

-- Drop old policies on competitions table
DROP POLICY IF EXISTS "admin_view_all_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_insert_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_update_competitions" ON competitions;
DROP POLICY IF EXISTS "admin_delete_competitions" ON competitions;
DROP POLICY IF EXISTS "view_active_competitions" ON competitions;
DROP POLICY IF EXISTS "public_read_competitions" ON competitions;

-- Enable RLS if not already enabled
ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;

-- ========================================
-- PUBLIC can READ active/completed competitions
-- ========================================
CREATE POLICY "public_read_competitions" ON competitions
FOR SELECT
USING (status = 'active' OR status = 'completed' OR true);

-- ========================================
-- ADMIN can VIEW all competitions
-- ========================================
CREATE POLICY "admin_view_all_competitions" ON competitions
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- ========================================
-- ADMIN can INSERT competitions (KEY FIX!)
-- ========================================
CREATE POLICY "admin_insert_competitions" ON competitions
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- ========================================
-- ADMIN can UPDATE competitions
-- ========================================
CREATE POLICY "admin_update_competitions" ON competitions
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
-- ADMIN can DELETE competitions
-- ========================================
CREATE POLICY "admin_delete_competitions" ON competitions
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- ========================================
-- Similarly for competition_scores, results, finalists - allow admin to manage
-- ========================================

-- Drop old policies on competition_scores
DROP POLICY IF EXISTS "admin_view_all_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_insert_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_update_scores" ON competition_scores;
DROP POLICY IF EXISTS "admin_delete_scores" ON competition_scores;
DROP POLICY IF EXISTS "public_read_scores" ON competition_scores;
DROP POLICY IF EXISTS "Scores are viewable by all" ON competition_scores;

ALTER TABLE competition_scores ENABLE ROW LEVEL SECURITY;

-- Public can read scores
CREATE POLICY "public_read_scores" ON competition_scores
FOR SELECT
USING (true);

-- Admin can manage scores
CREATE POLICY "admin_insert_scores" ON competition_scores
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "admin_view_all_scores" ON competition_scores
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "admin_update_scores" ON competition_scores
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

CREATE POLICY "admin_delete_scores" ON competition_scores
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- ========================================
-- Similar fixes for finalists, results
-- ========================================

-- Drop old policies on finalists
DROP POLICY IF EXISTS "admin_view_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_insert_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_update_finalists" ON finalists;
DROP POLICY IF EXISTS "admin_delete_finalists" ON finalists;
DROP POLICY IF EXISTS "view_finalists" ON finalists;

ALTER TABLE finalists ENABLE ROW LEVEL SECURITY;

-- Public can read finalists
CREATE POLICY "view_finalists" ON finalists
FOR SELECT
USING (true);

-- Admin can manage finalists
CREATE POLICY "admin_insert_finalists" ON finalists
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "admin_view_finalists" ON finalists
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "admin_update_finalists" ON finalists
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

CREATE POLICY "admin_delete_finalists" ON finalists
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- Drop old policies on results
DROP POLICY IF EXISTS "admin_view_results" ON results;
DROP POLICY IF EXISTS "admin_insert_results" ON results;
DROP POLICY IF EXISTS "admin_update_results" ON results;
DROP POLICY IF EXISTS "admin_delete_results" ON results;
DROP POLICY IF EXISTS "view_results" ON results;

ALTER TABLE results ENABLE ROW LEVEL SECURITY;

-- Public can read results
CREATE POLICY "view_results" ON results
FOR SELECT
USING (true);

-- Admin can manage results
CREATE POLICY "admin_insert_results" ON results
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "admin_view_results" ON results
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "admin_update_results" ON results
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

CREATE POLICY "admin_delete_results" ON results
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM user_roles 
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- ========================================
-- VERIFY THE FIX
-- ========================================
-- Run this to check policies:
-- SELECT schemaname, tablename, policyname, permissive
-- FROM pg_policies
-- WHERE tablename IN ('competitions', 'competition_scores', 'finalists', 'results')
-- ORDER BY tablename, policyname;
