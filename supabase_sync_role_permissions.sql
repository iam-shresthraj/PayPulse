-- ============================================================================
-- PayPulse — Role Permissions Sync to Existing Users Fix
-- Run this in the Supabase SQL Editor (https://gnyzctxlqcidubanoiae.supabase.co)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_role_permissions(
  p_staff_dashboard BOOLEAN,
  p_staff_invoices BOOLEAN,
  p_staff_customers BOOLEAN,
  p_staff_inventory BOOLEAN,
  p_staff_reports BOOLEAN,
  p_staff_records BOOLEAN,
  p_staff_rates BOOLEAN,
  p_staff_staff BOOLEAN,
  p_staff_settings BOOLEAN,
  p_staff_coupons BOOLEAN,
  p_manager_dashboard BOOLEAN,
  p_manager_invoices BOOLEAN,
  p_manager_customers BOOLEAN,
  p_manager_inventory BOOLEAN,
  p_manager_reports BOOLEAN,
  p_manager_records BOOLEAN,
  p_manager_rates BOOLEAN,
  p_manager_staff BOOLEAN,
  p_manager_settings BOOLEAN,
  p_manager_coupons BOOLEAN
) RETURNS VOID AS $$
DECLARE
  v_company_id UUID;
BEGIN
  IF public.current_role_pp() <> 'OWNER' THEN
    RAISE EXCEPTION 'Only owners can modify role permissions';
  END IF;

  v_company_id := public.current_company_id();

  -- 1. Update company settings/defaults
  UPDATE public.companies
  SET staff_access_dashboard = p_staff_dashboard,
      staff_access_invoices = p_staff_invoices,
      staff_access_customers = p_staff_customers,
      staff_access_inventory = p_staff_inventory,
      staff_access_reports = p_staff_reports,
      staff_access_records = p_staff_records,
      staff_access_rates = p_staff_rates,
      staff_access_staff = p_staff_staff,
      staff_access_settings = p_staff_settings,
      staff_access_coupons = p_staff_coupons,
      manager_access_dashboard = p_manager_dashboard,
      manager_access_invoices = p_manager_invoices,
      manager_access_customers = p_manager_customers,
      manager_access_inventory = p_manager_inventory,
      manager_access_reports = p_manager_reports,
      manager_access_records = p_manager_records,
      manager_access_rates = p_manager_rates,
      manager_access_staff = p_manager_staff,
      manager_access_settings = p_manager_settings,
      manager_access_coupons = p_manager_coupons
  WHERE id = v_company_id;

  -- 2. Update existing staff member profiles
  UPDATE public.profiles
  SET access_dashboard = p_staff_dashboard,
      access_invoices = p_staff_invoices,
      access_customers = p_staff_customers,
      access_inventory = p_staff_inventory,
      access_reports = p_staff_reports,
      access_records = p_staff_records,
      access_rates = p_staff_rates,
      access_staff = p_staff_staff,
      access_settings = p_staff_settings,
      access_coupons = p_staff_coupons
  WHERE company_id = v_company_id AND role = 'STAFF';

  -- 3. Update existing manager profiles
  UPDATE public.profiles
  SET access_dashboard = p_manager_dashboard,
      access_invoices = p_manager_invoices,
      access_customers = p_manager_customers,
      access_inventory = p_manager_inventory,
      access_reports = p_manager_reports,
      access_records = p_manager_records,
      access_rates = p_manager_rates,
      access_staff = p_manager_staff,
      access_settings = p_manager_settings,
      access_coupons = p_manager_coupons
  WHERE company_id = v_company_id AND role = 'MANAGER';

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.update_role_permissions(BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) TO authenticated;
