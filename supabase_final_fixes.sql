-- ============================================================================
-- PayPulse — Final Database Fixes & Setup
-- Run this in the Supabase SQL Editor (https://gnyzctxlqcidubanoiae.supabase.co)
-- ============================================================================

-- 1. Ensure profiles constraint allows SUPER_ADMIN
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('SUPER_ADMIN', 'OWNER', 'MANAGER', 'STAFF'));

-- 2. Approve and activate all super admin profiles
UPDATE public.profiles 
SET approval_status = 'APPROVED', is_active = TRUE 
WHERE role = 'SUPER_ADMIN';

-- 3. Ensure platform_settings table exists with all required columns
CREATE TABLE IF NOT EXISTS public.platform_settings (
  id TEXT PRIMARY KEY, -- will always be 'global'
  company_name TEXT NOT NULL DEFAULT 'PayPulse',
  tagline TEXT NOT NULL DEFAULT '',
  address TEXT DEFAULT '',
  logo_light_url TEXT DEFAULT '',
  logo_dark_url TEXT DEFAULT '',
  contact_email TEXT NOT NULL DEFAULT [EMAIL_ADDRESS]',
  working_time TEXT NOT NULL DEFAULT '11:00 AM - 08:00 PM (Mon - Sat)',
  notify_on_signup BOOLEAN NOT NULL DEFAULT TRUE,
  welcome_title TEXT NOT NULL DEFAULT 'Welcome to PayPulse',
  welcome_body TEXT NOT NULL DEFAULT 'Welcome to PayPulse! Your account has been created successfully. Please complete your profile and start exploring the app.',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Ensure all columns are present (in case table existed previously without them)
ALTER TABLE public.platform_settings ADD COLUMN IF NOT EXISTS notify_on_signup BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.platform_settings ADD COLUMN IF NOT EXISTS welcome_title TEXT NOT NULL DEFAULT 'Welcome to PayPulse';
ALTER TABLE public.platform_settings ADD COLUMN IF NOT EXISTS welcome_body TEXT NOT NULL DEFAULT 'Welcome to PayPulse! Your account has been created successfully. Please complete your profile and start exploring the app.';

-- Enable RLS on platform_settings
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Select policy: Everyone can read global settings/branding
DROP POLICY IF EXISTS platform_settings_select ON public.platform_settings;
CREATE POLICY platform_settings_select ON public.platform_settings
  FOR SELECT USING (true);

-- Admin write policy: allow Super Admins to write
DROP POLICY IF EXISTS platform_settings_all_admin ON public.platform_settings;
CREATE POLICY platform_settings_all_admin ON public.platform_settings
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'SUPER_ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'SUPER_ADMIN'
    )
  );

-- Seed global row if it doesn't exist
INSERT INTO public.platform_settings (id, company_name, contact_email, working_time)
VALUES ('global', 'PayPulse', 'contact.shresthraj@gmail.com', '10:00 AM - 08:00 PM (Mon - Sat)')
ON CONFLICT (id) DO NOTHING;


-- 4. Ensure notifications table exists and has target_role check & stats columns
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_target_role_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_target_role_check 
  CHECK (target_role IN ('ALL', 'OWNER', 'MANAGER', 'STAFF', 'SUPER_ADMIN'));

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS delivered_companies_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS delivered_users_count INT DEFAULT 0;

-- Ensure notification_reads table exists
CREATE TABLE IF NOT EXISTS public.notification_reads (
  notification_id UUID REFERENCES public.notifications(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (notification_id, user_id)
);

-- Enable RLS on notification_reads
ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reads_select_own ON public.notification_reads;
CREATE POLICY reads_select_own ON public.notification_reads
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS reads_insert_own ON public.notification_reads;
CREATE POLICY reads_insert_own ON public.notification_reads
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS reads_all_admin ON public.notification_reads;
CREATE POLICY reads_all_admin ON public.notification_reads
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'SUPER_ADMIN'
    )
  );

-- 5. Helper function for check
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'SUPER_ADMIN' AND approval_status = 'APPROVED'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

