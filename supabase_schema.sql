-- =====================================================
-- SCHEMA COMPLETO Y CORREGIDO PARA QUICKINVENT
-- Ejecuta TODO este archivo en el SQL Editor de Supabase
-- =====================================================

-- 1. TABLA: categories
CREATE TABLE IF NOT EXISTS public.categories (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);

-- 2. TABLA: products
-- (Agregamos min_stock que la app usa para alertas de stock bajo)
-- (Agregamos image_url para almacenar la URL de la imagen del producto)
CREATE TABLE IF NOT EXISTS public.products (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL,
  price numeric NOT NULL,
  stock_quantity integer NOT NULL DEFAULT 0,
  min_stock integer NOT NULL DEFAULT 0,
  barcode text UNIQUE,
  is_active boolean NOT NULL DEFAULT true,
  category_id bigint,
  image_url text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT products_pkey PRIMARY KEY (id),
  CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)
);

-- 3. TABLA: sales
-- (Agregamos received_amount, change, item_count que la app usa en checkout y reportes)
CREATE TABLE IF NOT EXISTS public.sales (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  total_amount numeric NOT NULL,
  payment_method text NOT NULL DEFAULT 'Efectivo',
  received_amount numeric NOT NULL DEFAULT 0,
  change numeric NOT NULL DEFAULT 0,
  item_count integer NOT NULL DEFAULT 0,
  user_id uuid,
  CONSTRAINT sales_pkey PRIMARY KEY (id)
);

-- 4. TABLA: sale_items
-- (Agregamos product_name y subtotal que la app usa para tickets y reportes)
CREATE TABLE IF NOT EXISTS public.sale_items (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  sale_id bigint NOT NULL,
  product_id bigint,
  product_name text,
  quantity integer NOT NULL,
  price_at_sale numeric NOT NULL,
  subtotal numeric NOT NULL DEFAULT 0,
  CONSTRAINT sale_items_pkey PRIMARY KEY (id),
  CONSTRAINT sale_items_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES public.sales(id) ON DELETE CASCADE,
  CONSTRAINT sale_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);

-- 5. TABLA: returns
CREATE TABLE IF NOT EXISTS public.returns (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  product_id bigint NOT NULL,
  quantity integer NOT NULL,
  amount_returned numeric NOT NULL,
  reason text,
  restock boolean NOT NULL DEFAULT false,
  CONSTRAINT returns_pkey PRIMARY KEY (id),
  CONSTRAINT returns_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);

-- 6. TABLA: profiles (extensión de auth.users para guardar nombres)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) - Políticas de seguridad
-- =====================================================

-- Habilitar RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas: usuarios autenticados pueden leer/escribir todo
-- (Ajusta según tus necesidades de seguridad)
-- Eliminamos primero si existen para evitar duplicados
DROP POLICY IF EXISTS "Allow all to authenticated" ON public.categories;
CREATE POLICY "Allow all to authenticated" ON public.categories
FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all to authenticated" ON public.products;
CREATE POLICY "Allow all to authenticated" ON public.products
FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all to authenticated" ON public.sales;
CREATE POLICY "Allow all to authenticated" ON public.sales
FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all to authenticated" ON public.sale_items;
CREATE POLICY "Allow all to authenticated" ON public.sale_items
FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all to authenticated" ON public.returns;
CREATE POLICY "Allow all to authenticated" ON public.returns
FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all to authenticated" ON public.profiles;
CREATE POLICY "Allow all to authenticated" ON public.profiles
FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =====================================================
-- TRIGGER: Auto-crear perfil al registrarse
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Solo crear el trigger si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_new_user();
  END IF;
END
$$;
