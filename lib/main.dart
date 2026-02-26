import 'package:app_movil_cam_maps/vistas/home_page.dart';
import 'package:flutter/material.dart';
import 'vistas/welcome.dart';
import 'vistas/login_page.dart';
import 'vistas/register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Configuración de colores USFQ
  static const Color usfqRed = Color(0xFFDC3545);
  static const Color bgColor = Color(0xFF1E1E2F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eye of the Dragon',
      
      // Configuración del Tema Oscuro para la Tesis
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgColor,
        primaryColor: usfqRed,
        colorScheme: ColorScheme.fromSeed(
          seedColor: usfqRed,
          brightness: Brightness.dark,
        ),
      ),

      // Definición de la página inicial
      initialRoute: '/',

      // Mapa de Navegación
      // En tu mapa de rutas en main.dart
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}