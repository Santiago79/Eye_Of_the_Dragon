import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // IMPORTANTE: Para guardar el token

class AuthService {
  // Asegúrate de que esta IP coincida con la de tu Arch Linux (era .26 en tus logs)
  final String baseUrl = "http://10.123.186.26:8001/api";

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // EXTRAEMOS EL TOKEN Y LO PASAMOS AL API SERVICE
        String accessToken = data['access'];
        ApiService.setToken(accessToken); 
        
        return true;
      }
      print("Error en login: ${response.statusCode} - ${response.body}");
      return false;
    } catch (e) {
      print("Error de conexión: $e");
      return false;
    }
  }

  Future<bool> register(String email, String password, String nombre, String rol) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/registro/'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "nombre_completo": nombre,
          "rol": rol
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

    // Añade esto a tu ApiService en Flutter
  Future<void> wakeUpCameras() async {
    final url = Uri.parse('$baseUrl/camaras/start_cameras/');
    await http.get(url); // Esto activa los hilos de YOLO en el servidor
  }
}