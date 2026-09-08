import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://xnhbgtonqdupiwvavdew.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhuaGJndG9ucWR1cGl3dmF2ZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDI5MTAsImV4cCI6MjA5MzQ3ODkxMH0.BP53oidioor871kFs-xZki8E1LGBztW283-8vzCzeoM');
  
  try {
    final payload = {
        'nombre_registro': 'Test Debug Insert',
        'monto_cobrar': 99.99,
        'metodo_pago': 'Efectivo',
        'isGasto': true,
        'tipo_ingreso': 'Gasto'
    };
    final response = await supabase.from('Finanzas').insert(payload).select();
    print("INSERT SUCCESS: " + response.toString());
  } catch (e) {
    print("INSERT ERROR: " + e.toString());
  }
}
