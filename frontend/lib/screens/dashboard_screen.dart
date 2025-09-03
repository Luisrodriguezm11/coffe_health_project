// Archivo: lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Importaciones para la navegación y los servicios
import '../services/api_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historial;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // La llamada a getHistorial ahora es segura y usa el token
    _historial = _apiService.getHistorial();
  }

  void _logout() async {
    await _apiService.deleteToken();
    if (!mounted) return; // Verificación de seguridad
    // Navegamos de vuelta a la pantalla de Login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _seleccionarYSubirImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagenSeleccionada = await picker.pickImage(source: ImageSource.gallery);

    if (imagenSeleccionada == null) return;

    setState(() { _isLoading = true; });

    try {
      String? token = await _apiService.getToken();
      if (token == null) {
        _logout();
        return;
      }

      var uri = Uri.parse("http://localhost:5000/api/analizar");
      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromBytes(
          'imagen',
          await imagenSeleccionada.readAsBytes(),
          filename: imagenSeleccionada.name,
        ));

      var response = await http.Response.fromStream(await request.send());

      if (!mounted) return;

      if (response.statusCode == 200) {
        var datos = json.decode(response.body);
        print('Diagnóstico recibido del servidor: $datos');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnóstico: ${datos['enfermedad']}'),
            backgroundColor: Colors.green,
          ),
        );
        // Refrescamos el historial
        setState(() { _historial = _apiService.getHistorial(); });
      } else {
        print('Error del servidor: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la imagen.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error al subir la imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión al subir la imagen.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: CircularProgressIndicator()))
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Analizar Nueva Hoja'),
                onPressed: _seleccionarYSubirImagen,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            const SizedBox(height: 20),
            Text('Historial de Análisis Recientes', style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _historial,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar el historial: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No hay análisis previos.'));
                  }

                  final analisis = snapshot.data!;
                  return ListView.builder(
                    itemCount: analisis.length,
                    itemBuilder: (context, index) {
                      // Aseguramos que los datos no sean nulos antes de mostrarlos
                      final diagnostico = analisis[index]['resultado_diagnostico'] ?? 'Diagnóstico no disponible';
                      final fecha = analisis[index]['fecha_analisis'] ?? 'Fecha no disponible';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(diagnostico),
                          subtitle: Text(fecha.toString()),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}