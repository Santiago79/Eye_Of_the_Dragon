import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color usfqRed = Color(0xFFDC3545);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA), 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AQUÍ VA TU LOGO WEBP
                    Image.asset(
                      'images/logo.webp', // Ruta que configuraste en pubspec.yaml
                      height: 120, // Ajusta según el tamaño de tu archivo
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Esto se muestra si la ruta está mal o el archivo no existe
                        return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
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
                    const SizedBox(height: 10),
                    const Text(
                      "Sistema de Monitoreo Inteligente",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    const SizedBox(height: 50),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
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
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            color: usfqRed,
            child: const Text(
              "© 2025 Eye of the Dragon. USFQ",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}