-- ============================================================================
-- PayPulse — Super Admin Platform Settings & Storage Policies
-- Run this in the Supabase SQL Editor (https://gnyzctxlqcidubanoiae.supabase.co)
-- ============================================================================

-- 1. Create the platform_assets bucket in storage if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('platform_assets', 'platform_assets', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Enable RLS on storage if not enabled (usually enabled by default)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Allow public read access to platform_assets bucket
DROP POLICY IF EXISTS "Public Access platform_assets" ON storage.objects;
CREATE POLICY "Public Access platform_assets" ON storage.objects
  FOR SELECT USING (bucket_id = 'platform_assets');

-- 4. Allow Super Admin to manage logo files in platform_assets bucket
DROP POLICY IF EXISTS "Super Admin platform_assets" ON storage.objects;
CREATE POLICY "Super Admin platform_assets" ON storage.objects
  FOR ALL TO authenticated
  USING (
    bucket_id = 'platform_assets'
    AND (
      SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'SUPER_ADMIN' AND approval_status = 'APPROVED'
      )
    )
  )
  WITH CHECK (
    bucket_id = 'platform_assets'
    AND (
      SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'SUPER_ADMIN' AND approval_status = 'APPROVED'
      )
    )
  );

-- 5. Fix platform_settings RLS policies
DROP POLICY IF EXISTS platform_settings_select ON public.platform_settings;
CREATE POLICY platform_settings_select ON public.platform_settings
  FOR SELECT USING (true);

DROP POLICY IF EXISTS platform_settings_all_admin ON public.platform_settings;
CREATE POLICY platform_settings_all_admin ON public.platform_settings
  FOR ALL USING (
    (SELECT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'SUPER_ADMIN' AND approval_status = 'APPROVED'
    ))
  )
  WITH CHECK (
    (SELECT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'SUPER_ADMIN' AND approval_status = 'APPROVED'
    ))
  );
