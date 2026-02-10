import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Color danger de tu CSS y Bootstrap: #dc3545
  static const Color usfqRed = Color(0xFFDC3545);
  
  String? _selectedRol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // bg-light en CSS
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
            const SizedBox(height: 30),
            // Logo del proyecto (identidad visual)
            Image.asset(
              'images/logo.webp',
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            
            // Contenedor del Formulario (Simulando la card del HTML)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                      "Crear Cuenta",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: usfqRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo Nombre (name="nombre")
                    const Text("Nombre completo", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Nombre",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Campo Correo (name="correo")
                    const Text("Correo electrónico", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "ejemplo@correo.com",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Campo Password (name="password")
                    const Text("Contraseña", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "********",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Selector de Rol (select name="rol" en HTML)
                    const Text("Rol", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                      value: _selectedRol,
                      hint: const Text("Selecciona un rol"),
                      items: const [
                        DropdownMenuItem(value: "administrador", child: Text("Administrador")),
                        DropdownMenuItem(value: "seguridad", child: Text("Cuerpo de Seguridad")),
                      ],
                      onChanged: (val) => setState(() => _selectedRol = val),
                    ),
                    const SizedBox(height: 30),
                    
                    // Botón Registrarse (rounded-pill btn-danger)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Aquí irá la lógica de registro
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: usfqRed,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          "REGISTRARSE",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Footer idéntico al HTML
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