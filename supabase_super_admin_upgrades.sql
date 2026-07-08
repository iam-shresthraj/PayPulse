-- ============================================================================
-- PayPulse — Super Admin Upgrades Migration
-- Run this in the Supabase SQL Editor (https://gnyzctxlqcidubanoiae.supabase.co)
-- Safe to re-run: uses IF NOT EXISTS / OR REPLACE.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Create Notifications Table and Policies
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  file_url TEXT,
  target_company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  target_role TEXT DEFAULT 'ALL' CHECK (target_role IN ('ALL', 'OWNER', 'MANAGER', 'STAFF')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Select Policy: users can read notifications sent to their company/role or global ones
DROP POLICY IF EXISTS notifications_select ON public.notifications;
CREATE POLICY notifications_select ON public.notifications
  FOR SELECT USING (
    target_company_id IS NULL OR target_company_id = (
      SELECT company_id FROM public.profiles WHERE id = auth.uid()
    )
  );

-- Admin Policy: Super Admin can do everything
DROP POLICY IF EXISTS notifications_all_admin ON public.notifications;
CREATE POLICY notifications_all_admin ON public.notifications
  FOR ALL USING (public.is_super_admin());


-- ----------------------------------------------------------------------------
-- 2. Create Platform Settings Table and Policies
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.platform_settings (
  id TEXT PRIMARY KEY, -- will always be 'global'
  company_name TEXT NOT NULL DEFAULT 'PayPulse',
  tagline TEXT NOT NULL DEFAULT '',
  address TEXT DEFAULT '',
  logo_light_url TEXT DEFAULT '',
  logo_dark_url TEXT DEFAULT '',
  contact_email TEXT NOT NULL DEFAULT 'contact@paypulse.com',
  working_time TEXT NOT NULL DEFAULT '10:00 AM - 08:00 PM (Mon - Sat)',
  notify_on_signup BOOLEAN NOT NULL DEFAULT TRUE,
  welcome_title TEXT NOT NULL DEFAULT 'Welcome to PayPulse',
  welcome_body TEXT NOT NULL DEFAULT 'Welcome to PayPulse! Your account has been created successfully. Please complete your profile and start exploring the app.',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Select Policy: everyone can read global settings/branding
DROP POLICY IF EXISTS platform_settings_select ON public.platform_settings;
CREATE POLICY platform_settings_select ON public.platform_settings
  FOR SELECT USING (true);

-- Admin Policy: Super Admin can do everything
DROP POLICY IF EXISTS platform_settings_all_admin ON public.platform_settings;
CREATE POLICY platform_settings_all_admin ON public.platform_settings
  FOR ALL USING (public.is_super_admin());

-- Seed global row if it doesn't exist
INSERT INTO public.platform_settings (id, company_name, contact_email, working_time)
VALUES ('global', 'PayPulse', 'contact.shresthraj@gmail.com', '10:00 AM - 08:00 PM (Mon - Sat)')
ON CONFLICT (id) DO NOTHING;


-- ----------------------------------------------------------------------------
-- 3. Seed PayPulse Company
-- ----------------------------------------------------------------------------
INSERT INTO public.companies (name, category, staff_code, manager_code, owner_code)
SELECT 'PayPulse', 'SAAS', 'PSTAFF01', 'PMANGR01', 'POWNER01'
WHERE NOT EXISTS (SELECT 1 FROM public.companies WHERE name = 'PayPulse');
