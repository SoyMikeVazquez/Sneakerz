import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sneakerz_app/core/constants/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sneakerz_app/core/widgets/streetwear_background.dart';
import 'package:sneakerz_app/features/booking/providers/services_provider.dart';
import 'package:sneakerz_app/features/admin/providers/admin_dashboard_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _modelController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedService;
  double _selectedPrice = 150.0;
  String _selectedBranch = 'Sucursal Centro';

  // Fecha y hora seleccionadas
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  // Lista de horarios con intervalos de 30 minutos (10:00 AM a 7:30 PM)
  final List<TimeOfDay> _timeSlots = const [
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 11, minute: 30),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 12, minute: 30),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 13, minute: 30),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 14, minute: 30),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 15, minute: 30),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 16, minute: 30),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 17, minute: 30),
    TimeOfDay(hour: 18, minute: 0),
    TimeOfDay(hour: 18, minute: 30),
    TimeOfDay(hour: 19, minute: 0),
    TimeOfDay(hour: 19, minute: 30),
  ];

  @override
  void initState() {
    super.initState();
    // Por defecto seleccionar el primer slot libre
    _selectedTime = const TimeOfDay(hour: 11, minute: 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Verifica si un slot de horario colisiona en un lapso de 30 minutos con una cita existente
  bool _isSlotOccupied(TimeOfDay slot, List<Map<String, dynamic>> existingAppointments) {
    final slotDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      slot.hour,
      slot.minute,
    );

    // No permitir horas pasadas en el día de hoy
    final now = DateTime.now();
    if (slotDateTime.isBefore(now)) {
      return true;
    }

    for (final app in existingAppointments) {
      final sucursal = app['sucursal']?.toString() ?? 'Sucursal Centro';
      if (sucursal != _selectedBranch) continue;

      final rawDate = app['fecha_cita'] ?? app['created_at'];
      if (rawDate == null) continue;

      final appDateTime = DateTime.tryParse(rawDate.toString());
      if (appDateTime == null) continue;

      // Misma fecha (año, mes, día)
      if (appDateTime.year == slotDateTime.year &&
          appDateTime.month == slotDateTime.month &&
          appDateTime.day == slotDateTime.day) {
        final diffMinutes = slotDateTime.difference(appDateTime).inMinutes.abs();
        // Si hay una cita en un lapso menor a 30 minutos, se bloquea
        if (diffMinutes < 30) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _submitBooking(List<Map<String, dynamic>> existingAppointments) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un horario disponible')),
      );
      return;
    }

    // Validar conflicto de 30 minutos antes de enviar
    if (_isSlotOccupied(_selectedTime!, existingAppointments)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El horario seleccionado ya no está disponible (mínimo 30 min de diferencia). Elige otro.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final errorMsg = await ref.read(adminRegistrosNotifierProvider.notifier).createCita(
          clienteNombre: _nameController.text.trim(),
          telefono: _phoneController.text.trim(),
          correo: _emailController.text.trim(),
          modelo: _modelController.text.trim().isNotEmpty
              ? _modelController.text.trim()
              : 'Sneakers General',
          servicio: _selectedService ?? 'Limpieza Básica',
          sucursal: _selectedBranch,
          fechaCita: appointmentDateTime,
          notas: _notesController.text.trim(),
          total: _selectedPrice,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (errorMsg == null) {
        context.go('/confirmation');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agendar cita: $errorMsg'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);
    final branchesAsync = ref.watch(adminBranchesProvider);
    final registrosAsync = ref.watch(adminRegistrosProvider);
    final existingAppointments = registrosAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Agendar Cita',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: StreetwearBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ENCABEZADO
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reserva tu Espacio',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Text(
                            'Horarios protegidos con intervalo de 30 minutos',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fade(duration: 400.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 24),

                  // DATOS DEL CLIENTE
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Por favor ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de contacto',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Por favor ingresa tu teléfono' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Marca y Modelo de Sneakers (ej. Jordan 1 Retro, Yeezy 350)',
                      prefixIcon: Icon(Icons.snowshoeing_outlined, color: AppColors.textSecondary),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Por favor ingresa el modelo de tus tenis' : null,
                  ),
                  const SizedBox(height: 28),

                  // SELECCIÓN DE SUCURSAL
                  Text('1. Selecciona Sucursal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  branchesAsync.when(
                    data: (branches) {
                      final list = branches.map((b) => b['nombre']?.toString() ?? 'Sucursal').toList();
                      if (list.isEmpty) list.add('Sucursal Centro');
                      if (!list.contains(_selectedBranch)) _selectedBranch = list.first;

                      return DropdownButtonFormField<String>(
                        value: _selectedBranch,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.storefront_outlined)),
                        items: list.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBranch = val);
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(color: AppColors.primary),
                    error: (_, __) => DropdownButtonFormField<String>(
                      value: _selectedBranch,
                      items: const [
                        DropdownMenuItem(value: 'Sucursal Centro', child: Text('Sucursal Centro')),
                        DropdownMenuItem(value: 'Plaza Norte', child: Text('Plaza Norte')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBranch = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // SELECCIÓN DE SERVICIO
                  Text('2. Servicio Deseado', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  servicesAsync.when(
                    data: (services) {
                      if (services.isNotEmpty && _selectedService == null) {
                        _selectedService = services.first.name;
                        _selectedPrice = services.first.price > 0 ? services.first.price : 150.0;
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedService ?? (services.isNotEmpty ? services.first.name : 'Limpieza Básica'),
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.cleaning_services_outlined)),
                        items: services.map((s) => DropdownMenuItem(
                          value: s.name,
                          child: Text('${s.name} ${s.price > 0 ? '(\$${s.price.toStringAsFixed(0)})' : ''}'),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = services.firstWhere((element) => element.name == val);
                            setState(() {
                              _selectedService = val;
                              _selectedPrice = match.price > 0 ? match.price : 150.0;
                            });
                          }
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(color: AppColors.primary),
                    error: (_, __) => const Text('Servicio Estándar (\$150)'),
                  ),
                  const SizedBox(height: 32),

                  // 3. CALENDARIO VISUAL INTERACTIVO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('3. Selecciona el Día', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInteractiveDateCalendar(),
                  const SizedBox(height: 32),

                  // 4. SELECTOR DE HORARIOS CON PROTECCIÓN DE 30 MIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('4. Horarios Disponibles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Libre', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(width: 10),
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red.withOpacity(0.6), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Ocupado', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTimeSlotsGrid(existingAppointments),
                  const SizedBox(height: 28),

                  // NOTAS
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Notas o detalles especiales (opcional)',
                      prefixIcon: Icon(Icons.edit_note_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // BOTÓN DE AGENDAR CITA
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                      ),
                      onPressed: _isSubmitting ? null : () => _submitBooking(existingAppointments),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                          : Text(
                              'Confirmar Cita • \$${_selectedPrice.toStringAsFixed(0)} MXN',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                    ),
                  ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // CALENDARIO HORIZONTAL DE DÍAS
  Widget _buildInteractiveDateCalendar() {
    final now = DateTime.now();
    final days = List.generate(30, (i) => now.add(Duration(days: i)));
    final weekDayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final dayDate = days[index];
          final isSelected = dayDate.year == _selectedDate.year &&
              dayDate.month == _selectedDate.month &&
              dayDate.day == _selectedDate.day;

          final weekDay = weekDayNames[dayDate.weekday - 1];
          final monthName = monthNames[dayDate.month - 1];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = dayDate;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 65,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekDay,
                    style: TextStyle(
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dayDate.day}',
                    style: TextStyle(
                      color: isSelected ? AppColors.background : AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthName,
                    style: TextStyle(
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // GRID DE HORARIOS CON DETECTOR DE COLISIÓN (30 MIN)
  Widget _buildTimeSlotsGrid(List<Map<String, dynamic>> existingAppointments) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        final isOccupied = _isSlotOccupied(slot, existingAppointments);
        final isSelected = _selectedTime != null &&
            _selectedTime!.hour == slot.hour &&
            _selectedTime!.minute == slot.minute &&
            !isOccupied;

        final hourStr = slot.hour.toString().padLeft(2, '0');
        final minStr = slot.minute.toString().padLeft(2, '0');
        final timeLabel = '$hourStr:$minStr';

        return GestureDetector(
          onTap: isOccupied
              ? null
              : () {
                  setState(() {
                    _selectedTime = slot;
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isOccupied
                  ? Colors.red.withOpacity(0.08)
                  : (isSelected ? AppColors.primary : AppColors.surface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOccupied
                    ? Colors.red.withOpacity(0.3)
                    : (isSelected ? AppColors.primary : AppColors.border),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isOccupied)
                    const Padding(
                      padding: EdgeInsets.only(right: 4.0),
                      child: Icon(Icons.block, size: 12, color: Colors.red),
                    ),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: isOccupied
                          ? AppColors.textSecondary.withOpacity(0.5)
                          : (isSelected ? AppColors.background : AppColors.textPrimary),
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 13,
                      decoration: isOccupied ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
