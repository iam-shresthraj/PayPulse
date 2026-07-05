-- ============================================================================
-- PayPulse — Security & Multi-Company Migration (v2)
-- Run this in the Supabase SQL Editor (https://gnyzctxlqcidubanoiae.supabase.co)
-- Safe to re-run: uses IF NOT EXISTS / OR REPLACE everywhere possible.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Helper: random 8-character company code (unambiguous alphabet)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_company_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no 0/O/1/I
  result TEXT := '';
  i INT;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- ----------------------------------------------------------------------------
-- 1. Companies table — each company gets 3 unique 8-char codes
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  staff_code CHAR(8) NOT NULL UNIQUE DEFAULT public.generate_company_code(),
  manager_code CHAR(8) NOT NULL UNIQUE DEFAULT public.generate_company_code(),
  owner_code CHAR(8) NOT NULL UNIQUE DEFAULT public.generate_company_code(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT codes_distinct CHECK (
    staff_code <> manager_code AND staff_code <> owner_code AND manager_code <> owner_code
  )
);

-- Seed the first company if none exists (rename as needed)
INSERT INTO public.companies (name)
SELECT 'Swarnayan Jewellers'
WHERE NOT EXISTS (SELECT 1 FROM public.companies);

-- ----------------------------------------------------------------------------
-- 2. Profiles — roles become OWNER / MANAGER / STAFF, add approval workflow
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
UPDATE public.profiles SET role = 'MANAGER' WHERE role = 'CO_OWNER';
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check CHECK (role IN ('OWNER', 'MANAGER', 'STAFF'));

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id),
  ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'APPROVED'
    CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED')),
  ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '';

-- Attach existing profiles to the first company
UPDATE public.profiles
SET company_id = (SELECT id FROM public.companies ORDER BY created_at LIMIT 1)
WHERE company_id IS NULL;

-- ----------------------------------------------------------------------------
-- 3. Company scoping for data tables (multi-tenancy)
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['company_settings','coupons','customers','products','invoices','daily_rates','record_book'] LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name = t) THEN
      EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id)', t);
      EXECUTE format('UPDATE public.%I SET company_id = (SELECT id FROM public.companies ORDER BY created_at LIMIT 1) WHERE company_id IS NULL', t);
    END IF;
  END LOOP;
END $$;

-- HUID must be the unique product identifier (per company)
CREATE UNIQUE INDEX IF NOT EXISTS products_huid_company_unique
  ON public.products (company_id, huid_number)
  WHERE huid_number IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 4. Signup trigger — resolve company code → role + company, set approval
--    Staff & Manager signups start as PENDING (staff approved by manager/owner,
--    manager approved by owner). Owner-code signups: first owner of a company
--    is auto-approved; later owners must be approved by an existing owner.
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

  INSERT INTO public.profiles (id, name, email, role, is_active, company_id, approval_status)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'User'),
    new.email,
    v_role,
    TRUE,
    v_company.id,
    v_status
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 5. RPC: validate a company code BEFORE signup (never leaks other codes)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_company_code(p_code TEXT)
RETURNS TABLE (company_name TEXT, role TEXT) AS $$
  SELECT c.name,
         CASE
           WHEN upper(trim(p_code)) = c.owner_code THEN 'OWNER'
           WHEN upper(trim(p_code)) = c.manager_code THEN 'MANAGER'
           ELSE 'STAFF'
         END
  FROM public.companies c
  WHERE c.staff_code = upper(trim(p_code))
     OR c.manager_code = upper(trim(p_code))
     OR c.owner_code = upper(trim(p_code));
$$ LANGUAGE sql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.validate_company_code(TEXT) TO anon, authenticated;

-- ----------------------------------------------------------------------------
-- 6. Helper functions for RLS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_company_id()
RETURNS UUID AS $$
  SELECT company_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.current_role_pp()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles
  WHERE id = auth.uid() AND approval_status = 'APPROVED' AND is_active;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ----------------------------------------------------------------------------
-- 7. RPC: fetch codes with role-based visibility
--    STAFF → nothing; MANAGER → staff code; OWNER → all three codes
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_company_codes()
RETURNS TABLE (staff_code TEXT, manager_code TEXT, owner_code TEXT) AS $$
DECLARE
  v_role TEXT := public.current_role_pp();
  v_company UUID := public.current_company_id();
