import 'package:flutter/material.dart';
import 'package:app_movil_cam_maps/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color usfqRed = Color(0xFFDC3545);
  static const Color bgColor = Color(0xFF161625);
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  String? _selectedRol;
  bool _isLoading = false;

  void _handleRegister() async {
    if (_selectedRol == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor selecciona un rol")));
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      _selectedRol!,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registro exitoso. Ahora puedes iniciar sesión.")));
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error en el registro. Verifica los datos.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        title: const Text("CREAR CUENTA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF2A2A3B), borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Nombre completo", style: TextStyle(color: Colors.white)),
                TextField(controller: _nameController, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 15),
                const Text("Correo electrónico", style: TextStyle(color: Colors.white)),
                TextField(controller: _emailController, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 15),
                const Text("Contraseña", style: TextStyle(color: Colors.white)),
                TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 15),
                const Text("Rol", style: TextStyle(color: Colors.white)),
                DropdownButtonFormField<String>(
                  value: _selectedRol,
                  items: const [
                    DropdownMenuItem(value: "administrador", child: Text("Administrador")),
                    DropdownMenuItem(value: "seguridad", child: Text("Cuerpo de Seguridad")),
                  ],
                  onChanged: (val) => setState(() => _selectedRol = val),
                  decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(backgroundColor: usfqRed, shape: const StadiumBorder()),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("REGISTRARSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}