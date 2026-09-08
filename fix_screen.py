import re

with open('lib/features/admin/screens/admin_dashboard_screen.dart', 'r') as f:
    content = f.read()

# We need to change `bool success;` to `String? error;`
# And `success = await ...` to `error = await ...`
# And `success ? 'Éxito' : 'Error'` to `error == null ? 'Éxito' : 'Error: $error'`
# Since there are multiple places:
# 1. Product (createProduct, updateProduct)
# 2. Service (createService, updateService)
# 3. Branch (createBranch, updateBranch)
# 4. User (createUser)

# Let's just do it manually with python replace block by block

# Product
content = content.replace("bool success;", "String? errorMsg;")
content = content.replace("success = await ref.read", "errorMsg = await ref.read")
content = content.replace(
    "content: Text(success ? '¡Producto guardado exitosamente!' : 'No se pudo guardar el producto en Supabase'),",
    "content: Text(errorMsg == null ? '¡Producto guardado exitosamente!' : 'Error: $errorMsg'),"
)
content = content.replace("backgroundColor: success ? Colors.green : AppColors.error,", "backgroundColor: errorMsg == null ? Colors.green : AppColors.error,")

# Service
content = content.replace(
    "content: Text(success ? '¡Servicio guardado exitosamente!' : 'No se pudo guardar el servicio en Supabase'),",
    "content: Text(errorMsg == null ? '¡Servicio guardado exitosamente!' : 'Error: $errorMsg'),"
)

# User
content = content.replace(
    "content: Text(success ? '¡Usuario registrado con éxito en Supabase!' : 'Error al registrar usuario'),",
    "content: Text(errorMsg == null ? '¡Usuario registrado con éxito en Supabase!' : 'Error: $errorMsg'),"
)

# Branch
content = content.replace(
    "content: Text(success ? '¡Sucursal guardada exitosamente en Supabase!' : 'Error al guardar sucursal'),",
    "content: Text(errorMsg == null ? '¡Sucursal guardada exitosamente en Supabase!' : 'Error: $errorMsg'),"
)

# Also fix `final success = await ref.read(adminUsersNotifierProvider.notifier).createUser`
content = content.replace("final success = await ref.read(adminUsersNotifierProvider", "final errorMsg = await ref.read(adminUsersNotifierProvider")


with open('lib/features/admin/screens/admin_dashboard_screen.dart', 'w') as f:
    f.write(content)