BEGIN
  IF v_role = 'OWNER' THEN
    RETURN QUERY SELECT c.staff_code::TEXT, c.manager_code::TEXT, c.owner_code::TEXT
      FROM public.companies c WHERE c.id = v_company;
  ELSIF v_role = 'MANAGER' THEN
    RETURN QUERY SELECT c.staff_code::TEXT, NULL::TEXT, NULL::TEXT
      FROM public.companies c WHERE c.id = v_company;
  END IF;
  -- STAFF (or pending/unknown): return nothing
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_company_codes() TO authenticated;

-- ----------------------------------------------------------------------------
-- 8. RPC: approve / reject a pending member (with role hierarchy checks)
--    MANAGER can approve STAFF; OWNER can approve STAFF, MANAGER and OWNER.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.review_member(p_user_id UUID, p_approve BOOLEAN)
RETURNS VOID AS $$
DECLARE
  v_reviewer_role TEXT := public.current_role_pp();
  v_target public.profiles%ROWTYPE;
BEGIN
  SELECT * INTO v_target FROM public.profiles WHERE id = p_user_id;

  IF v_target.id IS NULL OR v_target.company_id IS DISTINCT FROM public.current_company_id() THEN
    RAISE EXCEPTION 'Member not found in your company';
  END IF;
  IF v_target.approval_status <> 'PENDING' THEN
    RAISE EXCEPTION 'Member is not pending approval';
  END IF;
  IF v_reviewer_role = 'MANAGER' AND v_target.role <> 'STAFF' THEN
    RAISE EXCEPTION 'Managers can only approve staff accounts';
  END IF;
  IF v_reviewer_role NOT IN ('MANAGER', 'OWNER') THEN
    RAISE EXCEPTION 'Not authorised to approve members';
  END IF;

  UPDATE public.profiles
  SET approval_status = CASE WHEN p_approve THEN 'APPROVED' ELSE 'REJECTED' END,
      is_active = p_approve,
      approved_by = auth.uid(),
      updated_at = timezone('utc', now())
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.review_member(UUID, BOOLEAN) TO authenticated;

-- ----------------------------------------------------------------------------
-- 9. Row Level Security — role permission matrix
--    STAFF   : create/delete/recover invoices, update rates, add customers,
--              add products (no invoice edits, no company edits, no codes)
--    MANAGER : all staff rights + modify invoices, manage staff, export data
--    OWNER   : everything incl. company details
-- ----------------------------------------------------------------------------
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- companies: no direct select for codes — access only through get_company_codes()
DROP POLICY IF EXISTS companies_select ON public.companies;
CREATE POLICY companies_select ON public.companies
  FOR SELECT USING (false);

-- profiles
DROP POLICY IF EXISTS profiles_select ON public.profiles;
CREATE POLICY profiles_select ON public.profiles
  FOR SELECT USING (
    id = auth.uid() OR company_id = public.current_company_id()
  );

DROP POLICY IF EXISTS profiles_update_self ON public.profiles;
CREATE POLICY profiles_update_self ON public.profiles
  FOR UPDATE USING (id = auth.uid());

DROP POLICY IF EXISTS profiles_update_admin ON public.profiles;
CREATE POLICY profiles_update_admin ON public.profiles
  FOR UPDATE USING (
    company_id = public.current_company_id()
    AND public.current_role_pp() IN ('MANAGER', 'OWNER')
  );

-- Data tables
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['company_settings','coupons','customers','products','invoices','daily_rates','record_book'] LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name = t) THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('DROP POLICY IF EXISTS %I_select ON public.%I', t, t);
      EXECUTE format(
        'CREATE POLICY %I_select ON public.%I FOR SELECT USING (company_id = public.current_company_id() AND public.current_role_pp() IS NOT NULL)',
        t, t);
    END IF;
  END LOOP;
END $$;

-- INSERT: any approved member of the company (staff can create invoices,
-- customers, products, rates, records)
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['coupons','customers','products','invoices','daily_rates','record_book'] LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name = t) THEN
      EXECUTE format('DROP POLICY IF EXISTS %I_insert ON public.%I', t, t);
      EXECUTE format(
        'CREATE POLICY %I_insert ON public.%I FOR INSERT WITH CHECK (company_id = public.current_company_id() AND public.current_role_pp() IS NOT NULL)',
        t, t);
    END IF;
  END LOOP;
