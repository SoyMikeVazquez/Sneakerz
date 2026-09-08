import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sneakerz_app/core/constants/colors.dart';
import 'package:sneakerz_app/core/widgets/streetwear_background.dart';
import 'package:sneakerz_app/features/orders/providers/customer_orders_provider.dart';
import 'package:intl/intl.dart';

class OrderStatusScreen extends ConsumerWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      body: StreetwearBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Text(
                  'Mis Pedidos',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ordersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(orders[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
              const SizedBox(height: 80), // Espacio para el BottomNav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.border.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No tienes pedidos activos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando dejes un par o bolsa,\naparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? '').toString().toLowerCase();
    final model = order['modelo'] ?? 'Producto';
    final service = order['servicio'] ?? 'Servicio';
    final imageUrl = order['image'];
    
    // Parse date
    String dateStr = '';
    if (order['created_at'] != null) {
      try {
        final date = DateTime.parse(order['created_at']);
        dateStr = DateFormat('dd MMM yyyy').format(date);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        image: imageUrl != null && imageUrl.toString().isNotEmpty
                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl == null || imageUrl.toString().isEmpty
                          ? const Icon(Icons.shopping_bag, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          if (dateStr.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Ingresado: $dateStr',
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Timeline
                _buildTimeline(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    int currentStep = 0;
    
    // Normalizar estatus (incluye compatibilidad hacia atrás)
    if (currentStatus == 'servicio_iniciado' || currentStatus == 'recibido') {
      currentStep = 1;
    } else if (currentStatus == 'servicio_realizandose' || currentStatus == 'en_lavado') {
      currentStep = 2;
    } else if (currentStatus == 'servicio_listo_para_entregar' || currentStatus == 'listo_para_entrega' || currentStatus == 'listo') {
      currentStep = 3;
    } else if (currentStatus == 'entregado') {
      currentStep = 4;
    }

    return Row(
      children: [
        _buildTimelineStep(1, 'Iniciado', currentStep >= 1, isFirst: true),
        _buildTimelineLine(currentStep >= 2),
        _buildTimelineStep(2, 'En Proceso', currentStep >= 2),
        _buildTimelineLine(currentStep >= 3),
        _buildTimelineStep(3, 'Listo', currentStep >= 3, isLast: true),
      ],
    );
  }

  Widget _buildTimelineStep(int step, String label, bool isActive, {bool isFirst = false, bool isLast = false}) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Icon(
            isActive ? Icons.check : Icons.circle,
            size: 16,
            color: isActive ? AppColors.background : Colors.transparent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine(bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 2,
        color: isActive ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
