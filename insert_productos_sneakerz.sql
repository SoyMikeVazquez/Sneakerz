-- =========================================================================
-- SQL PARA INSERTAR PRODUCTOS DE ACOMPAÑAMIENTO Y CUIDADO DE SNEAKERS
-- Proyecto: Sneakerz
-- =========================================================================

-- Opción 1: Si tu tabla se llama "Productos" o "productos" con columnas en español/inglés:
-- Asegúrate de que los nombres de las columnas coincidan con tu tabla en Supabase.

-- Inserción en tabla Productos (columnas comunes: nombre/title, descripcion/description, precio/price, image/imagen/image_url, categoria)
INSERT INTO public."Productos" (title, description, price, image, category) 
VALUES
  (
    'Toallitas Quick Clean (Pack 12)',
    'Toallitas de doble textura para limpieza rápida de suelas y piel.',
    120.00,
    'https://images.unsplash.com/photo-1595950653106-6c9ebd614c3a?q=80&w=400&auto=format&fit=crop',
    'Cuidado Rápido'
  ),
  (
    'Nano Spray Repelente 200ml',
    'Crea una capa hidrofóbica invisible contra agua, manchas y líquidos.',
    280.00,
    'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?q=80&w=400&auto=format&fit=crop',
    'Protección'
  ),
  (
    'Toalla Microfibra Ultra-Plush',
    'Microfibra sin costuras de alta absorción para secado y pulido sin rayar.',
    95.00,
    'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?q=80&w=400&auto=format&fit=crop',
    'Accesorios'
  ),
  (
    'Crease Protectors (Escudos Antiarrugas)',
    'Protege la puntera de tus sneakers evitando que se doblen o deformen al caminar.',
    150.00,
    'https://images.unsplash.com/photo-1608231387042-66d1773070a5?q=80&w=400&auto=format&fit=crop',
    'Estructura'
  ),
  (
    'Cápsulas Desodorizantes & Anti-humedad',
    'Neutraliza malos olores y absorbe la humedad dejando un aroma fresco.',
    140.00,
    'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=400&auto=format&fit=crop',
    'Higiene'
  ),
  (
    'Cepillo de Cerdas de Cerdo Premium',
    'Ideal para materiales delicados como gamuza, nubuck, malla y knit.',
    160.00,
    'https://images.unsplash.com/photo-1603487742131-4160ec999306?q=80&w=400&auto=format&fit=crop',
    'Herramientas'
  );

-- =========================================================================
-- Si tus columnas en la tabla "Productos" están en español (nombre, descripcion, precio, imagen):
-- =========================================================================
/*
INSERT INTO public."Productos" (nombre, descripcion, precio, imagen, categoria) 
VALUES
  ('Toallitas Quick Clean (Pack 12)', 'Toallitas de doble textura para limpieza rápida de suelas y piel.', 120.00, 'https://images.unsplash.com/photo-1595950653106-6c9ebd614c3a?q=80&w=400&auto=format&fit=crop', 'Cuidado Rápido'),
  ('Nano Spray Repelente 200ml', 'Crea una capa hidrofóbica invisible contra agua, manchas y líquidos.', 280.00, 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?q=80&w=400&auto=format&fit=crop', 'Protección'),
  ('Toalla Microfibra Ultra-Plush', 'Microfibra sin costuras de alta absorción para secado y pulido sin rayar.', 95.00, 'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?q=80&w=400&auto=format&fit=crop', 'Accesorios'),
  ('Crease Protectors (Escudos Antiarrugas)', 'Protege la puntera de tus sneakers evitando que se doblen o deformen al caminar.', 150.00, 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?q=80&w=400&auto=format&fit=crop', 'Estructura'),
  ('Cápsulas Desodorizantes & Anti-humedad', 'Neutraliza malos olores y absorbe la humedad dejando un aroma fresco.', 140.00, 'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?q=80&w=400&auto=format&fit=crop', 'Higiene'),
  ('Cepillo de Cerdas de Cerdo Premium', 'Ideal para materiales delicados como gamuza, nubuck, malla y knit.', 160.00, 'https://images.unsplash.com/photo-1603487742131-4160ec999306?q=80&w=400&auto=format&fit=crop', 'Herramientas');
*/
