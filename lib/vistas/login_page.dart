import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Esta función es la que conectarás el próximo viernes a la API
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // SIMULACIÓN: Aquí irá la petición a Django
      await Future.delayed(Duration(seconds: 2)); 
      
      print("Usuario: ${_userController.text}");
      print("Password: ${_passwordController.text}");
      
      setState(() => _isLoading = false);
      
      // Por ahora, solo navegamos a una "Home" ficticia
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simulación de inicio de sesión exitosa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("CVPack Login", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              TextFormField(
                controller: _userController,
                decoration: InputDecoration(labelText: 'Usuario', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Ingresa tu usuario' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña' : null,
              ),
              SizedBox(height: 30),
              _isLoading 
                ? CircularProgressIndicator() 
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: Text("Iniciar Sesión"),
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}