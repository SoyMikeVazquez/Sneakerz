class UserProfile {
  final String id;
  final String? nombre;
  final String? correo;
  final String? telefono;
  final bool isAdmin;
  final bool superAdmin;
  final String? branchId;
  final String? branchName;
  final String? rol;

  UserProfile({
    required this.id,
    this.nombre,
    this.correo,
    this.telefono,
    this.isAdmin = false,
    this.superAdmin = false,
    this.branchId,
    this.branchName,
    this.rol,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rolStr = (json['rol'] ?? json['role'] ?? '').toString().toLowerCase();

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      final str = val.toString().trim().toLowerCase();
      return str == 'true' || str == '1' || str == 't' || str == 'yes';
    }

    // Comprobación de isAdmin
    final isAdminBool = parseBool(json['isAdmin']) ||
        parseBool(json['is_admin']) ||
        parseBool(json['admin']) ||
        rolStr == 'administrador' ||
        rolStr == 'admin' ||
        rolStr == 'superadmin';

    // Comprobación de superAdmin
    final isSuperAdminBool = parseBool(json['superAdmin']) ||
        parseBool(json['super_admin']) ||
        parseBool(json['is_super_admin']) ||
        rolStr == 'superadmin' ||
        rolStr == 'super_administrador';

    return UserProfile(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['name'] ?? json['full_name'])?.toString(),
      correo: (json['correo'] ?? json['email'])?.toString(),
      telefono: (json['telefono'] ?? json['phone'])?.toString(),
      isAdmin: isSuperAdminBool ? true : isAdminBool,
      superAdmin: isSuperAdminBool,
      branchId: (json['branch_id'] ?? json['sucursal_id'] ?? json['sucursal'])?.toString(),
      branchName: (json['sucursal_nombre'] ?? json['branch_name'] ?? json['sucursal'])?.toString(),
      rol: (json['rol'] ?? json['role'] ?? (isSuperAdminBool ? 'SuperAdmin' : (isAdminBool ? 'Administrador' : 'Empleado'))).toString(),
    );
  }
}
