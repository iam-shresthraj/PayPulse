-- ============================================================================
-- PayPulse — Migrate existing customer and product names to Title Case / Pascal Case
-- Run this in the Supabase SQL Editor (https://gnyzctxlqcidubanoiae.supabase.co)
-- ============================================================================

-- 1. Update existing customer names
UPDATE public.customers 
SET name = initcap(name) 
WHERE name IS NOT NULL AND name != '';

-- 2. Update existing product names
UPDATE public.products 
SET name = initcap(name) 
WHERE name IS NOT NULL AND name != '';

-- 3. Update existing invoice temporary customer names
UPDATE public.invoices 
SET temp_customer_name = initcap(temp_customer_name) 
WHERE temp_customer_name IS NOT NULL AND temp_customer_name != '';
