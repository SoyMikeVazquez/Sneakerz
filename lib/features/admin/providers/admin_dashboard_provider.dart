import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';
import 'package:sneakerz_app/features/booking/providers/products_provider.dart';
import 'package:sneakerz_app/features/booking/providers/services_provider.dart';
import 'package:sneakerz_app/models/product_model.dart';
import 'package:sneakerz_app/models/service_model.dart';

// Sucursal seleccionada (null = Todas las sucursales para superAdmin)
final selectedBranchIdProvider = StateProvider<String?>((ref) => null);

// Filtro de fecha para finanzas
final financeDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return DateTimeRange(start: todayStart, end: todayEnd);
});

// Notifier para CRUD de Sucursales en Administrador
class AdminBranchesNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AdminBranchesNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadBranches();
  }

  Future<void> loadBranches() async {
    state = const AsyncValue.loading();
    final tableNames = ['sucursales', 'branches'];

    for (final table in tableNames) {
      try {
        final data = await _supabase.from(table).select('*').order('id', ascending: true);
        if (data is List) {
          state = AsyncValue.data(data.map((e) => Map<String, dynamic>.from(e)).toList());
          return;
        }
      } catch (e) {
        debugPrint('[Admin Branches] Error al consultar $table: $e');
      }
    }
    state = const AsyncValue.data([]);
  }

  // Crear sucursal
  Future<String?> createBranch({
    required String nombre,
    required String direccion,
    String? telefono,
    String? horario,
    Map<String, dynamic>? horarioJson,
    double? latitud,
    double? longitud,
    String? imagen,
    bool isOpen = true,
  }) async {
    final tableNames = ['sucursales', 'branches'];
    for (final table in tableNames) {
      try {
        final probe = await _supabase.from(table).select('*').limit(1).maybeSingle();
        final keys = probe != null ? probe.keys.map((k) => k.toString().toLowerCase()).toSet() : <String>{};

        final row = <String, dynamic>{
          if (keys.contains('nombre_sucursal')) 'nombre_sucursal': nombre
          else if (keys.contains('nombre')) 'nombre': nombre
          else if (keys.contains('name')) 'name': nombre
          else 'nombre': nombre,

          if (keys.contains('direccion')) 'direccion': direccion
          else if (keys.contains('address')) 'address': direccion
          else 'direccion': direccion,

          if (telefono != null && telefono.isNotEmpty) ...{
            if (keys.contains('telefono')) 'telefono': telefono
            else if (keys.contains('phone')) 'phone': telefono
            else 'telefono': telefono,
          },

          if (horario != null && horario.isNotEmpty) ...{
            if (keys.contains('horario')) 'horario': horario
            else if (keys.contains('schedule')) 'schedule': horario
            else 'horario': horario,
          },

          if (latitud != null) ...{
            if (keys.contains('lat')) 'lat': latitud
            else if (keys.contains('latitud')) 'latitud': latitud
            else 'lat': latitud,
          },

          if (longitud != null) ...{
            if (keys.contains('long')) 'long': longitud
            else if (keys.contains('lng')) 'lng': longitud
            else if (keys.contains('longitud')) 'longitud': longitud
            else 'long': longitud,
          },

          if (imagen != null && imagen.isNotEmpty) ...{
            if (keys.contains('imagen_sucursal')) 'imagen_sucursal': imagen
            else if (keys.contains('imagen')) 'imagen': imagen
            else if (keys.contains('image')) 'image': imagen
            else if (keys.contains('foto')) 'foto': imagen
            else 'imagen_sucursal': imagen,
          },

          if (keys.contains('is_open')) 'is_open': isOpen
          else if (keys.contains('is_active')) 'is_active': isOpen
          else if (keys.contains('activo')) 'activo': isOpen
          else 'is_open': isOpen,
        };

        // Detectar si la tabla tiene columna jsonb
        if (horarioJson != null && keys.isNotEmpty) {
          final jsonCol = keys.firstWhere(
            (k) =>
                k.contains('horario_json') ||
                k.contains('horarios_json') ||
                k.contains('horario_semanal') ||
                k.contains('horarios') ||
                k.contains('schedule_json') ||
                k.contains('detalle_horario') ||
                k.contains('dias_horario'),
            orElse: () => '',
          );
          if (jsonCol.isNotEmpty) {
            row[jsonCol] = horarioJson;
          }
        }

        await _supabase.from(table).insert(row);
        await loadBranches();
        return null;
      } catch (e1) {
        try {
          final fallbackRow = <String, dynamic>{
            'name': nombre,
            'address': direccion,
            if (telefono != null && telefono.isNotEmpty) 'phone': telefono,
            if (horario != null && horario.isNotEmpty) 'schedule': horario,
            if (latitud != null) 'lat': latitud,
            if (longitud != null) 'long': longitud,
            if (imagen != null && imagen.isNotEmpty) 'imagen_sucursal': imagen,
            'is_active': isOpen,
          };
          await _supabase.from(table).insert(fallbackRow);
          await loadBranches();
          return null;
        } catch (e2) {
          debugPrint('[Admin Branches] Error al insertar sucursal: $e2');
        }
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }

  // Editar sucursal
  Future<String?> updateBranch({
    required dynamic id,
    required String nombre,
    required String direccion,
    String? telefono,
    String? horario,
    Map<String, dynamic>? horarioJson,
    double? latitud,
    double? longitud,
    String? imagen,
    bool? isOpen,
  }) async {
    final parsedId = int.tryParse(id.toString()) ?? id;
    final tableNames = ['sucursales', 'branches'];

    for (final table in tableNames) {
      try {
        dynamic queryId = parsedId;
        var existingRow = await _supabase.from(table).select('*').eq('id', queryId).maybeSingle();
        if (existingRow == null && queryId != id) {
          queryId = id;
          existingRow = await _supabase.from(table).select('*').eq('id', queryId).maybeSingle();
        }

        final Map<String, dynamic> updatePayload = {};

        if (existingRow != null) {
          final keys = existingRow.keys.map((k) => k.toString().toLowerCase()).toSet();

          // Nombre
          if (keys.contains('nombre_sucursal')) updatePayload['nombre_sucursal'] = nombre;
          else if (keys.contains('nombre')) updatePayload['nombre'] = nombre;
          else if (keys.contains('name')) updatePayload['name'] = nombre;

          // Dirección
          if (keys.contains('direccion')) updatePayload['direccion'] = direccion;
          else if (keys.contains('address')) updatePayload['address'] = direccion;
          else if (keys.contains('ubicacion')) updatePayload['ubicacion'] = direccion;

          // Teléfono
          if (keys.contains('telefono')) updatePayload['telefono'] = telefono;
          else if (keys.contains('phone')) updatePayload['phone'] = telefono;

          // Horario (String)
          if (keys.contains('horario')) updatePayload['horario'] = horario;
          else if (keys.contains('schedule')) updatePayload['schedule'] = horario;

          // Horario (JSONB)
          if (horarioJson != null) {
            final jsonCol = keys.firstWhere(
              (k) =>
                  k.contains('horario_json') ||
                  k.contains('horarios_json') ||
                  k.contains('horario_semanal') ||
                  k.contains('horarios') ||
                  k.contains('schedule_json') ||
                  k.contains('detalle_horario') ||
                  k.contains('dias_horario'),
              orElse: () => '',
            );
            if (jsonCol.isNotEmpty) {
              updatePayload[jsonCol] = horarioJson;
            }
          }

          // Latitud
          if (latitud != null) {
            if (keys.contains('lat')) updatePayload['lat'] = latitud;
            else if (keys.contains('latitud')) updatePayload['latitud'] = latitud;
            else updatePayload['lat'] = latitud;
          }

          // Longitud
          if (longitud != null) {
            if (keys.contains('long')) updatePayload['long'] = longitud;
            else if (keys.contains('lng')) updatePayload['lng'] = longitud;
            else if (keys.contains('longitud')) updatePayload['longitud'] = longitud;
            else updatePayload['long'] = longitud;
          }

          // Imagen
          if (keys.contains('imagen_sucursal')) updatePayload['imagen_sucursal'] = imagen;
          else if (keys.contains('imagen')) updatePayload['imagen'] = imagen;
          else if (keys.contains('image')) updatePayload['image'] = imagen;
          else if (keys.contains('foto')) updatePayload['foto'] = imagen;
          else updatePayload['imagen_sucursal'] = imagen;

          // Estatus abierto
          if (isOpen != null) {
            if (keys.contains('is_open')) updatePayload['is_open'] = isOpen;
            else if (keys.contains('is_active')) updatePayload['is_active'] = isOpen;
            else if (keys.contains('activo')) updatePayload['activo'] = isOpen;
          }
        }

        if (updatePayload.isEmpty) {
          updatePayload.addAll({
            'nombre': nombre,
            'direccion': direccion,
            'telefono': telefono,
            'horario': horario,
          });
        }

        debugPrint('[Admin Branches] Actualizando $table con payload: $updatePayload en id: $queryId');
        await _supabase.from(table).update(updatePayload).eq('id', queryId);
        debugPrint('[Admin Branches] ¡Sucursal actualizada con éxito!');

        await loadBranches();
        return null;
      } catch (e) {
        debugPrint('[Admin Branches] Error al actualizar sucursal en $table: $e');
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }

  // Eliminar sucursal
  Future<String?> deleteBranch(dynamic id) async {
    final parsedId = int.tryParse(id.toString()) ?? id;
    final tableNames = ['sucursales', 'branches'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).delete().eq('id', parsedId);
        await loadBranches();
        return null;
      } catch (e) {
        debugPrint('[Admin Branches] Error al eliminar sucursal: $e');
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }
}

final adminBranchesNotifierProvider =
    StateNotifierProvider<AdminBranchesNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminBranchesNotifier(ref.watch(supabaseClientProvider), ref);
});

final adminBranchesProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ref.watch(adminBranchesNotifierProvider);
});

class AdminFinancesNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AdminFinancesNotifier(this._supabase, this._ref) : super(const AsyncValue.data(null));

  Future<String?> createFinanceRecord({
    required String nombreRegistro,
    String? descripcion,
    required double montoCobrar,
    String? contacto,
    String? idCliente,
    required String metodoPago,
    required bool isGasto,
    required String tipoIngreso,
    String? idSucursal,
  }) async {
    state = const AsyncValue.loading();
    try {
      final payload = {
        'nombre_registro': nombreRegistro,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
        'monto_cobrar': montoCobrar,
        if (contacto != null && contacto.isNotEmpty) 'contacto': contacto,
        if (idCliente != null && idCliente.isNotEmpty) 'id_cliente': int.tryParse(idCliente),
        'metodo_pago': metodoPago,
        'isGasto': isGasto,
        'tipo_ingreso': tipoIngreso,
        if (idSucursal != null) 'id_sucursal': idSucursal,
      };

      await _supabase.from('Finanzas').insert(payload);
      _ref.invalidate(adminFinanceProvider);
      state = const AsyncValue.data(null);
      return null;
    } catch (e) {
      debugPrint('[Admin Finances] Error al crear registro financiero: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return e.toString();
    }
  }
}

final adminFinancesNotifierProvider = StateNotifierProvider<AdminFinancesNotifier, AsyncValue<void>>((ref) {
  return AdminFinancesNotifier(ref.watch(supabaseClientProvider), ref);
});

