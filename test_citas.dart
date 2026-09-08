import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://xnhbgtonqdupiwvavdew.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhuaGJndG9ucWR1cGl3dmF2ZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDI5MTAsImV4cCI6MjA5MzQ3ODkxMH0.BP53oidioor871kFs-xZki8E1LGBztW283-8vzCzeoM');
  
  try {
    final response = await supabase.from('Registros|Citas').select('*').limit(1);
    print("CITAS SUCCESS");
  } catch (e) {
    print("CITAS ERROR: " + e.toString());
  }
}
