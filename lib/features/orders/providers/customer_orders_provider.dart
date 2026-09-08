import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';

final customerOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final customerId = ref.watch(customerSessionProvider);
  if (customerId == null) return [];

  final supabase = ref.read(supabaseClientProvider);

  try {
    // Obtener los registros asociados a este cliente que no sean citas (solo registros/pedidos)
    final data = await supabase
        .from('Registros|Citas')
        .select('*')
        .eq('id_cliente', customerId)
        .eq('cita', false)
        .order('created_at', ascending: true); // Del más antiguo al más nuevo
        
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
  } catch (e) {
    print('Error loading customer orders: $e');
  }

  return [];
});