-- 6. Trigger to calculate delivered counts
CREATE OR REPLACE FUNCTION public.set_notification_delivered_counts()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate delivered companies
  IF NEW.target_company_id IS NOT NULL THEN
    NEW.delivered_companies_count := 1;
  ELSE
    NEW.delivered_companies_count := (SELECT COUNT(*)::INT FROM public.companies);
  END IF;

  -- Calculate delivered users
  IF NEW.target_company_id IS NOT NULL THEN
    IF NEW.target_role = 'ALL' THEN
      NEW.delivered_users_count := (SELECT COUNT(*)::INT FROM public.profiles WHERE company_id = NEW.target_company_id AND is_active AND approval_status = 'APPROVED');
    ELSE
      NEW.delivered_users_count := (SELECT COUNT(*)::INT FROM public.profiles WHERE company_id = NEW.target_company_id AND role = NEW.target_role AND is_active AND approval_status = 'APPROVED');
    END IF;
  ELSE
    IF NEW.target_role = 'ALL' THEN
      NEW.delivered_users_count := (SELECT COUNT(*)::INT FROM public.profiles WHERE is_active AND approval_status = 'APPROVED');
    ELSIF NEW.target_role = 'SUPER_ADMIN' THEN
      NEW.delivered_users_count := (SELECT COUNT(*)::INT FROM public.profiles WHERE role = 'SUPER_ADMIN' AND is_active);
    ELSE
      NEW.delivered_users_count := (SELECT COUNT(*)::INT FROM public.profiles WHERE role = NEW.target_role AND is_active AND approval_status = 'APPROVED');
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_set_notification_delivered_counts ON public.notifications;
CREATE TRIGGER trg_set_notification_delivered_counts
  BEFORE INSERT ON public.notifications
  FOR EACH ROW EXECUTE PROCEDURE public.set_notification_delivered_counts();

-- 7. Functions for read status
CREATE OR REPLACE FUNCTION public.get_unread_notifications_count()
RETURNS INT AS $$
DECLARE
  v_user_id UUID;
  v_company_id UUID;
  v_role TEXT;
  v_unread_count INT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN 0;
  END IF;

  -- Get current user info
  SELECT company_id, role INTO v_company_id, v_role
  FROM public.profiles
  WHERE id = v_user_id;

  -- Count unread notifications
  SELECT COUNT(*)::INT INTO v_unread_count
  FROM public.notifications n
  WHERE (
    n.target_company_id IS NULL OR n.target_company_id = v_company_id
  ) AND (
    n.target_role = 'ALL' 
    OR n.target_role = v_role
    OR (v_role = 'SUPER_ADMIN' AND n.target_role = 'SUPER_ADMIN')
  ) AND NOT EXISTS (
    SELECT 1 FROM public.notification_reads r
    WHERE r.notification_id = n.id AND r.user_id = v_user_id
  );

  RETURN v_unread_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION public.get_unread_notifications_count() TO authenticated;


CREATE OR REPLACE FUNCTION public.mark_notifications_as_read()
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
  v_company_id UUID;
  v_role TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  -- Get current user info
  SELECT company_id, role INTO v_company_id, v_role
  FROM public.profiles
  WHERE id = v_user_id;

  -- Insert read receipts for all matching unread notifications
  INSERT INTO public.notification_reads (notification_id, user_id)
  SELECT n.id, v_user_id
  FROM public.notifications n
  WHERE (
    n.target_company_id IS NULL OR n.target_company_id = v_company_id
  ) AND (
    n.target_role = 'ALL' 
    OR n.target_role = v_role
    OR (v_role = 'SUPER_ADMIN' AND n.target_role = 'SUPER_ADMIN')
  ) AND NOT EXISTS (
    SELECT 1 FROM public.notification_reads r
    WHERE r.notification_id = n.id AND r.user_id = v_user_id
  )
  ON CONFLICT (notification_id, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.mark_notifications_as_read() TO authenticated;

-- 8. Enable real-time replication for notifications table
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
  
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION
    WHEN duplicate_object THEN
      NULL;
  END;
END;
$$;
