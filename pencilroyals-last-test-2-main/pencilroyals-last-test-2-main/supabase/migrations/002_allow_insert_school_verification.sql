-- Migration: allow schools to INSERT into school_verification
-- Adds a policy to permit the authenticated school user to create their own verification record
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy p
        JOIN pg_class c ON p.polrelid = c.oid
        WHERE c.relname = 'school_verification' AND p.polname = 'schools_insert_own_verification'
    ) THEN
        EXECUTE $sql$
            CREATE POLICY schools_insert_own_verification
            ON public.school_verification
            FOR INSERT
            WITH CHECK (
                auth.uid() = user_id
                AND school_id = get_user_school(auth.uid())
            );
        $sql$;
    END IF;
END
$$;
