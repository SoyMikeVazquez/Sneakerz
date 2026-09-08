import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sneakerz_app/models/user_profile.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Proveedor de usuario actual administrado manualmente
final currentUserProvider = StateProvider<User?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.currentUser;
});

// Proveedor de perfil detallado de usuario (isAdmin, superAdmin, sucursal)
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = ref.watch(supabaseClientProvider);
  try {
    var data;
    try {
      // 1. Intentar por ID (Falla si id es int8 y auth.uid es uuid)
      data = await supabase.from('users').select('*').eq('id', user.id).maybeSingle();
    } catch (e) {
      debugPrint('[Auth] Error querying by id: $e');
    }

    if (data == null) {
      try {
        // 2. Intentar por correo
        data = await supabase.from('users').select('*').eq('correo', user.email ?? '').maybeSingle();
      } catch (e) {
        debugPrint('[Auth] Error querying by correo: $e');
      }
    }

    if (data == null) {
      try {
        // 3. Intentar por email
        data = await supabase.from('users').select('*').eq('email', user.email ?? '').maybeSingle();
      } catch (e) {
        debugPrint('[Auth] Error querying by email: $e');
      }
    }

    if (data != null) {
      debugPrint('[Auth] Data de perfil obtenida: $data');
      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    }
  } catch (e) {
    debugPrint('[Auth] Error al consultar perfil de users en Supabase: $e');
  }

  // Si no se encuentra fila en tabla users, usar metadata o fallback de staff
  return UserProfile(
    id: user.id,
    correo: user.email,
    nombre: user.userMetadata?['nombre'] ?? user.email?.split('@').first,
    isAdmin: true,
    superAdmin: false,
  );
});

// Proveedor para mantener la sesión local del cliente (basada en el ID de la tabla clients)
final customerSessionProvider = StateProvider<String?>((ref) => null);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AuthNotifier(this._supabase, this._ref) : super(const AsyncValue.data(null));

  // Iniciar sesión Staff
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _ref.read(currentUserProvider.notifier).state = response.user;
      _ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Refrescar sesión de manera manual
  Future<void> refreshSessionManually() async {
    try {
      final response = await _supabase.auth.refreshSession();
      _ref.read(currentUserProvider.notifier).state = response.user;
      _ref.invalidate(userProfileProvider);
    } catch (_) {
      _ref.read(currentUserProvider.notifier).state = _supabase.auth.currentUser;
    }
  }

  // Registro de usuario
  Future<void> signUp(String email, String password, String fullName) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      _ref.read(currentUserProvider.notifier).state = response.user;
      _ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _supabase.auth.signOut();
      _ref.read(currentUserProvider.notifier).state = null;
      _ref.read(customerSessionProvider.notifier).state = null;
      _ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Iniciar sesión como cliente (solo con teléfono)
  Future<String?> signInAsCustomer(String phone) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase
          .from('clientes')
          .select('id_cliente')
          .eq('telefono', phone)
          .maybeSingle();

      String customerId;

      if (response != null) {
        customerId = response['id_cliente'].toString();
      } else {
        final insertResponse = await _supabase
            .from('clientes')
            .insert({
              'telefono': phone,
              'nombre': 'Cliente'
            })
            .select('id_cliente')
            .single();
        customerId = insertResponse['id_cliente'].toString();
      }

      _ref.read(customerSessionProvider.notifier).state = customerId;
      state = const AsyncValue.data(null);
      return customerId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  // Registrar cliente con más campos
  Future<Map<String, dynamic>> registerCustomerWithResult(String phone, String name, String email, String sucursalId) async {
    state = const AsyncValue.loading();
    try {
      final existing = await _supabase
          .from('clientes')
          .select('id_cliente')
          .eq('telefono', phone)
          .maybeSingle();

      String customerId;

      if (existing != null) {
        customerId = existing['id_cliente'].toString();
        await _supabase
            .from('clientes')
            .update({
              'nombre': name,
              if (email.trim().isNotEmpty) 'correo': email.trim(),
              'sucursal_asociado': int.tryParse(sucursalId) ?? sucursalId,
            })
            .eq('id_cliente', int.parse(customerId));
      } else {
        final insertData = <String, dynamic>{
          'telefono': int.tryParse(phone) ?? phone,
          'nombre': name,
          'sucursal_asociado': int.tryParse(sucursalId) ?? sucursalId,
          'created_at': DateTime.now().toIso8601String(),
        };
        if (email.trim().isNotEmpty) {
          insertData['correo'] = email.trim();
        }

        final insertResponse = await _supabase
            .from('clientes')
            .insert(insertData)
            .select('id_cliente')
            .single();
        customerId = insertResponse['id_cliente'].toString();
      }

      _ref.read(customerSessionProvider.notifier).state = customerId;
      state = const AsyncValue.data(null);
      return {'success': true, 'id': customerId};
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return {'success': false, 'error': e.toString()};
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider), ref);
});
