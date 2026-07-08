-- ============================================================================
-- PayPulse — Notifications Tracking, Read Receipts, and Signup Alerts Fix
-- Run this in the Supabase SQL Editor (https://gnyzctxlqcidubanoiae.supabase.co)
-- ============================================================================

-- 1. Update target_role check constraint to include 'SUPER_ADMIN'
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_target_role_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_target_role_check 
  CHECK (target_role IN ('ALL', 'OWNER', 'MANAGER', 'STAFF', 'SUPER_ADMIN'));

-- 2. Add delivery columns to notifications table
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS delivered_companies_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS delivered_users_count INT DEFAULT 0;

-- 3. Create notification reads (seen receipts) table
CREATE TABLE IF NOT EXISTS public.notification_reads (
  notification_id UUID REFERENCES public.notifications(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (notification_id, user_id)
);

-- Enable RLS on notification_reads
ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS reads_select_own ON public.notification_reads;
DROP POLICY IF EXISTS reads_insert_own ON public.notification_reads;
DROP POLICY IF EXISTS reads_all_admin ON public.notification_reads;

-- Add policies
CREATE POLICY reads_select_own ON public.notification_reads
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY reads_insert_own ON public.notification_reads
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY reads_all_admin ON public.notification_reads
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'SUPER_ADMIN'
    )
  );

-- 4. Trigger function to calculate and set delivered counts BEFORE INSERT
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

-- Drop trigger if exists, then recreate
DROP TRIGGER IF EXISTS trg_set_notification_delivered_counts ON public.notifications;
CREATE TRIGGER trg_set_notification_delivered_counts
  BEFORE INSERT ON public.notifications
  FOR EACH ROW EXECUTE PROCEDURE public.set_notification_delivered_counts();

-- 5. RPC function to get count of unread notifications for current user
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
    -- Target checking
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

-- 6. RPC function to mark all matching notifications as read for current user
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

-- 7. Add notify_on_signup column to platform_settings table
ALTER TABLE public.platform_settings
  ADD COLUMN IF NOT EXISTS notify_on_signup BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.platform_settings
  ADD COLUMN IF NOT EXISTS welcome_title TEXT NOT NULL DEFAULT 'Welcome to PayPulse';
ALTER TABLE public.platform_settings
  ADD COLUMN IF NOT EXISTS welcome_body TEXT NOT NULL DEFAULT 'Welcome to PayPulse! Your account has been created successfully. Please complete your profile and start exploring the app.';

-- 8. Recreate handle_new_user() trigger function to optionally auto-notify Super Admin on new signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_notify BOOLEAN;
BEGIN
  -- Insert profile
  INSERT INTO public.profiles (id, name, email, role, is_active)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'User'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'role', 'STAFF'),
    TRUE
  );

  -- Fetch notify settings (default to TRUE if row/setting doesn't exist yet)
  SELECT COALESCE(notify_on_signup, TRUE) INTO v_notify
  FROM public.platform_settings
  WHERE id = 'global';

  IF v_notify IS NULL THEN
    v_notify := TRUE;
  END IF;

  -- Create system notification for Super Admin
  IF v_notify = TRUE THEN
    INSERT INTO public.notifications (title, body, target_role)
    VALUES (
      'New User Registration',
      'A new user named ' || COALESCE(new.raw_user_meta_data->>'name', 'User') || ' (' || new.email || ') has signed up.',
      'SUPER_ADMIN'
    );
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