END $$;

-- UPDATE invoices: all approved members may update (needed for staff
-- delete/recover which touches status/deleted_at), BUT a guard trigger blocks
-- STAFF from modifying the financial content of an existing invoice.
DROP POLICY IF EXISTS invoices_update ON public.invoices;
CREATE POLICY invoices_update ON public.invoices
  FOR UPDATE USING (
    company_id = public.current_company_id()
    AND public.current_role_pp() IS NOT NULL
  );

CREATE OR REPLACE FUNCTION public.guard_invoice_edit()
RETURNS TRIGGER AS $$
BEGIN
  IF public.current_role_pp() = 'STAFF' THEN
    IF (new.items::TEXT IS DISTINCT FROM old.items::TEXT)
       OR (new.gross_amount IS DISTINCT FROM old.gross_amount)
       OR (new.final_payable IS DISTINCT FROM old.final_payable)
       OR (new.taxable_amount IS DISTINCT FROM old.taxable_amount)
       OR (new.total_amount_paid IS DISTINCT FROM old.total_amount_paid)
       OR (new.balance_due IS DISTINCT FROM old.balance_due)
       OR (new.coupon_discount IS DISTINCT FROM old.coupon_discount)
       OR (new.customer_id IS DISTINCT FROM old.customer_id) THEN
      RAISE EXCEPTION 'Staff accounts cannot modify existing invoices. Ask a manager.';
    END IF;
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_guard_invoice_edit ON public.invoices;
CREATE TRIGGER trg_guard_invoice_edit
  BEFORE UPDATE ON public.invoices
  FOR EACH ROW EXECUTE PROCEDURE public.guard_invoice_edit();

-- Invoice number counter lives in company_settings (owner-only table), so all
-- members bump it through SECURITY DEFINER RPCs instead of direct updates.
CREATE OR REPLACE FUNCTION public.next_invoice_number()
RETURNS TEXT AS $$
DECLARE
  s RECORD;
  v_next INT;
BEGIN
  IF public.current_role_pp() IS NULL THEN
    RAISE EXCEPTION 'Not authorised';
  END IF;
  SELECT * INTO s FROM public.company_settings
  WHERE company_id = public.current_company_id()
  LIMIT 1 FOR UPDATE;
  IF s IS NULL THEN
    RETURN 'S-' || floor(extract(epoch FROM now()))::TEXT;
  END IF;
  v_next := COALESCE(s.invoice_current_counter, 0) + 1;
  UPDATE public.company_settings SET invoice_current_counter = v_next WHERE id = s.id;
  RETURN COALESCE(s.invoice_prefix, 'S') || COALESCE(s.invoice_separator, '-')
         || lpad(v_next::TEXT, COALESCE(s.invoice_padding_length, 6), '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rollback_invoice_counter(p_invoice_number TEXT)
RETURNS VOID AS $$
DECLARE
  s RECORD;
  v_expected TEXT;
BEGIN
  IF public.current_role_pp() IS NULL THEN
    RAISE EXCEPTION 'Not authorised';
  END IF;
  SELECT * INTO s FROM public.company_settings
  WHERE company_id = public.current_company_id()
  LIMIT 1 FOR UPDATE;
  IF s IS NULL THEN RETURN; END IF;
  v_expected := COALESCE(s.invoice_prefix, 'S') || COALESCE(s.invoice_separator, '-')
                || lpad(COALESCE(s.invoice_current_counter, 0)::TEXT, COALESCE(s.invoice_padding_length, 6), '0');
  IF p_invoice_number = v_expected AND COALESCE(s.invoice_current_counter, 0) > 0 THEN
    UPDATE public.company_settings
    SET invoice_current_counter = s.invoice_current_counter - 1
    WHERE id = s.id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.next_invoice_number() TO authenticated;
GRANT EXECUTE ON FUNCTION public.rollback_invoice_counter(TEXT) TO authenticated;

-- UPDATE other business tables: any approved member (rates, customers, products)
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['customers','products','daily_rates','record_book'] LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name = t) THEN
      EXECUTE format('DROP POLICY IF EXISTS %I_update ON public.%I', t, t);
      EXECUTE format(
        'CREATE POLICY %I_update ON public.%I FOR UPDATE USING (company_id = public.current_company_id() AND public.current_role_pp() IS NOT NULL)',
        t, t);
    END IF;
  END LOOP;
