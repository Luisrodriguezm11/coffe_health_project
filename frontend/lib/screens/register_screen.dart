// Archivo: lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _idController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ongController = TextEditingController(text: 'De la Gente'); // Valor por defecto

  final _apiService = ApiService();
  bool _isLoading = false;

  void _register() async {
    setState(() { _isLoading = true; });

    bool success = await _apiService.register(
      _idController.text,
      _nombreController.text,
      _emailController.text,
      _passwordController.text,
      _ongController.text,
    );

    setState(() { _isLoading = false; });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Registro exitoso! Ahora puedes iniciar sesión.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Regresamos a la pantalla de login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error en el registro. Inténtalo de nuevo.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nueva Cuenta')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _idController, decoration: const InputDecoration(labelText: 'ID de Usuario (ej. juanperez)')),
              const SizedBox(height: 10),
              TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Completo')),
              const SizedBox(height: 10),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
              const SizedBox(height: 10),
              TextField(controller: _ongController, decoration: const InputDecoration(labelText: 'Organización')),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Registrarse'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}