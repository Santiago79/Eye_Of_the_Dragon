import 'package:flutter/material.dart';
import 'package:app_movil_cam_maps/vistas/home_page.dart';
import 'package:app_movil_cam_maps/services/auth_service.dart';
import 'package:app_movil_cam_maps/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    
    bool success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      await ApiService().startAnalysis();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Credenciales incorrectas")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color usfqRed = Color(0xFFDC3545);
    const Color bgColor = Color(0xFF161625);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        title: const Text("EYE OF THE DRAGON", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset('images/logo.png', height: 100),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3B),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Iniciar Sesión", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: usfqRed)),
                    const SizedBox(height: 25),
                    const Text("Correo electrónico", style: TextStyle(color: Colors.white)),
                    TextField(
                      style: const TextStyle(color: Colors.black),
                      controller: _emailController,
                      decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 20),
                    const Text("Contraseña", style: TextStyle(color: Colors.white)),
                    TextField(
                      style: const TextStyle(color: Colors.black),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(backgroundColor: usfqRed, shape: const StadiumBorder()),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("INGRESAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}