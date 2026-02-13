-- Allow public/anonymous read access to schools table
-- This allows the homepage and public pages to fetch and display school listings without authentication

-- Enable RLS on schools table (if not already enabled)
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow anonymous users to SELECT (read) all schools
CREATE POLICY "Allow public read access to schools" ON public.schools
  FOR SELECT
  USING (true);

-- Policy 2: Allow authenticated users (school owners) to INSERT their own school
CREATE POLICY "Allow authenticated users to insert schools" ON public.schools
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy 3: Allow authenticated users to UPDATE their own school
CREATE POLICY "Allow users to update their own school" ON public.schools
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy 4: Allow authenticated users to DELETE their own school
CREATE POLICY "Allow users to delete their own school" ON public.schools
  FOR DELETE
  USING (auth.uid() = user_id);

-- Optional: Allow public read on related students table for homepage display
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to students" ON public.students
  FOR SELECT
  USING (true);

-- Optional: Allow public read on finalists table
ALTER TABLE public.finalists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to finalists" ON public.finalists
  FOR SELECT
  USING (true);

-- Note: You may need to adjust column visibility or add more granular policies
-- depending on which fields should be visible to the public
