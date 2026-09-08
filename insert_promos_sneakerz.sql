-- =========================================================================
-- SQL PARA INSERTAR PROMOCIONES ESPECIALES EN SUPABASE
-- Tabla: public.Promos
-- =========================================================================

INSERT INTO public."Promos" (
  titulo_promo, 
  descripcion_prom, 
  imagen_promo, 
  fecha_inicio, 
  fecha_final
) 
VALUES
  (
    '20% OFF en\nLavado Profundo',
    'Aprovecha 20% de descuento en el servicio de lavado profundo durante esta semana.',
    'https://images.unsplash.com/photo-1549298916-b41d501d3772?q=80&w=600&auto=format&fit=crop',
    NOW(),
    NOW() + INTERVAL '30 days'
  ),
  (
    '2x1 en\nRestauración',
    'Trae dos pares y paga solo una restauración de color o mediasuelas.',
    'https://images.unsplash.com/photo-1608231387042-66d1773070a5?q=80&w=600&auto=format&fit=crop',
    NOW(),
    NOW() + INTERVAL '15 days'
  ),
  (
    'Envío Gratis en\n3+ Pares',
    'Recolección y entrega a domicilio totalmente gratis a partir de 3 pares.',
    'https://images.unsplash.com/photo-1552346154-21d32810aba3?q=80&w=600&auto=format&fit=crop',
    NOW(),
    NOW() + INTERVAL '60 days'
  );
