// app_flutter/lib/services/paquete_service.dart

import 'package:dio/dio.dart'; // Corregido: Se importa Options y DioException desde aquí
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class PaqueteService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<Options> _getAuthOptions() async {
    final token = await _storage.read(key: 'auth_token');
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<List<dynamic>> fetchPaquetesAsignados() async {
    final options = await _getAuthOptions();
    try {
      final response = await _dio.get(
        '$API_BASE_URL/paquetes/asignados',
        options: options,
      );
      return response.data; 
    } on DioException catch (e) { // Corregido: Uso de DioException
      if (e.response?.statusCode == 401) {
        throw Exception('Sesión expirada. Por favor, inicia sesión de nuevo.');
      }
      throw Exception('Fallo al obtener paquetes: ${e.message}');
    }
  }

  Future<void> registrarEntrega({
    required int idPaquete,
    required double latitud,
    required double longitud,
    required String urlFotoEvidencia,
  }) async {
    final options = await _getAuthOptions();
    try {
      await _dio.post(
        '$API_BASE_URL/paquetes/registrar_entrega',
        data: {
          'id_paquete': idPaquete,
          'latitud': latitud,
          'longitud': longitud,
          'url_foto_evidencia': urlFotoEvidencia, 
        },
        options: options,
      );
    } on DioException catch (e) { // Corregido: Uso de DioException
      throw Exception('Fallo al registrar entrega: ${e.response?.data['detail'] ?? e.message}');
    }
  }
}