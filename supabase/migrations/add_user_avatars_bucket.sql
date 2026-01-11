-- =====================================================
-- ADD USER-AVATARS STORAGE BUCKET AND POLICIES
-- Run this in Supabase SQL Editor
-- =====================================================

-- Create user-avatars bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-avatars', 'user-avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop existing policies if they exist
DO $$ 
BEGIN
    EXECUTE 'DROP POLICY IF EXISTS "Allow public read on user-avatars" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public insert on user-avatars" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public update on user-avatars" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow public delete on user-avatars" ON storage.objects';
END $$;

-- User Avatars policies - Allow all public operations
CREATE POLICY "Allow public read on user-avatars" ON storage.objects
    FOR SELECT TO public USING (bucket_id = 'user-avatars');

CREATE POLICY "Allow public insert on user-avatars" ON storage.objects
    FOR INSERT TO public WITH CHECK (bucket_id = 'user-avatars');

CREATE POLICY "Allow public update on user-avatars" ON storage.objects
    FOR UPDATE TO public USING (bucket_id = 'user-avatars');

CREATE POLICY "Allow public delete on user-avatars" ON storage.objects
    FOR DELETE TO public USING (bucket_id = 'user-avatars');
