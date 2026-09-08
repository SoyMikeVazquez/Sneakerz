import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sneakerz_app/core/constants/theme.dart';
import 'package:sneakerz_app/core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno (.env)
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase con refresco manual de sesión
  await Supabase.initialize(
    url: 'https://xnhbgtonqdupiwvavdew.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhuaGJndG9ucWR1cGl3dmF2ZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDI5MTAsImV4cCI6MjA5MzQ3ODkxMH0.BP53oidioor871kFs-xZki8E1LGBztW283-8vzCzeoM',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: false,
    ),
  );

  runApp(
    const ProviderScope(
      child: SneakerzApp(),
    ),
  );
}

class SneakerzApp extends ConsumerWidget {
  const SneakerzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Sneakerz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