// Resumen de Finanzas (filtrable por sucursal)
class FinanceSummary {
  final double totalIngresos;
  final double totalGastos;
  final double balance;
  final int serviciosCompletados;
  final int serviciosPendientes;
  final double ticketPromedio;
  final List<Map<String, dynamic>> transacciones;

  FinanceSummary({
    required this.totalIngresos,
    required this.totalGastos,
    required this.balance,
    required this.serviciosCompletados,
    required this.serviciosPendientes,
    required this.ticketPromedio,
    required this.transacciones,
  });
}

final adminFinanceProvider = FutureProvider<FinanceSummary>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final selectedBranch = ref.watch(selectedBranchIdProvider);
  final dateRange = ref.watch(financeDateRangeProvider);

  try {
    var query = supabase.from('Finanzas').select('*');
    if (selectedBranch != null) {
      query = query.eq('id_sucursal', selectedBranch);
    }
    if (dateRange != null) {
      query = query.gte('created_at', dateRange.start.toUtc().toIso8601String());
      query = query.lte('created_at', dateRange.end.toUtc().toIso8601String());
    }
    final data = await query;

    double ingresos = 0;
    double gastos = 0;
    List<Map<String, dynamic>> transacciones = [];

    if (data is List && data.isNotEmpty) {
      transacciones = data.map((e) => Map<String, dynamic>.from(e)).toList();
      for (final item in transacciones) {
        final montoVal = item['monto_cobrar'] ?? item['monto'] ?? item['total'] ?? item['precio'] ?? 0;
        final monto = montoVal is num
            ? montoVal.toDouble()
            : double.tryParse(montoVal.toString()) ?? 0.0;

        final isGasto = item['isGasto'] == true || 
                        item['isgasto'] == true || 
                        item['tipo_ingreso']?.toString().toLowerCase() == 'gasto' ||
                        item['tipo']?.toString().toLowerCase() == 'gasto' || 
                        item['tipo']?.toString().toLowerCase() == 'egreso';

        if (isGasto) {
          gastos += monto;
        } else {
          ingresos += monto;
        }
      }
    }

    // Consultar Citas/Registros para métricas
    List<dynamic> citasData = [];
    try {
      var citasQuery = supabase.from('Registros|Citas').select('*');
      if (selectedBranch != null) {
        citasQuery = citasQuery.eq('sucursal_id', selectedBranch);
      }
      if (dateRange != null) {
        citasQuery = citasQuery.gte('created_at', dateRange.start.toUtc().toIso8601String());
        citasQuery = citasQuery.lte('created_at', dateRange.end.toUtc().toIso8601String());
      }
      citasData = await citasQuery;
    } catch (e) {
      debugPrint('[FinanceProvider] Error fetching citas: $e');
    }

    int serviciosCompletados = 0;
    int serviciosPendientes = 0;

    if (citasData.isNotEmpty) {
      for (final item in citasData) {
        final estado = item['estado']?.toString().toLowerCase() ?? '';
        if (estado == 'completado' || estado == 'entregado' || estado == 'pagado') {
          serviciosCompletados++;
        } else {
          serviciosPendientes++;
        }
      }
    }

    final ticketPromedio = serviciosCompletados > 0 ? (ingresos / serviciosCompletados) : 0.0;

    debugPrint('[FinanceProvider] Final result: ingresos=$ingresos, gastos=$gastos, balance=${ingresos - gastos}');

    return FinanceSummary(
      totalIngresos: ingresos,
      totalGastos: gastos,
      balance: ingresos - gastos,
      serviciosCompletados: serviciosCompletados,
      serviciosPendientes: serviciosPendientes,
      ticketPromedio: ticketPromedio,
      transacciones: transacciones,
    );
  } catch (e, stack) {
    debugPrint('[FinanceProvider] Error fetch: $e\n$stack');
    return FinanceSummary(
      totalIngresos: 0.0,
      totalGastos: 0.0,
      balance: 0.0,
      serviciosCompletados: 0,
      serviciosPendientes: 0,
      ticketPromedio: 0.0,
      transacciones: [],
    );
  }
});

