// Archivo: lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart'; // <-- Importamos la nueva pantalla

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  void _login() async {
    setState(() { _isLoading = true; });
    
    bool success = await _apiService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() { _isLoading = false; });

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email o contraseña incorrectos'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Iniciar Sesión', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Entrar'),
                ),
              const SizedBox(height: 15),
              // V--- BOTÓN NUEVO PARA REGISTRARSE ---V
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text('¿No tienes una cuenta? Regístrate'),
              )
              // ^--- HASTA AQUÍ ---^
            ],
          ),
        ),
      ),
    );
  }
}