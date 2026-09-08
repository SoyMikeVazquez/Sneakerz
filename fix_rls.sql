-- Ejecuta este código en el SQL Editor de Supabase

-- 1. Primero, asegúrate de que el usuario logueado como SuperAdmin pueda actualizar la tabla users.
-- Crea una política para permitir a los SuperAdmins actualizar y crear usuarios:
CREATE POLICY "SuperAdmins can all on users" 
ON public.users 
FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE correo = (auth.jwt() ->> 'email')::text AND "superAdmin" = true
  )
);

-- 2. Si ya tienes políticas que restringen INSERT o UPDATE, esta política anterior les dará acceso total a los SuperAdmins.
