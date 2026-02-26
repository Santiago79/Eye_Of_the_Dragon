import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Definición de colores institucionales EOTD - USFQ
    const Color usfqRed = Color(0xFFDC3545);
    const Color bgColor = Color(0xFF161625);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header Institucional
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 15, left: 20, right: 20),
            width: double.infinity,
            color: usfqRed,
            child: const Text(
              "UNIVERSIDAD SAN FRANCISCO DE QUITO",
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              color: bgColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de la Tesis / Proyecto
                    Image.asset(
                      'images/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.remove_red_eye, size: 80, color: usfqRed);
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    const Text(
                      "EYE OF THE DRAGON",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: usfqRed,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      "SISTEMA DE MONITOREO INTELIGENTE",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 50),
                    
                    // Botón de Iniciar Sesión (Ruta Nombrada)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navegación usando el nombre configurado en main.dart
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: usfqRed,
                          shape: const StadiumBorder(),
                          elevation: 2,
                        ),
                        child: const Text(
                          "INICIAR SESIÓN",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Botón de Registro (Ruta Nombrada)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          // Navegación usando el nombre configurado en main.dart
                          Navigator.pushNamed(context, '/register');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: usfqRed, width: 2),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          "REGISTRARSE",
                          style: TextStyle(color: usfqRed, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Footer de Tesis
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            color: usfqRed,
            child: const Text(
              "© 2026 Eye of the Dragon. USFQ",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w300),
            ),
          ),
        ],
      ),
    );
  }
}