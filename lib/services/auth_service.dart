import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService {
  final String baseUrl = "http://10.127.8.27:8000/api";

Future<bool> login(String email, String password) async {
  final url = Uri.parse("http://10.127.8.27:8000/api/auth/login/"); 
  
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "email": email, // <--- ESTA ES LA LLAVE CORRECTA. Cámbiala aquí.
        "password": password,
      }),
    ).timeout(const Duration(seconds: 10));

    print("STATUS LOGIN: ${response.statusCode}");
    print("BODY LOGIN: ${response.body}"); // Esto nos dirá la verdad absoluta

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ApiService.setToken(data['access']); 
      return true;
    }
    return false;
  } catch (e) {
    print("Error en login: $e");
    return false;
  }
}

Future<bool> register(String email, String password, String nombre, String rol) async {
  try {
    // Añadimos /auth/ para que coincida con el backend
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'), 
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
    print("ERROR REGISTRO: $e");
    return false;
  }
}

  Future<void> wakeUpCameras() async {
    try {
      // Ajustado a la ruta que suele manejar Django fuera del prefijo /api/
      final url = Uri.parse('http://10.127.8.27:8000/camaras/start_cameras/');
      await http.get(url).timeout(const Duration(seconds: 5));
    } catch (e) {
      print("Error activando YOLO: $e");
    }
  }
}