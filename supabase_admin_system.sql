-- ============================================================================
-- PayPulse — Super Admin System & Code Auto-Rotation Migration
-- Run this in the Supabase SQL Editor (https://gnyzctxlqcidubanoiae.supabase.co)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Alter profiles role check constraint to include 'SUPER_ADMIN'
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('SUPER_ADMIN', 'OWNER', 'MANAGER', 'STAFF'));

-- ----------------------------------------------------------------------------
-- 2. Helper: check if current user is SUPER_ADMIN
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'SUPER_ADMIN' AND approval_status = 'APPROVED'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. Update companies policies for SUPER_ADMIN access
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS companies_select_super ON public.companies;
CREATE POLICY companies_select_super ON public.companies
  FOR SELECT USING (public.is_super_admin());

DROP POLICY IF EXISTS companies_insert_super ON public.companies;
CREATE POLICY companies_insert_super ON public.companies
  FOR INSERT WITH CHECK (public.is_super_admin());

DROP POLICY IF EXISTS companies_update_super ON public.companies;
CREATE POLICY companies_update_super ON public.companies
  FOR UPDATE USING (public.is_super_admin());

DROP POLICY IF EXISTS companies_delete_super ON public.companies;
CREATE POLICY companies_delete_super ON public.companies
  FOR DELETE USING (public.is_super_admin());

-- ----------------------------------------------------------------------------
-- 4. Update profiles policies for SUPER_ADMIN access
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_super_all ON public.profiles;
CREATE POLICY profiles_super_all ON public.profiles
  FOR ALL USING (public.is_super_admin() OR company_id = public.current_company_id() OR id = auth.uid());

-- ----------------------------------------------------------------------------
-- 5. Update data tables policies to allow SUPER_ADMIN select/read access
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['company_settings','coupons','customers','products','invoices','daily_rates','record_book'] LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name = t) THEN
      EXECUTE format('DROP POLICY IF EXISTS %I_select ON public.%I', t, t);
      EXECUTE format(
        'CREATE POLICY %I_select ON public.%I FOR SELECT USING (company_id = public.current_company_id() OR public.is_super_admin())',
        t, t);
    END IF;
  END LOOP;
END $$;

-- ----------------------------------------------------------------------------
-- 6. RPC: manually regenerate a company code (SUPER_ADMIN only)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.regenerate_company_code(p_company_id UUID, p_role TEXT)
RETURNS TEXT AS $$
DECLARE
  v_new_code TEXT;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorised';
  END IF;

  v_new_code := public.generate_company_code();

  IF p_role = 'STAFF' THEN
    UPDATE public.companies SET staff_code = v_new_code WHERE id = p_company_id;
  ELSIF p_role = 'MANAGER' THEN
    UPDATE public.companies SET manager_code = v_new_code WHERE id = p_company_id;
  ELSIF p_role = 'OWNER' THEN
    UPDATE public.companies SET owner_code = v_new_code WHERE id = p_company_id;
  ELSE
    RAISE EXCEPTION 'Invalid role';
  END IF;

  RETURN v_new_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.regenerate_company_code(UUID, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 7. Update handle_new_user trigger to support SUPER_ADMIN signups
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_code TEXT;
  v_company public.companies%ROWTYPE;
  v_role TEXT;
  v_status TEXT;
  v_owner_exists BOOLEAN;
BEGIN
  -- Auto-promote and auto-approve super admin email addresses (with or without .com)
  IF new.email = 'contact.shresthraj@gmail' OR new.email = 'contact.shresthraj@gmail.com' THEN
    INSERT INTO public.profiles (id, name, email, phone, role, is_active, company_id, approval_status)
    VALUES (
      new.id,
      COALESCE(new.raw_user_meta_data->>'name', 'Super Admin'),
      new.email,
      COALESCE(new.raw_user_meta_data->>'phone', ''),
      'SUPER_ADMIN',
      TRUE,
      NULL,
      'APPROVED'
    );
    RETURN new;
  END IF;

  v_code := upper(trim(COALESCE(new.raw_user_meta_data->>'company_code', '')));

  SELECT * INTO v_company FROM public.companies
  WHERE staff_code = v_code OR manager_code = v_code OR owner_code = v_code;

  IF v_company.id IS NULL THEN
    RAISE EXCEPTION 'Invalid company code';
  END IF;

  IF v_code = v_company.owner_code THEN
    v_role := 'OWNER';
    SELECT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE company_id = v_company.id AND role = 'OWNER' AND approval_status = 'APPROVED'
    ) INTO v_owner_exists;
    v_status := CASE WHEN v_owner_exists THEN 'PENDING' ELSE 'APPROVED' END;
  ELSIF v_code = v_company.manager_code THEN
    v_role := 'MANAGER';
    v_status := 'PENDING';
  ELSE
    v_role := 'STAFF';
    v_status := 'PENDING';
  END IF;

  INSERT INTO public.profiles (id, name, email, phone, role, is_active, company_id, approval_status)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'User'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'phone', ''),
    v_role,
    TRUE,
    v_company.id,
    v_status
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ----------------------------------------------------------------------------
-- 8. Update review_member to automatically rotate company codes upon approval
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.review_member(p_user_id UUID, p_approve BOOLEAN)
RETURNS VOID AS $$
DECLARE
  v_reviewer_role TEXT := public.current_role_pp();
  v_target public.profiles%ROWTYPE;
BEGIN
  SELECT * INTO v_target FROM public.profiles WHERE id = p_user_id;

  IF v_target.id IS NULL THEN
    RAISE EXCEPTION 'Member not found';
  END IF;

  -- Super admin can approve any user; otherwise check standard business boundaries
  IF NOT public.is_super_admin() THEN
    IF v_target.company_id IS DISTINCT FROM public.current_company_id() THEN
      RAISE EXCEPTION 'Member not found in your company';
    END IF;
    IF v_reviewer_role = 'MANAGER' AND v_target.role <> 'STAFF' THEN
      RAISE EXCEPTION 'Managers can only approve staff accounts';
    END IF;
    IF v_reviewer_role NOT IN ('MANAGER', 'OWNER') THEN
      RAISE EXCEPTION 'Not authorised to approve members';
    END IF;
  END IF;

  IF v_target.approval_status <> 'PENDING' THEN
    RAISE EXCEPTION 'Member is not pending approval';
  END IF;

  UPDATE public.profiles
  SET approval_status = CASE WHEN p_approve THEN 'APPROVED' ELSE 'REJECTED' END,
      is_active = p_approve,
      approved_by = auth.uid(),
      updated_at = timezone('utc', now())
  WHERE id = p_user_id;

  -- Rotate company access codes on successful approval
  IF p_approve THEN
    IF v_target.role = 'STAFF' THEN
      UPDATE public.companies SET staff_code = public.generate_company_code() WHERE id = v_target.company_id;
    ELSIF v_target.role = 'MANAGER' THEN
      UPDATE public.companies SET manager_code = public.generate_company_code() WHERE id = v_target.company_id;
    ELSIF v_target.role = 'OWNER' THEN
      UPDATE public.companies SET owner_code = public.generate_company_code() WHERE id = v_target.company_id;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.review_member(UUID, BOOLEAN) TO authenticated;
