import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';
import 'package:sneakerz_app/models/product_model.dart';

final productsProvider = FutureProvider<List<ProductItem>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final tableNames = ['Productos', 'productos', 'products', 'supplier_products'];

  for (final table in tableNames) {
    try {
      debugPrint('[Supabase Products] Consultando tabla: $table');
      final data = await supabase.from(table).select('*');
      debugPrint('[Supabase Products] Datos recibidos de $table: $data');

      if (data is List && data.isNotEmpty) {
        final list = data.map((item) => ProductItem.fromJson(Map<String, dynamic>.from(item))).toList();
        debugPrint('[Supabase Products] -> ${list.length} productos cargados con éxito desde $table.');
        return list;
      }
    } catch (e) {
      debugPrint('[Supabase Products] Error en tabla $table: $e');
    }
  }

  debugPrint('[Supabase Products] No se encontraron productos en la base de datos.');
  return [];
});