// Notifier para gestión de Registros | Citas (Crear Citas, Convertir a Registro, Cambiar Estatus)
class AdminRegistrosNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AdminRegistrosNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadRegistros();
  }

  Future<void> loadRegistros() async {
    state = const AsyncValue.loading();
    final selectedBranch = _ref.read(selectedBranchIdProvider);
    final tableNames = ['Registros|Citas', 'citas', 'registros', 'orders'];

    for (final table in tableNames) {
      try {
        var query = _supabase.from(table).select('*');
        if (selectedBranch != null) {
          query = query.eq('sucursal_id', selectedBranch);
        }
        final data = await query.order('created_at', ascending: false);

        if (data is List) {
          state = AsyncValue.data(data.map((e) => Map<String, dynamic>.from(e)).toList());
          return;
        }
      } catch (_) {}
    }
    state = const AsyncValue.data([]);
  }

  // Helper para buscar o crear cliente
  Future<int?> _getOrCreateClienteId(String telefono, String nombre, String? correo) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select('id_cliente')
          .eq('telefono', telefono)
          .maybeSingle();

      if (response != null) {
        return int.tryParse(response['id_cliente'].toString());
      } else {
        final insertData = {
          'telefono': telefono,
          'nombre': nombre,
          if (correo != null && correo.isNotEmpty) 'correo': correo,
        };
        final insertResponse = await _supabase
            .from('clientes')
            .insert(insertData)
            .select('id_cliente')
            .single();
        return int.tryParse(insertResponse['id_cliente'].toString());
      }
    } catch (e) {
      debugPrint('[Registros/Citas] Error al obtener/crear cliente: $e');
      return null;
    }
  }

  // Agendar nueva Cita (cita: true, status: 'cita')
  Future<String?> createCita({
    required String clienteNombre,
    required String telefono,
    String? correo,
    required String modelo,
    required String servicio,
    required String sucursal,
    String? sucursalId,
    DateTime? fechaCita,
    String? notas,
    double total = 0.0,
    String? imageUrl,
  }) async {
    final clienteId = await _getOrCreateClienteId(telefono, clienteNombre, correo);

    final row = <String, dynamic>{
      'cita': true,
      'status': 'cita',
      'cliente_nombre': clienteNombre,
      'telefono': telefono,
      if (correo != null && correo.isNotEmpty) 'correo': correo,
      'modelo': modelo,
      'servicio': servicio,
      'sucursal': sucursal,
      if (sucursalId != null && sucursalId.isNotEmpty) 'sucursal_id': sucursalId,
      'fecha_cita': (fechaCita ?? DateTime.now()).toIso8601String(),
      if (notas != null && notas.isNotEmpty) 'notas': notas,
      'total': total,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
      if (clienteId != null) 'id_cliente': clienteId,
    };

    final tableNames = ['Registros|Citas', 'Registro|Cita', 'citas', 'registros'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).insert(row);
        await loadRegistros();
        return null;
      } catch (e1) {
        try {
          // Fallback en caso de que la columna se llame imagen o foto
          final fallbackRow = Map<String, dynamic>.from(row);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            fallbackRow.remove('image');
            fallbackRow['imagen'] = imageUrl;
          }
          await _supabase.from(table).insert(fallbackRow);
          await loadRegistros();
          return null;
        } catch (e2) {
          debugPrint('[Registros/Citas] Error al insertar cita en $table: $e2');
        }
      }
    }
    return 'Error al registrar cita en Supabase. Verifica permisos o consola.';
  }

  // Crear un Registro directo en Taller (cita: false, status: 'Dado de alta')
  Future<String?> createRegistro({
    required String clienteNombre,
    required String telefono,
    String? correo,
    required String modelo,
    required String servicio,
    required String sucursal,
    String? sucursalId,
    String? imageUrl,
    List<String>? imageUrls,
    String? notas,
    double total = 0.0,
    double anticipo = 0.0,
    String status = 'Dado de alta',
  }) async {
    final clienteId = await _getOrCreateClienteId(telefono, clienteNombre, correo);

    final row = <String, dynamic>{
      'cita': false,
      'status': status,
      'nombre_dueño': clienteNombre,
      'telefono_dueño': int.tryParse(telefono.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      if (correo != null && correo.isNotEmpty) 'correo_dueño': correo,
      'modelo': modelo,
      'servicio': servicio,
      'sucursal': sucursal,
      if (sucursalId != null && sucursalId.isNotEmpty) 'sucursal_id': sucursalId,
      if (notas != null && notas.isNotEmpty) 'notas': notas,
      'pagado_total': total.toString(),
      'ancitipo': anticipo.toString(), // Note the typo in the DB column name
      if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
      if (imageUrls != null && imageUrls.isNotEmpty) 'galeria_item_inicio': imageUrls,
      'created_at': DateTime.now().toIso8601String(),
      if (clienteId != null) 'id_cliente': clienteId,
    };

    final tableNames = ['Registros|Citas', 'Registro|Cita', 'citas', 'registros'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).insert(row);
        await loadRegistros();
        return null;
      } catch (e1) {
        try {
          // Fallback en caso de que la columna se llame imagen o foto
          final fallbackRow = Map<String, dynamic>.from(row);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            fallbackRow.remove('image');
            fallbackRow['imagen'] = imageUrl;
          }
          await _supabase.from(table).insert(fallbackRow);
          await loadRegistros();
          return null;
        } catch (e2) {
          debugPrint('[Registros/Citas] Error al crear registro en $table: $e2');
        }
      }
    }
    return 'Error al registrar en taller en Supabase. Verifica permisos o consola.';
  }


  // Convertir Cita a Registro de Trabajo (cita: false, status: 'recibido' o 'en_lavado')
  Future<String?> convertToRegistro(dynamic id, {String newStatus = 'recibido'}) async {
    final parsedId = int.tryParse(id.toString()) ?? id;
    final tableNames = ['Registros|Citas', 'citas', 'registros'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).update({
          'cita': false,        // <-- Se convierte en trabajo/registro activo
          'status': newStatus,  // <-- Pasa a estatus de taller
        }).eq('id', parsedId);
        await loadRegistros();
        return null;
      } catch (e) {
        debugPrint('[Registros/Citas] Error al convertir cita: $e');
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }

  // Actualizar estatus de trabajo (en_lavado, listo_para_entrega, entregado)
  Future<String?> updateStatus(dynamic id, String newStatus) async {
    final parsedId = int.tryParse(id.toString()) ?? id;
    final tableNames = ['Registros|Citas', 'citas', 'registros'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).update({
          'status': newStatus,
        }).eq('id', parsedId);
        await loadRegistros();
        return null;
      } catch (e) {
        debugPrint('[Registros/Citas] Error al actualizar status: $e');
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }
}

