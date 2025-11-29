// app_flutter/lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class AuthService {
  final Dio _dio = Dio();
  // Almacenamiento seguro de tokens (Encriptación)
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _tokenKey = 'auth_token';
  final String _agenteIdKey = 'agente_id';

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<bool> isAuthenticated() async => await getToken() != null;

  // 1. Lógica de Login (Validación de sesión de usuario - 2 Pts)
  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$API_BASE_URL/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        // Almacenar el Token y el ID del Agente de forma segura (Encriptación/Seguridad)
        await _storage.write(key: _tokenKey, value: response.data['access_token']);
        await _storage.write(key: _agenteIdKey, value: response.data['id_agente'].toString());
        
      } else {
        throw Exception('Error desconocido durante el login.');
      }
    } on DioException catch (e) {
      // Manejo de errores de la API (ej: Credenciales inválidas)
      String errorMessage = e.response?.data['detail'] ?? 'Error de conexión con la API';
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _agenteIdKey);
  }
}