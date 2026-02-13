-- Migration: add foreign key constraint for school_verification.school_id -> schools.id
-- This migration is safe to run multiple times; it only adds the constraint if missing.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_name = 'school_verification'
          AND kcu.column_name = 'school_id'
    ) THEN
        ALTER TABLE public.school_verification
        ADD CONSTRAINT fk_school_verification_school_id
        FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;
    END IF;
END
$$;

-- Optional: create index for performance (no-op if exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'i' AND c.relname = 'idx_verification_school_id'
    ) THEN
        CREATE INDEX idx_verification_school_id ON public.school_verification(school_id);
    END IF;
END
$$;