END $$;

-- Coupons update: manager/owner
DROP POLICY IF EXISTS coupons_update ON public.coupons;
CREATE POLICY coupons_update ON public.coupons
  FOR UPDATE USING (
    company_id = public.current_company_id()
    AND public.current_role_pp() IN ('MANAGER', 'OWNER')
  );

-- company_settings: everyone reads (policy above); only OWNER writes
DROP POLICY IF EXISTS company_settings_update ON public.company_settings;
CREATE POLICY company_settings_update ON public.company_settings
  FOR UPDATE USING (
    company_id = public.current_company_id()
    AND public.current_role_pp() = 'OWNER'
  );
DROP POLICY IF EXISTS company_settings_insert ON public.company_settings;
CREATE POLICY company_settings_insert ON public.company_settings
  FOR INSERT WITH CHECK (
    company_id = public.current_company_id()
    AND public.current_role_pp() = 'OWNER'
  );

-- DELETE invoices permanently: any approved member (per requirements staff can
-- delete). Other tables: manager/owner.
DROP POLICY IF EXISTS invoices_delete ON public.invoices;
CREATE POLICY invoices_delete ON public.invoices
  FOR DELETE USING (
    company_id = public.current_company_id()
    AND public.current_role_pp() IS NOT NULL
  );

-- ----------------------------------------------------------------------------
-- 10. Avatars storage bucket (profile photos)
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS avatars_read ON storage.objects;
CREATE POLICY avatars_read ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS avatars_write ON storage.objects;
CREATE POLICY avatars_write ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND auth.uid() IS NOT NULL
    AND name LIKE auth.uid() || '%'
  );

DROP POLICY IF EXISTS avatars_update ON storage.objects;
CREATE POLICY avatars_update ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND auth.uid() IS NOT NULL
    AND name LIKE auth.uid() || '%'
  );

-- ----------------------------------------------------------------------------
-- 11. View: pending approvals (RLS-safe via SECURITY INVOKER on profiles)
-- ----------------------------------------------------------------------------
-- Managers see pending STAFF; owners see pending STAFF + MANAGER + OWNER.
CREATE OR REPLACE FUNCTION public.get_pending_members()
RETURNS TABLE (id UUID, name TEXT, email TEXT, role TEXT, created_at TIMESTAMPTZ) AS $$
DECLARE
  v_role TEXT := public.current_role_pp();
BEGIN
  IF v_role = 'OWNER' THEN
    RETURN QUERY SELECT p.id, p.name, p.email, p.role, p.created_at
      FROM public.profiles p
      WHERE p.company_id = public.current_company_id() AND p.approval_status = 'PENDING'
      ORDER BY p.created_at;
  ELSIF v_role = 'MANAGER' THEN
    RETURN QUERY SELECT p.id, p.name, p.email, p.role, p.created_at
      FROM public.profiles p
      WHERE p.company_id = public.current_company_id()
        AND p.approval_status = 'PENDING' AND p.role = 'STAFF'
      ORDER BY p.created_at;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_pending_members() TO authenticated;

-- ----------------------------------------------------------------------------
-- 12. Auto-fill company_id on insert (so the app never has to send it)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.autofill_company_id()
RETURNS TRIGGER AS $$
BEGIN
  IF new.company_id IS NULL THEN
    new.company_id := public.current_company_id();
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['company_settings','coupons','customers','products','invoices','daily_rates','record_book'] LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name = t) THEN
      EXECUTE format('DROP TRIGGER IF EXISTS trg_autofill_company ON public.%I', t);
      EXECUTE format(
        'CREATE TRIGGER trg_autofill_company BEFORE INSERT ON public.%I FOR EACH ROW EXECUTE PROCEDURE public.autofill_company_id()',
        t);
    END IF;
  END LOOP;
END $$;

-- Done. Verify with:
--   SELECT name, staff_code, manager_code, owner_code FROM public.companies;
