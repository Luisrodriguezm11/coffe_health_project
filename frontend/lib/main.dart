import 'package:flutter/material.dart';
// Asegúrate de que esta ruta a tu dashboard sea correcta
import 'screens/login_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Health Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Esta es la línea clave: le decimos que la pantalla de inicio es DashboardScreen
      home: LoginScreen(),
    );
  }
}