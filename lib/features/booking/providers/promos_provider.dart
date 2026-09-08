import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';
import 'package:sneakerz_app/models/promo_model.dart';

final promosProvider = FutureProvider<List<PromoItem>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final tableNames = ['Promos', 'promos', 'promociones'];

  for (final table in tableNames) {
    try {
      debugPrint('[Supabase Promos] Consultando tabla: $table');
      final data = await supabase.from(table).select('*');
      debugPrint('[Supabase Promos] Datos recibidos de $table: $data');

      if (data is List && data.isNotEmpty) {
        final list = data.map((item) => PromoItem.fromJson(Map<String, dynamic>.from(item))).toList();
        debugPrint('[Supabase Promos] -> ${list.length} promociones cargadas con éxito.');
        return list;
      }
    } catch (e) {
      debugPrint('[Supabase Promos] Error en tabla $table: $e');
    }
  }

  debugPrint('[Supabase Promos] No se encontraron promociones en la base de datos.');
  return [];
});
