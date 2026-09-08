import re

with open('lib/features/admin/providers/admin_dashboard_provider.dart', 'r') as f:
    content = f.read()

# Replace "return false;" with "return 'Error. Revisa reglas RLS y logs de consola.';" 
# ONLY inside the methods that now return Future<String?>.
# Actually, since all boolean returns were for these CRUD ops, we can just replace "return false;" globally in this file, because the only other boolean might be inside some other logic, but looking at the file it's just the CRUD methods. Let's check.
content = content.replace("return false;", "return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';")

with open('lib/features/admin/providers/admin_dashboard_provider.dart', 'w') as f:
    f.write(content)