final adminRegistrosNotifierProvider =
    StateNotifierProvider<AdminRegistrosNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminRegistrosNotifier(ref.watch(supabaseClientProvider), ref);
});

// Getter compatible para consultas
final adminRegistrosProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ref.watch(adminRegistrosNotifierProvider);
});

// Notifier para CRUD de Productos en Administrador
class AdminProductsNotifier extends StateNotifier<AsyncValue<List<ProductItem>>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AdminProductsNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    final tableNames = ['Productos', 'productos', 'products'];

    for (final table in tableNames) {
      try {
        final data = await _supabase.from(table).select('*');
        if (data is List && data.isNotEmpty) {
          final list = data.map((e) => ProductItem.fromJson(Map<String, dynamic>.from(e))).toList();
          state = AsyncValue.data(list);
          return;
        }
      } catch (_) {}
    }
    state = const AsyncValue.data([]);
  }

  // Crear producto
  Future<String?> createProduct({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? category,
  }) async {
    final tableNames = ['Productos', 'productos', 'products'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).insert({
          'title': name,
          'description': description,
          'price': price,
          'image': imageUrl,
          'category': category ?? 'Cuidado Rápido',
        });
        await loadProducts();
        _ref.invalidate(productsProvider);
        return null;
      } catch (e1) {
        try {
          await _supabase.from(table).insert({
            'nombre_producto': name,
            'descripcion_producto': description,
            'precio_producto': price,
            'foto_producto': imageUrl,
            'categoria': category ?? 'Cuidado Rápido',
          });
          await loadProducts();
          _ref.invalidate(productsProvider);
          return null;
        } catch (e2) {
          debugPrint('[Admin Products] Error al insertar en $table: $e2');
        }
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }

  // Editar producto con detección de columnas reales
  Future<String?> updateProduct({
    required String id,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? category,
  }) async {
    final tableNames = ['Productos', 'productos', 'products'];

    for (final table in tableNames) {
      try {
        dynamic queryId = int.tryParse(id) ?? id;
        var existingRow = await _supabase.from(table).select('*').eq('id', queryId).maybeSingle();
        if (existingRow == null && queryId != id) {
          queryId = id;
          existingRow = await _supabase.from(table).select('*').eq('id', queryId).maybeSingle();
        }

        final Map<String, dynamic> updatePayload = {};

        if (existingRow != null) {
          final keys = existingRow.keys.map((k) => k.toString().toLowerCase()).toSet();

          // Title / Nombre
          if (keys.contains('nombre_producto')) updatePayload['nombre_producto'] = name;
          else if (keys.contains('nombre')) updatePayload['nombre'] = name;
          else if (keys.contains('title')) updatePayload['title'] = name;
          else if (keys.contains('name')) updatePayload['name'] = name;

          // Description / Descripción
          if (keys.contains('descripcion_producto')) updatePayload['descripcion_producto'] = description;
          else if (keys.contains('descripcion')) updatePayload['descripcion'] = description;
          else if (keys.contains('description')) updatePayload['description'] = description;

          // Price / Precio
          if (keys.contains('precio_producto')) updatePayload['precio_producto'] = price;
          else if (keys.contains('precio')) updatePayload['precio'] = price;
          else if (keys.contains('price')) updatePayload['price'] = price;

          // Image / Foto
          if (keys.contains('foto_producto')) updatePayload['foto_producto'] = imageUrl;
          else if (keys.contains('foto')) updatePayload['foto'] = imageUrl;
          else if (keys.contains('image')) updatePayload['image'] = imageUrl;
          else if (keys.contains('imagen')) updatePayload['imagen'] = imageUrl;
          else if (keys.contains('image_url')) updatePayload['image_url'] = imageUrl;

          // Category / Categoría
          if (keys.contains('categoria')) updatePayload['categoria'] = category;
          else if (keys.contains('category')) updatePayload['category'] = category;
        }

        if (updatePayload.isEmpty) {
          updatePayload.addAll({
            'title': name,
            'description': description,
            'price': price,
            'image': imageUrl,
            'category': category,
          });
        }

        debugPrint('[Admin Products] Actualizando $table en ID $queryId con: $updatePayload');
        await _supabase.from(table).update(updatePayload).eq('id', queryId);
        debugPrint('[Admin Products] ¡Producto actualizado correctamente en Supabase!');

        await loadProducts();
        _ref.invalidate(productsProvider);
        return null;
      } catch (e) {
        debugPrint('[Admin Products] Error al actualizar en $table: $e');
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }

  // Eliminar producto
  Future<String?> deleteProduct(String id) async {
    final parsedId = int.tryParse(id.toString()) ?? id;
    final tableNames = ['Productos', 'productos', 'products'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).delete().eq('id', parsedId);
        await loadProducts();
        _ref.invalidate(productsProvider);
        return null;
      } catch (e) {
        debugPrint('[Admin Products] Error al eliminar producto: $e');
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }
}

final adminProductsNotifierProvider =
    StateNotifierProvider<AdminProductsNotifier, AsyncValue<List<ProductItem>>>((ref) {
  return AdminProductsNotifier(ref.watch(supabaseClientProvider), ref);
});

// Notifier para CRUD de Servicios en Administrador
class AdminServicesNotifier extends StateNotifier<AsyncValue<List<ServiceItem>>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AdminServicesNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadServices();
  }

  Future<void> loadServices() async {
    state = const AsyncValue.loading();
    final tableNames = ['servicios', 'services', 'services_catalog'];

    for (final table in tableNames) {
      try {
        final data = await _supabase.from(table).select('*');
        if (data is List && data.isNotEmpty) {
          final list = data.map((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e))).toList();
          state = AsyncValue.data(list);
          return;
        }
      } catch (_) {}
    }
    state = const AsyncValue.data([]);
  }

  // Crear servicio
  Future<String?> createService({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? type,
  }) async {
    final tableNames = ['servicios', 'services'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).insert({
          'title': name,
          'description': description,
          'precio_servicio': price,
          'image': imageUrl,
          'type': type ?? 'General',
        });
        await loadServices();
        _ref.invalidate(servicesProvider);
        return null;
      } catch (e1) {
        try {
          await _supabase.from(table).insert({
            'nombre': name,
            'descripcion': description,
            'precio': price,
            'imagen': imageUrl,
            'tipo': type ?? 'General',
          });
          await loadServices();
          _ref.invalidate(servicesProvider);
          return null;
        } catch (e2) {
          debugPrint('[Admin Services] Error al insertar servicio: $e2');
        }
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }

  // Editar servicio con detección de columnas reales
  Future<String?> updateService({
    required String id,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? type,
  }) async {
    final tableNames = ['servicios', 'services', 'services_catalog'];

    for (final table in tableNames) {
      try {
        dynamic queryId = int.tryParse(id) ?? id;
        var existingRow = await _supabase.from(table).select('*').eq('id', queryId).maybeSingle();
        if (existingRow == null && queryId != id) {
          queryId = id;
          existingRow = await _supabase.from(table).select('*').eq('id', queryId).maybeSingle();
        }

        final Map<String, dynamic> updatePayload = {};

        if (existingRow != null) {
          final keys = existingRow.keys.map((k) => k.toString().toLowerCase()).toSet();

          // Title / Nombre
          if (keys.contains('title')) updatePayload['title'] = name;
          else if (keys.contains('nombre')) updatePayload['nombre'] = name;
          else if (keys.contains('titulo')) updatePayload['titulo'] = name;
          else if (keys.contains('name')) updatePayload['name'] = name;

          // Description / Descripción
          if (keys.contains('description')) updatePayload['description'] = description;
          else if (keys.contains('descripcion')) updatePayload['descripcion'] = description;

          // Price / Precio
          if (keys.contains('precio_servicio')) updatePayload['precio_servicio'] = price;
          else if (keys.contains('precio')) updatePayload['precio'] = price;
          else if (keys.contains('price')) updatePayload['price'] = price;

          // Image / Imagen
          if (keys.contains('image')) updatePayload['image'] = imageUrl;
          else if (keys.contains('imagen')) updatePayload['imagen'] = imageUrl;
          else if (keys.contains('foto')) updatePayload['foto'] = imageUrl;
          else if (keys.contains('image_url')) updatePayload['image_url'] = imageUrl;

          // Type / Tipo
          if (keys.contains('type')) updatePayload['type'] = type;
          else if (keys.contains('tipo')) updatePayload['tipo'] = type;
          else if (keys.contains('categoria')) updatePayload['categoria'] = type;
        }

        if (updatePayload.isEmpty) {
          updatePayload.addAll({
            'title': name,
            'description': description,
            'precio_servicio': price,
            'image': imageUrl,
          });
        }

        debugPrint('[Admin Services] Actualizando $table en ID $queryId con: $updatePayload');
        await _supabase.from(table).update(updatePayload).eq('id', queryId);
        debugPrint('[Admin Services] ¡Servicio actualizado correctamente en Supabase!');

        await loadServices();
        _ref.invalidate(servicesProvider);
        return null;
      } catch (e) {
        debugPrint('[Admin Services] Error al actualizar servicio en $table: $e');
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }

  // Eliminar servicio
  Future<String?> deleteService(String id) async {
    final parsedId = int.tryParse(id.toString()) ?? id;
    final tableNames = ['servicios', 'services'];
    for (final table in tableNames) {
      try {
        await _supabase.from(table).delete().eq('id', parsedId);
        await loadServices();
        _ref.invalidate(servicesProvider);
        return null;
      } catch (e) {
        debugPrint('[Admin Services] Error al eliminar servicio: $e');
      }
    }
    return 'Error en base de datos. Revisa reglas RLS, permisos o consola.';
  }
}

final adminServicesNotifierProvider =
    StateNotifierProvider<AdminServicesNotifier, AsyncValue<List<ServiceItem>>>((ref) {
  return AdminServicesNotifier(ref.watch(supabaseClientProvider), ref);
});

// Notifier para CRUD y Creador de Usuarios en tabla users (Solo SuperAdmin)
class AdminUsersNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AdminUsersNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    try {
      final data = await _supabase.from('users').select('*');
      if (data is List) {
        state = AsyncValue.data(data.map((e) => Map<String, dynamic>.from(e)).toList());
        return;
      }
      state = const AsyncValue.data([]);
    } catch (e) {
      debugPrint('[Admin] Error al cargar usuarios: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Crear usuario con autenticación y registro en tabla users
  Future<String?> createUser({
    required String nombre,
    required String correo,
    required String password,
    required String telefono,
    required String sucursal,
    required bool isAdmin,
    required bool isSuperAdmin,
  }) async {
    try {
      String? authUserId;

      // 1. Crear el usuario en Auth usando la API REST directa (para NUNCA alterar la sesión local del SuperAdmin)
      try {
        final httpRes = await http.post(
          Uri.parse('https://xnhbgtonqdupiwvavdew.supabase.co/auth/v1/signup'),
          headers: {
            'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhuaGJndG9ucWR1cGl3dmF2ZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDI5MTAsImV4cCI6MjA5MzQ3ODkxMH0.BP53oidioor871kFs-xZki8E1LGBztW283-8vzCzeoM',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': correo,
            'password': password,
            'data': {
              'nombre': nombre,
              'sucursal': sucursal,
              'is_admin': isAdmin,
              'superAdmin': isSuperAdmin,
            },
          }),
        );

        if (httpRes.statusCode == 200 || httpRes.statusCode == 201) {
          final resData = jsonDecode(httpRes.body);
          authUserId = resData['id'] ?? resData['user']?['id'];
        } else {
          debugPrint('[Admin] Respuesta Auth REST: ${httpRes.statusCode} - ${httpRes.body}');
        }
      } catch (authError) {
        debugPrint('[Admin] Aviso al registrar auth user via REST: $authError');
      }

      final numericPhone = num.tryParse(telefono.replaceAll(RegExp(r'\D'), '')) ?? telefono;

      final fullUserData = <String, dynamic>{
        'nombre': nombre,
        'correo': correo,
        'telefono': numericPhone,
        'sucursal': sucursal,
        'is_admin': isAdmin,
        'superAdmin': isSuperAdmin,
        'fecha_registro': DateTime.now().toIso8601String(),
      };

      // 2. Esperar brevemente para que el trigger de Supabase cree la fila inicial
      await Future.delayed(const Duration(milliseconds: 350));

      // 3. Verificar si la fila ya fue insertada por el trigger de Supabase Auth
      final existing = await _supabase
          .from('users')
          .select('*')
          .eq('correo', correo)
          .maybeSingle();

      if (existing != null) {
        debugPrint('[Admin] Actualizando fila creada por trigger en users para $correo...');
        await _supabase
            .from('users')
            .update(fullUserData)
            .eq('correo', correo);
      } else {
        debugPrint('[Admin] Insertando nueva fila completa en users para $correo...');
        try {
          if (authUserId != null) {
            await _supabase.from('users').insert({
              'id': authUserId,
              ...fullUserData,
            });
          } else {
            await _supabase.from('users').insert(fullUserData);
          }
        } catch (_) {
          await _supabase.from('users').insert(fullUserData);
        }
      }

      await loadUsers();
      return null;
    } catch (e) {
      debugPrint('[Admin] Error al registrar usuario en tabla users: $e');
      return e.toString();
    }
  }

  // Eliminar usuario de la tabla users
  Future<String?> deleteUser(dynamic id, {String? correo}) async {
    try {
      final parsedId = int.tryParse(id.toString()) ?? id;
      try {
        await _supabase.from('users').delete().eq('id', parsedId);
      } catch (e) {
        if (correo != null) {
          await _supabase.from('users').delete().eq('correo', correo);
        } else {
          rethrow;
        }
      }
      await loadUsers();
      return null;
    } catch (e) {
      debugPrint('[Admin] Error al eliminar usuario: $e');
      return e.toString();
    }
  }
}

final adminUsersNotifierProvider =
    StateNotifierProvider<AdminUsersNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminUsersNotifier(ref.watch(supabaseClientProvider), ref);
});
