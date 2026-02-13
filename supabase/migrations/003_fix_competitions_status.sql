-- Migration: Fix competitions table to have proper status field
-- This ensures the competitions table has a status column with the right values

-- Check if status column exists, if not add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'competitions' AND column_name = 'status'
    ) THEN
        ALTER TABLE competitions ADD COLUMN status TEXT DEFAULT 'active' CHECK (status IN ('upcoming', 'active', 'completed'));
        RAISE NOTICE 'Added status column to competitions table';
    ELSE
        RAISE NOTICE 'Status column already exists on competitions table';
    END IF;
END $$;

-- Update any "Pending" status to "active"
UPDATE competitions 
SET status = 'active' 
WHERE LOWER(status) = 'pending' OR status IS NULL;

-- Update any invalid status values to "active"
UPDATE competitions 
SET status = 'active' 
WHERE status NOT IN ('upcoming', 'active', 'completed');

-- Ensure updated_at is set
UPDATE competitions SET updated_at = NOW() WHERE updated_at IS NULL;

-- Verify the fix
SELECT 
  id, 
  name, 
  status, 
  created_at, 
  updated_at 
FROM competitions 
ORDER BY created_at DESC
LIMIT 10;
