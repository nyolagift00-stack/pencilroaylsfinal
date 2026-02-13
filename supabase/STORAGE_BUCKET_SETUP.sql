-- Storage Bucket Setup for Sponsor Logos
-- Run this in Supabase SQL Editor to enable storage

-- Note: Create bucket in Supabase dashboard:
-- 1. Go to Storage > Buckets
-- 2. Create new bucket named "sponsor-logos"
-- 3. Make it Public
-- 4. Run the RLS policies below

-- RLS Policies for sponsor-logos storage bucket
-- Remove the default policies first if they exist

-- Allow public read access to all sponsor logos  
CREATE POLICY "Allow public read access to sponsor logos" ON storage.objects
FOR SELECT
USING (bucket_id = 'sponsor-logos');

-- Allow admins to upload sponsor logos
CREATE POLICY "Allow admins to upload sponsor logos" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'sponsor-logos' AND 
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
);

-- Allow admins to delete sponsor logos
CREATE POLICY "Allow admins to delete sponsor logos" ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'sponsor-logos' AND 
  EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
);
