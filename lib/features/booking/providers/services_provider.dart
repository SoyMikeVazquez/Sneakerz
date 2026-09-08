import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';
import 'package:sneakerz_app/models/service_model.dart';

final servicesProvider = FutureProvider<List<ServiceItem>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final tableNames = ['servicios', 'services', 'services_catalog'];

  for (final table in tableNames) {
    try {
      debugPrint('[Supabase Services] Consultando tabla: $table');
      final data = await supabase.from(table).select('*');
      debugPrint('[Supabase Services] Datos recibidos de $table: $data');

      if (data is List && data.isNotEmpty) {
        final list = data.map((item) => ServiceItem.fromJson(Map<String, dynamic>.from(item))).toList();
        debugPrint('[Supabase Services] -> ${list.length} servicios listados correctamente.');
        return list;
      }
    } catch (e) {
      debugPrint('[Supabase Services] Error en tabla $table: $e');
    }
  }

  return [];
});
