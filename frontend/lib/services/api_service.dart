// Archivo: lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String _baseUrl = "http://localhost:5000/api";
  final _storage = const FlutterSecureStorage();

  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'accessToken', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'accessToken');
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        String token = json.decode(response.body)['accessToken'];
        await _saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  // V--- FUNCIÓN NUEVA PARA EL REGISTRO ---V
  Future<bool> register(String idUsuario, String nombre, String email, String password, String ong) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_usuario': idUsuario,
          'nombre_completo': nombre,
          'email': email,
          'password': password,
          'ong': ong
        }),
      );
      // 201 significa "Created" (Creado) y es la respuesta exitosa para un registro
      return response.statusCode == 201;
    } catch (e) {
      print('Error en registro: $e');
      return false;
    }
  }
  // ^--- HASTA AQUÍ ---^

  Future<List<dynamic>> getHistorial() async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('Token no encontrado. Inicia sesión de nuevo.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/historial'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fallo al cargar el historial. Código: ${response.statusCode}');
    }
  }
}