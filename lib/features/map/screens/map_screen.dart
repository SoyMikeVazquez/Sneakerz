import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sneakerz_app/core/constants/colors.dart';
import 'package:sneakerz_app/features/admin/providers/admin_dashboard_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _selectedBranchIndex = 0;
  String? _mapboxToken;
  bool _isMapReady = false;

  // Controles de Cámara para Desktop / Web
  double _zoom = 14.5;
  double? _customLat;
  double? _customLng;

  bool get _isDesktopOrWeb =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _initMapbox();
  }

  void _initMapbox() {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    if (token.isNotEmpty) {
      MapboxOptions.setAccessToken(token);
      _mapboxToken = token;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();

    setState(() {
      _isMapReady = true;
    });

    _refreshMarkers();
  }

  List<Map<String, dynamic>> _getValidBranches(List<Map<String, dynamic>> rawBranches) {
    return rawBranches.where((b) {
      final lat = _parseDouble(b['lat'] ?? b['latitud'] ?? b['latitude']);
      final lng = _parseDouble(b['long'] ?? b['lng'] ?? b['longitud'] ?? b['longitude']);
      return lat != null && lng != null && lat != 0.0 && lng != 0.0;
    }).toList();
  }

  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    return double.tryParse(str);
  }

  void _onPanMap(DragUpdateDetails details, double baseLng, double baseLat) {
    final factor = 360.0 / (256.0 * (1 << _zoom.toInt().clamp(1, 20)));
    setState(() {
      _customLng = (_customLng ?? baseLng) - details.delta.dx * factor * 0.45;
      _customLat = (_customLat ?? baseLat) + details.delta.dy * factor * 0.45;
    });
  }

  Future<void> _refreshMarkers() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) return;

    await _pointAnnotationManager?.deleteAll();

    final branchesAsync = ref.read(adminBranchesProvider);
    final rawBranches = branchesAsync.value ?? [];
    final validBranches = _getValidBranches(rawBranches);

    if (validBranches.isEmpty) return;

    for (int i = 0; i < validBranches.length; i++) {
      final branch = validBranches[i];
      final lat = _parseDouble(branch['lat'] ?? branch['latitud'] ?? branch['latitude'])!;
      final lng = _parseDouble(branch['long'] ?? branch['lng'] ?? branch['longitud'] ?? branch['longitude'])!;
      final name = (branch['nombre_sucursal'] ?? branch['nombre'] ?? branch['name'] ?? 'Sucursal').toString();

      await _pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          textField: name,
          textSize: 12.0,
          textColor: 0xFF000000,
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 2.0,
          textOffset: [0.0, 1.2],
          iconSize: 1.3,
        ),
      );
    }

    if (validBranches.isNotEmpty) {
      _flyToBranch(validBranches[0]);
    }
  }

  void _flyToBranch(Map<String, dynamic> branch) {
    final lat = _parseDouble(branch['lat'] ?? branch['latitud'] ?? branch['latitude']);
    final lng = _parseDouble(branch['long'] ?? branch['lng'] ?? branch['longitud'] ?? branch['longitude']);

    if (lat != null && lng != null) {
      if (_isDesktopOrWeb) {
        setState(() {
          _customLat = lat;
          _customLng = lng;
          _zoom = 14.5;
        });
      } else if (_mapboxMap != null) {
        _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lng, lat)),
            zoom: 14.5,
            pitch: 25.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    }
  }

  Future<void> _openExternalMaps(double lat, double lng, String name) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(adminBranchesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. MAPA DE FONDO COMPLETO (100% de la pantalla)
          Positioned.fill(
            child: _isDesktopOrWeb
                ? branchesAsync.when(
                    data: (rawBranches) {
                      final valid = _getValidBranches(rawBranches);
                      final selectedBranch = valid.isNotEmpty
                          ? valid[_selectedBranchIndex.clamp(0, valid.length - 1)]
                          : null;
                      final baseLat = selectedBranch != null
                          ? (_parseDouble(selectedBranch['lat'] ?? selectedBranch['latitud'] ?? selectedBranch['latitude']) ?? 25.6866)
                          : 25.6866;
                      final baseLng = selectedBranch != null
                          ? (_parseDouble(selectedBranch['long'] ?? selectedBranch['lng'] ?? selectedBranch['longitud'] ?? selectedBranch['longitude']) ?? -100.3161)
                          : -100.3161;

                      final currentLat = _customLat ?? baseLat;
                      final currentLng = _customLng ?? baseLng;

                      // URL limpia para Mapbox Static en gris claro
                      final staticUrl = (_mapboxToken != null && _mapboxToken!.isNotEmpty)
                          ? 'https://api.mapbox.com/styles/v1/mapbox/light-v11/static/${currentLng.toStringAsFixed(6)},${currentLat.toStringAsFixed(6)},${_zoom.toStringAsFixed(1)},0/1000x800?access_token=$_mapboxToken'
                          : '';

                      if (staticUrl.isEmpty) {
                        return Container(
                          color: const Color(0xFFE5E9EE),
                          child: const Center(
                            child: Text('Mapbox token no configurado en .env', style: TextStyle(color: Colors.red)),
                          ),
                        );
                      }

                      return GestureDetector(
                        onPanUpdate: (details) => _onPanMap(details, baseLng, baseLat),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              staticUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: const Color(0xFFE5E9EE),
                                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                                );
                              },
                              errorBuilder: (ctx, err, stack) => Container(
                                color: const Color(0xFFE5E9EE),
                                child: Center(
                                  child: Text(
                                    'Error al cargar imagen del mapa: $err',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                                  ),
                                ),
                              ),
                            ),

                            // PIN FLOTANTE EN EL CENTRO
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 38.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (selectedBranch != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.88),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6),
                                            ],
                                          ),
                                          child: Text(
                                            selectedBranch['nombre_sucursal'] ?? selectedBranch['nombre'] ?? selectedBranch['name'] ?? 'Sucursal',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      const Icon(Icons.location_pin, size: 46, color: AppColors.accent),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Botones flotantes de Zoom (+ / -)
                            Positioned(
                              top: 90,
                              right: 16,
                              child: Column(
                                children: [
                                  Material(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 3,
                                    child: IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        if (_zoom < 19) setState(() => _zoom += 1);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Material(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 3,
                                    child: IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        if (_zoom > 3) setState(() => _zoom -= 1);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, _) => Container(
                      color: const Color(0xFFE5E9EE),
                      child: Center(child: Text('Error: $err')),
                    ),
                  )
                : (_mapboxToken != null && _mapboxToken!.isNotEmpty
                    ? MapWidget(
                        key: const ValueKey("mapbox_screen_widget"),
                        onMapCreated: _onMapCreated,
                        styleUri: MapboxStyles.LIGHT,
                      )
                    : Container(
                        color: const Color(0xFFE5E9EE),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No se encontró el token de Mapbox en .env',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )),
          ),

          // 2. Header superior flotante
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        const Text(
                          'Nuestras Sucursales',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        branchesAsync.when(
                          data: (list) {
                            final valid = _getValidBranches(list);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${valid.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Botón para refrescar
                  Material(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                      onPressed: () {
                        setState(() {
                          _customLat = null;
                          _customLng = null;
                        });
                        ref.invalidate(adminBranchesProvider);
                        if (_isMapReady) {
                          _refreshMarkers();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Carousel de Sucursales en la parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: branchesAsync.when(
              data: (rawBranches) {
                final validBranches = _getValidBranches(rawBranches);

                if (validBranches.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.accent, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No hay sucursales con coordenadas registradas aún. Agrégalas desde el Dashboard de Administrador.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 155,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: validBranches.length,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedBranchIndex = index;
                      });
                      _flyToBranch(validBranches[index]);
                    },
                    itemBuilder: (context, index) {
                      final branch = validBranches[index];
                      final isSelected = index == _selectedBranchIndex;
                      final nombre = branch['nombre_sucursal'] ?? branch['nombre'] ?? branch['name'] ?? 'Sucursal';
                      final direccion = branch['direccion'] ?? branch['address'] ?? branch['ubicacion'] ?? 'Sin dirección';
                      final horario = branch['horario'] ?? branch['schedule'] ?? 'Horario no especificado';
                      final telefono = branch['telefono'] ?? branch['phone'];
                      final imagen = branch['imagen_sucursal'] ?? branch['imagen'] ?? branch['image'] ?? branch['foto'];
                      final isOpen = branch['is_open'] == true || branch['is_active'] == true || branch['activo'] == true;
                      final lat = _parseDouble(branch['lat'] ?? branch['latitud'] ?? branch['latitude']) ?? 0.0;
                      final lng = _parseDouble(branch['long'] ?? branch['lng'] ?? branch['longitud'] ?? branch['longitude']) ?? 0.0;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: isSelected ? 2 : 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.black12,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.06),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Imagen de sucursal
                            if (imagen != null && imagen.toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  imagen.toString(),
                                  width: 80,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 110,
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    child: const Icon(Icons.storefront, color: AppColors.primary, size: 28),
                                  ),
                                ),
                              ),
                            if (imagen != null && imagen.toString().isNotEmpty)
                              const SizedBox(width: 12),

                            // Detalles de sucursal
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Fila Superior: Nombre y Estado
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          nombre,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOpen
                                              ? AppColors.success.withValues(alpha: 0.12)
                                              : Colors.grey.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isOpen ? 'Abierto' : 'Cerrado',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isOpen ? AppColors.success : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Dirección
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          direccion,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // Horario
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          horario,
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Botones de Acción
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _openExternalMaps(lat, lng, nombre),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                          icon: const Icon(Icons.navigation_outlined, size: 12),
                                          label: const Text(
                                            'Cómo llegar',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      if (telefono != null && telefono.toString().isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        OutlinedButton(
                                          onPressed: () => _callPhone(telefono.toString()),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: AppColors.border),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Icon(Icons.phone_outlined, size: 14),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Error al cargar sucursales: $err', style: const TextStyle(fontSize: 12, color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
