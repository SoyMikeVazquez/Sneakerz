import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sneakerz_app/core/constants/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIImageUploadSection extends ConsumerStatefulWidget {
  const AIImageUploadSection({super.key});

  @override
  ConsumerState<AIImageUploadSection> createState() => _AIImageUploadSectionState();
}

class _AIImageUploadSectionState extends ConsumerState<AIImageUploadSection> {
  bool _isUploading = false;
  String? _uploadedImageUrl;
  String? _errorMessage;

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.name.contains('.') ? pickedFile.name.split('.').last : 'jpg';
      final fileName = 'ia_sneakers_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final supabase = ref.read(supabaseClientProvider);

      // Subir archivo al bucket 'general'
      await supabase.storage.from('general').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      // Obtener URL pública
      final publicUrl = supabase.storage.from('general').getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _uploadedImageUrl = publicUrl;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Imagen subida con éxito al bucket general!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Error al subir imagen. Verifica los permisos de tu bucket.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isUploading) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Subiendo imagen a Supabase Storage (bucket: general)...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ] else if (_uploadedImageUrl != null) ...[
            // Vista con la imagen ya subida
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _uploadedImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: AppColors.border.withOpacity(0.2),
                  child: const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Guardada en bucket general',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Diagnóstico IA (Próximamente)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La Inteligencia Artificial se conectará posteriormente para analizar el desgaste, manchas y darte el resultado exacto del tratamiento recomendado.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
              label: const Text(
                'Subir otra imagen',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            // Estado inicial para subir
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Sube una foto de tus Sneakers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nuestra IA analizará el estado de la piel, suela y manchas para recomendarte el mejor servicio.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ℹ️ La IA se conectará posteriormente para dar el resultado',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _pickAndUploadImage,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text(
                  'Subir Imagen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    ).animate().fade(duration: 600.ms, delay: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
