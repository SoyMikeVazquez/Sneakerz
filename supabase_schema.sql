-- ========================================================
-- ESQUEMA SNEAKERZ APP (Lavado y Restauración de Tenis)
-- ========================================================

-- ========================================================
-- 1. TABLA DE USUARIOS Y ROLES (public.users)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT,
  correo TEXT NOT NULL,
  telefono TEXT,
  id_empleado UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  rol TEXT DEFAULT 'Administrador' CHECK (rol IN ('Lavador', 'Recepcionista', 'Repartidor', 'Administrador')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura de usuarios para autenticados" ON public.users;
DROP POLICY IF EXISTS "Insertar usuarios" ON public.users;
DROP POLICY IF EXISTS "Actualizar propio usuario" ON public.users;

CREATE POLICY "Lectura de usuarios para autenticados" ON public.users FOR SELECT USING (true);
CREATE POLICY "Insertar usuarios" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Actualizar propio usuario" ON public.users FOR UPDATE USING (true);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, id_empleado, correo, nombre, telefono, rol)
  VALUES (
    NEW.id,
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nombre', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'telefono', ''),
    COALESCE(NEW.raw_user_meta_data->>'rol', 'Administrador')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================================
-- 2. TABLA DE CLIENTES (public.clients)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.clients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  apellido TEXT NOT NULL,
  direccion TEXT,
  telefono TEXT NOT NULL,
  email TEXT,
  lead_source TEXT DEFAULT 'App',
  talla_promedio TEXT,
  preferencia_notificacion TEXT DEFAULT 'WhatsApp' CHECK (preferencia_notificacion IN ('WhatsApp', 'Email', 'SMS')),
  status TEXT DEFAULT 'activo',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a clientes" ON public.clients;
CREATE POLICY "Permitir acceso total a clientes" ON public.clients FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- 3. TABLA DE SUCURSALES (public.branches)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.branches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  direccion TEXT NOT NULL,
  latitud NUMERIC(10, 8),
  longitud NUMERIC(11, 8),
  is_open BOOLEAN DEFAULT true,
  horario TEXT DEFAULT 'Lunes a Sábado: 10:00 - 20:00',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a sucursales" ON public.branches;
CREATE POLICY "Permitir acceso total a sucursales" ON public.branches FOR ALL USING (true) WITH CHECK (true);

-- DATOS DE PRUEBA SUCURSALES
-- INSERT INTO public.branches (nombre, direccion) VALUES ('Sucursal Centro', 'Av. Principal #123'), ('Plaza Norte', 'Centro Comercial Plaza Norte, Local 45');

-- ========================================================
-- 4. TABLA DE SERVICIOS CATALOGO (public.services_catalog)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.services_catalog (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  precio_base NUMERIC(10, 2) NOT NULL,
  tipo TEXT DEFAULT 'Lavado' CHECK (tipo IN ('Lavado', 'Restauracion', 'Producto')),
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.services_catalog ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a catalogo" ON public.services_catalog;
CREATE POLICY "Permitir acceso total a catalogo" ON public.services_catalog FOR ALL USING (true) WITH CHECK (true);

-- DATOS DE PRUEBA SERVICIOS
-- INSERT INTO public.services_catalog (nombre, precio_base, tipo) VALUES ('Lavado Básico', 150.00, 'Lavado'), ('Lavado Profundo', 250.00, 'Lavado'), ('Restauración de Color', 450.00, 'Restauracion');

-- ========================================================
-- 5. TABLA DE ÓRDENES (public.orders) - Reemplaza client_jobs
-- ========================================================
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  marca_modelo TEXT NOT NULL,
  servicio_id UUID REFERENCES public.services_catalog(id) ON DELETE SET NULL,
  notas TEXT,
  total NUMERIC(10, 2),
  status TEXT DEFAULT 'recibido' CHECK (status IN ('recibido', 'en_lavado', 'listo_para_entrega', 'entregado', 'cancelado')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a ordenes" ON public.orders;
CREATE POLICY "Permitir acceso total a ordenes" ON public.orders FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- 6. TABLA DE FOTOS DE LA ORDEN (public.order_photos)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.order_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  etapa TEXT DEFAULT 'antes_lavado' CHECK (etapa IN ('antes_lavado', 'despues_lavado')),
  file_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.order_photos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a fotos de ordenes" ON public.order_photos;
CREATE POLICY "Permitir acceso total a fotos de ordenes" ON public.order_photos FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- 7. TABLA DE CONDICIÓN / INSPECCIÓN (public.inspections)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.inspections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  inspector_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  danos_previos TEXT,
  nivel_suciedad TEXT DEFAULT 'Medio' CHECK (nivel_suciedad IN ('Bajo', 'Medio', 'Alto', 'Extremo')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a inspecciones" ON public.inspections;
CREATE POLICY "Permitir acceso total a inspecciones" ON public.inspections FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- 8. TABLA DE PROVEEDORES (public.suppliers)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.suppliers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre_empresa TEXT NOT NULL,
  nombre_contacto TEXT,
  email TEXT,
  telefono TEXT,
  categoria TEXT DEFAULT 'Quimicos',
  direccion TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a proveedores" ON public.suppliers;
CREATE POLICY "Permitir acceso total a proveedores" ON public.suppliers FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- 9. TABLA DE INVENTARIO DEL PROVEEDOR (public.supplier_products)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.supplier_products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE CASCADE,
  nombre_producto TEXT NOT NULL,
  unidad_medida TEXT DEFAULT 'Pza',
  precio_unitario NUMERIC(10, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.supplier_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a productos" ON public.supplier_products;
CREATE POLICY "Permitir acceso total a productos" ON public.supplier_products FOR ALL USING (true) WITH CHECK (true);

-- DATOS DE PRUEBA PROVEEDORES (Limpieza de Tenis)
-- INSERT INTO public.suppliers (nombre_empresa, nombre_contacto, email, categoria) VALUES ('Crep Protect MX', 'Ventas', 'ventas@crep.mx', 'Quimicos'), ('Reshoevn8r Dist', 'Contacto', 'info@reshoevn8r.com', 'Quimicos'), ('Cepillos Premium', 'Luis', 'luis@cepillos.com', 'Herramientas');

-- ========================================================
-- 10. TABLA DE EQUIPOS / STAFF POR SUCURSAL (public.teams)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a equipos" ON public.teams;
CREATE POLICY "Permitir acceso total a equipos" ON public.teams FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- 11. TABLA DE MIEMBROS DE EQUIPO (public.team_members)
-- ========================================================
CREATE TABLE IF NOT EXISTS public.team_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, user_id)
);

ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso total a miembros de equipo" ON public.team_members;
CREATE POLICY "Permitir acceso total a miembros de equipo" ON public.team_members FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- FUNCIONES ADICIONALES
-- ========================================================
CREATE OR REPLACE FUNCTION public.delete_staff_user(target_user_id UUID)
RETURNS void AS $$
BEGIN
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
