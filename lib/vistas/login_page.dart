import 'package:flutter/material.dart';
import "package:app_movil_cam_maps/vistas/home_page.dart";

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Color danger de tu CSS: #dc3545
    const Color usfqRed = Color(0xFFDC3545);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // bg-light del CSS
      appBar: AppBar(
        backgroundColor: usfqRed,
        elevation: 0,
        title: const Text(
          "EYE OF THE DRAGON",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo del proyecto
            Image.asset(
              'images/logo.webp',
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            
            // Contenedor del Formulario (Simulando la card del HTML)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Iniciar Sesión",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: usfqRed,
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    // Campo Correo (name="correo" en tu HTML)
                    const Text("Correo electrónico", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "ejemplo@correo.com",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo Password (name="password" en tu HTML)
                    const Text("Contraseña", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "********",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 35),
                    
                    // Botón Ingresar (rounded-pill btn-danger)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: usfqRed,
                          shape: const StadiumBorder(),
                          
                        ),
                        
                        child: const Text(
                          "INGRESAR",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Footer igual al HTML
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
      ),
    );
  }
}