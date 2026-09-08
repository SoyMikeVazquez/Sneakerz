import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://xnhbgtonqdupiwvavdew.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhuaGJndG9ucWR1cGl3dmF2ZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDI5MTAsImV4cCI6MjA5MzQ3ODkxMH0.BP53oidioor871kFs-xZki8E1LGBztW283-8vzCzeoM');
  
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

  var query = supabase.from('Finanzas').select('*');
  query = query.gte('created_at', start.toUtc().toIso8601String());
  query = query.lte('created_at', end.toUtc().toIso8601String());
  
  try {
    final data = await query;
    double ingresos = 0;
    double gastos = 0;
    List<Map<String, dynamic>> transacciones = [];
    
    if (data is List && data.isNotEmpty) {
      transacciones = data.map((e) => Map<String, dynamic>.from(e)).toList();
      for (final item in transacciones) {
        final montoVal = item['monto_cobrar'] ?? item['monto'] ?? item['total'] ?? item['precio'] ?? 0;
        final monto = montoVal is num
            ? montoVal.toDouble()
            : double.tryParse(montoVal.toString()) ?? 0.0;

        final isGasto = item['isGasto'] == true || 
                        item['isgasto'] == true || 
                        item['tipo_ingreso']?.toString().toLowerCase() == 'gasto' ||
                        item['tipo']?.toString().toLowerCase() == 'gasto' || 
                        item['tipo']?.toString().toLowerCase() == 'egreso';

        if (isGasto) {
          gastos += monto;
        } else {
          ingresos += monto;
        }
      }
    }
    print("INGRESOS: \$ingresos");
    print("GASTOS: \$gastos");
    print("BALANCE: \${ingresos - gastos}");
  } catch (e) {
    print("ERROR: " + e.toString());
  }
}
