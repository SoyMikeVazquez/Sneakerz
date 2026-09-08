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
    final response = await query;
    print("MATCHING ROWS: " + response.length.toString());
    print("DATA: " + response.toString());
  } catch (e) {
    print("ERROR: " + e.toString());
  }
}
