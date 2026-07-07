-- 1. Profiles (linked to auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT DEFAULT '',
  address TEXT DEFAULT '',
  role TEXT DEFAULT 'STAFF' CHECK (role IN ('OWNER', 'CO_OWNER', 'STAFF')),
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Trigger to automatically create a profile on user sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role, is_active)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'User'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'role', 'STAFF'),
    TRUE
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. Company Settings
CREATE TABLE IF NOT EXISTS public.company_settings (
  id SERIAL PRIMARY KEY,
  company_name TEXT NOT NULL,
  logo_url TEXT DEFAULT '',
  address_line1 TEXT NOT NULL,
  address_line2 TEXT DEFAULT '',
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  gstin TEXT NOT NULL,
  mobile TEXT NOT NULL,
  email TEXT NOT NULL,
  invoice_prefix TEXT DEFAULT 'S',
  invoice_suffix TEXT DEFAULT '',
  invoice_separator TEXT DEFAULT '-',
  invoice_padding_length INTEGER DEFAULT 6,
  invoice_current_counter INTEGER DEFAULT 0,
  invoice_financial_year TEXT DEFAULT '',
  terms_and_conditions TEXT[] DEFAULT '{}',
  tagline TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  state_with_code TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Coupons
CREATE TABLE IF NOT EXISTS public.coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('PERCENTAGE', 'FIXED')),
  discount_value DOUBLE PRECISION NOT NULL,
  max_discount DOUBLE PRECISION DEFAULT 0,
  min_bill_amount DOUBLE PRECISION DEFAULT 0,
  expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
  usage_limit INTEGER DEFAULT 0,
  starts_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  used_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Customers
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mobile TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  email TEXT DEFAULT '',
  address TEXT NOT NULL,
  pincode TEXT DEFAULT '',
  city TEXT DEFAULT '',
  state TEXT DEFAULT '',
  pan_card TEXT DEFAULT '',
  gst_number TEXT DEFAULT '',
  additional_note TEXT DEFAULT '',
  total_purchase_amount DOUBLE PRECISION DEFAULT 0,
  total_invoices INTEGER DEFAULT 0,
  last_visit_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Daily Rates
CREATE TABLE IF NOT EXISTS public.daily_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date TEXT NOT NULL UNIQUE,
  rate_gold_22k DOUBLE PRECISION NOT NULL,
  rate_gold_18k DOUBLE PRECISION NOT NULL,
  rate_silver DOUBLE PRECISION NOT NULL,
  entered_by UUID REFERENCES auth.users,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Products
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('GOLD', 'SILVER', 'PLATINUM', 'DIAMOND', 'GEMS')),
  purity TEXT NOT NULL CHECK (purity IN ('22K', '18K', 'SILVER')),
  huid_number TEXT UNIQUE,
  hsn_code TEXT DEFAULT '7113' NOT NULL,
  stock_units INTEGER DEFAULT 1,
  weight DOUBLE PRECISION DEFAULT 0,
  stone_type TEXT DEFAULT 'NONE',
  stone_weight DOUBLE PRECISION DEFAULT 0,
  stone_value DOUBLE PRECISION DEFAULT 0,
  image_url TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. Invoices
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT NOT NULL UNIQUE,
  customer_id UUID REFERENCES public.customers ON DELETE SET NULL,
  temp_customer_name TEXT DEFAULT '',
  temp_customer_mobile TEXT DEFAULT '',
  temp_customer_address TEXT DEFAULT '',
  temp_customer_pincode TEXT DEFAULT '',
  temp_customer_city TEXT DEFAULT '',
  temp_customer_state TEXT DEFAULT '',
  gross_amount DOUBLE PRECISION NOT NULL,
  coupon_id UUID REFERENCES public.coupons ON DELETE SET NULL,
  coupon_code TEXT DEFAULT '',
  coupon_discount DOUBLE PRECISION DEFAULT 0,
  old_gold_adjustment_weight DOUBLE PRECISION DEFAULT 0,
  old_gold_adjustment_purity TEXT DEFAULT '',
  old_gold_adjustment_rate_applied DOUBLE PRECISION DEFAULT 0,
  old_gold_adjustment_total_value DOUBLE PRECISION DEFAULT 0,
  taxable_amount DOUBLE PRECISION NOT NULL,
  cgst DOUBLE PRECISION NOT NULL,
  sgst DOUBLE PRECISION NOT NULL,
  total_tax DOUBLE PRECISION NOT NULL,
  net_amount DOUBLE PRECISION NOT NULL,
  final_payable DOUBLE PRECISION NOT NULL,
  payments JSONB DEFAULT '[]'::JSONB,
  total_amount_paid DOUBLE PRECISION DEFAULT 0,
  balance_due DOUBLE PRECISION DEFAULT 0,
  invoice_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  generated_by UUID REFERENCES auth.users NOT NULL,
  status TEXT DEFAULT 'PAID' CHECK (status IN ('PAID', 'PARTIALLY_PAID', 'CANCELLED', 'DELETED')),
  cancellation_reason TEXT DEFAULT '',
  deleted_at TIMESTAMP WITH TIME ZONE,
  rates_snapshot_gold_22k DOUBLE PRECISION DEFAULT 0,
  rates_snapshot_gold_18k DOUBLE PRECISION DEFAULT 0,
  rates_snapshot_silver DOUBLE PRECISION DEFAULT 0,
  items JSONB NOT NULL DEFAULT '[]'::JSONB,
  manual_discount DOUBLE PRECISION DEFAULT 0,
  pdf_base64 TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8. Record Book
CREATE TABLE IF NOT EXISTS public.record_book (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('EXPENSE', 'INCOME')),
  amount DOUBLE PRECISION NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  recorded_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
