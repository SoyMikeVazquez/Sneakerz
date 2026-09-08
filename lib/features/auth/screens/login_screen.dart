import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sneakerz_app/core/constants/colors.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';
import 'package:sneakerz_app/features/admin/providers/admin_dashboard_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Toggle: true = Cliente, false = Staff
  bool _isCustomerMode = true;
  bool _isRegistering = false;
  String? _selectedBranchId;

  // Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _customerEmailController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (_isCustomerMode) {
        if (_isRegistering) {
          if (_selectedBranchId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Por favor, selecciona una sucursal'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
          // FLUJO REGISTRO CLIENTE
          final result = await ref.read(authNotifierProvider.notifier)
              .registerCustomerWithResult(
                _phoneController.text.trim(),
                _nameController.text.trim(),
                _customerEmailController.text.trim(),
                _selectedBranchId!,
              );
              
          if (mounted) {
            if (result['success'] == true) {
              ref.read(customerSessionProvider.notifier).state = result['id'];
              context.go('/orders');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al registrar: ${result['error']}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        } else {
          // FLUJO LOGIN CLIENTE (Teléfono)
          final customerId = await ref.read(authNotifierProvider.notifier)
              .signInAsCustomer(_phoneController.text.trim());
              
          if (mounted) {
            if (customerId != null) {
              // Guardar sesión localmente
              ref.read(customerSessionProvider.notifier).state = customerId;
              context.go('/orders');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al acceder. Intenta nuevamente.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        }
      } else {
        // FLUJO STAFF (Supabase Auth)
        await ref.read(authNotifierProvider.notifier).signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        
        if (mounted) {
          final authState = ref.read(authNotifierProvider);
          if (authState.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: Credenciales incorrectas'),
                backgroundColor: AppColors.error,
              ),
            );
          } else {
            final profile = await ref.read(userProfileProvider.future);
            if (profile != null && (profile.isAdmin || profile.superAdmin)) {
              context.go('/admin');
            } else {
              context.go('/');
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final customerSession = ref.watch(customerSessionProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final branchesAsync = ref.watch(adminBranchesProvider);
    final isLoggedIn = currentUser != null || customerSession != null;

    if (isLoggedIn) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 64, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    currentUser != null ? 'Sesión de Staff' : 'Sesión de Cliente',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUser != null ? (currentUser.email ?? 'Staff') : 'Teléfono registrado',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (currentUser != null)
                    profileAsync.when(
                      data: (profile) {
                        if (profile != null && (profile.isAdmin || profile.superAdmin)) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.background,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () => context.push('/admin'),
                                icon: const Icon(Icons.dashboard_customize_outlined),
                                label: Text(
                                  profile.superAdmin
                                      ? 'Ir a Dashboard (SuperAdmin)'
                                      : 'Ir a Dashboard (Administración)',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        if (currentUser != null) {
                          await ref.read(authNotifierProvider.notifier).signOut();
                        }
                        ref.read(customerSessionProvider.notifier).state = null;
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sneakerz.',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCustomerMode ? 'Rastrea tus Sneakers' : 'Acceso a Empleados',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Toggle Switch
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isCustomerMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isCustomerMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Soy Cliente',
                                style: TextStyle(
                                  color: _isCustomerMode ? AppColors.background : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isCustomerMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isCustomerMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Soy Staff',
                                style: TextStyle(
                                  color: !_isCustomerMode ? AppColors.background : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_isCustomerMode) ...[
                    if (_isRegistering) ...[
                      // Inputs Registro Cliente
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico (Opcional)',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Selector de Sucursal
                      branchesAsync.when(
                        data: (branches) {
                          return DropdownButtonFormField<String>(
                            value: _selectedBranchId,
                            decoration: const InputDecoration(
                              labelText: 'Sucursal de preferencia',
                              prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.textSecondary),
                            ),
                            items: branches.map((b) {
                              final bName = (b['nombre'] ?? b['name'] ?? 'Sucursal').toString();
                              final bId = b['id']?.toString();
                              return DropdownMenuItem(
                                value: bId,
                                child: Text(bName, style: const TextStyle(color: AppColors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedBranchId = val;
                              });
                            },
                            validator: (value) => value == null ? 'Selecciona una sucursal' : null,
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text('Error al cargar sucursales', style: TextStyle(color: AppColors.error)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Input Teléfono Cliente (Login y Registro)
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Número de Teléfono',
                        prefixText: '+52 ',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 10) {
                          return 'Ingresa un número válido de 10 dígitos';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    // Inputs Staff
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _login,
                      child: authState.isLoading
                          ? const CircularProgressIndicator(color: AppColors.background)
                          : Text(_isCustomerMode 
                              ? (_isRegistering ? 'Crear Cuenta' : 'Entrar') 
                              : 'Iniciar Sesión'),
                    ),
                  ),
                  
                  if (_isCustomerMode) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isRegistering = !_isRegistering;
                        });
                      },
                      child: Text(
                        _isRegistering 
                            ? '¿Ya tienes cuenta? Inicia sesión' 
                            : '¿No tienes cuenta? Regístrate',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    Text(
                      'El personal solo puede ser registrado por un Administrador.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
