import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sneakerz_app/core/constants/colors.dart';
import 'package:sneakerz_app/features/admin/providers/admin_dashboard_provider.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';

class FinanzasBottomSheet extends ConsumerStatefulWidget {
  const FinanzasBottomSheet({super.key});

  @override
  ConsumerState<FinanzasBottomSheet> createState() => _FinanzasBottomSheetState();
}

class _FinanzasBottomSheetState extends ConsumerState<FinanzasBottomSheet> {
  bool _isGasto = false;
  String _tipoIngreso = 'Servicio'; // Servicio, Producto, Propina
  String _metodoPago = 'Efectivo';
  
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();
  final _contactoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _montoController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();
    final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;
    final contacto = _contactoController.text.trim();

    final selectedBranchId = ref.read(selectedBranchIdProvider);
    final userProfile = ref.read(userProfileProvider).value;
    final branchId = selectedBranchId ?? userProfile?.branchId;

    final error = await ref.read(adminFinancesNotifierProvider.notifier).createFinanceRecord(
      nombreRegistro: nombre,
      descripcion: descripcion,
      montoCobrar: monto,
      contacto: contacto,
      metodoPago: _metodoPago,
      isGasto: _isGasto,
      tipoIngreso: _isGasto ? 'Gasto' : _tipoIngreso,
      idSucursal: branchId,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registro financiero guardado con éxito'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isLoading = ref.watch(adminFinancesNotifierProvider).isLoading;

    return Container(
      margin: const EdgeInsets.only(top: kToolbarHeight),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset, left: 20, right: 20, top: 12),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Registro de Finanzas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 20),

                // Selector Ingreso / Gasto
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isGasto = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isGasto ? Colors.green.withOpacity(0.15) : AppColors.surface,
                            border: Border.all(color: !_isGasto ? Colors.green : AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward, color: !_isGasto ? Colors.green : AppColors.textSecondary, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Ingreso',
                                style: TextStyle(
                                  color: !_isGasto ? Colors.green : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isGasto = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isGasto ? AppColors.error.withOpacity(0.15) : AppColors.surface,
                            border: Border.all(color: _isGasto ? AppColors.error : AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, color: _isGasto ? AppColors.error : AppColors.textSecondary, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Gasto',
                                style: TextStyle(
                                  color: _isGasto ? AppColors.error : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Selector Tipo (sólo para ingresos)
                if (!_isGasto) ...[
                  const Text('Tipo de Ingreso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _tipoIngreso,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: ['Servicio', 'Producto', 'Propina'].map((tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                    onChanged: (val) => setState(() => _tipoIngreso = val!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Nombre
                TextFormField(
                  controller: _nombreController,
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  decoration: InputDecoration(
                    labelText: 'Concepto (Ej: Venta de Limpiador)',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Monto
                TextFormField(
                  controller: _montoController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  decoration: InputDecoration(
                    labelText: 'Monto (\$) *',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Método de pago
                DropdownButtonFormField<String>(
                  value: _metodoPago,
                  decoration: InputDecoration(
                    labelText: 'Método de Pago',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: ['Efectivo', 'Tarjeta', 'Transferencia'].map((metodo) {
                    return DropdownMenuItem(value: metodo, child: Text(metodo));
                  }).toList(),
                  onChanged: (val) => setState(() => _metodoPago = val!),
                ),
                const SizedBox(height: 16),

                // Contacto (Opcional)
                TextFormField(
                  controller: _contactoController,
                  decoration: InputDecoration(
                    labelText: 'Contacto / Cliente (Opcional)',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción / Notas (Opcional)',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const CircularProgressIndicator(color: AppColors.background)
                        : Text(
                            _isGasto ? 'Registrar Gasto' : 'Registrar Ingreso',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
