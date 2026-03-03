import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/camera_model.dart'; // Ajusta la ruta si es necesario

class ApiService {
  // IP centralizada para todo el servicio
  final String _baseUrl = "http://172.16.150.27:8001";
  String get baseUrl => _baseUrl; 
  
  // Variable estática para mantener la sesión viva
  static String? _token;

  static void setToken(String token) {
    _token = token;
    print("DEBUG JWT: Token guardado en ApiService");
  }

  // Generador automático de headers con el Token
  Map<String, String> _getHeaders() {
    return {
      "Content-Type": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }

  // Añade esta función de vuelta para que analisis_page pueda leer el token
  Future<String?> getToken() async {
    return _token;
  }

  // ---------------------------------------------------------
  // ENDPOINTS DE LA API REST (Usan Token JWT)
  // ---------------------------------------------------------

  Future<List<Camera>> getCameras() async {
    final url = Uri.parse('$_baseUrl/api/cameras/');
    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final dynamic decodedData = json.decode(response.body);
      List<dynamic> jsonResponse;
      
      // Manejo de paginación de Django REST Framework por si acaso
      if (decodedData is Map && decodedData.containsKey('results')) {
        jsonResponse = decodedData['results'];
      } else {
        jsonResponse = decodedData as List;
      }

      return jsonResponse.map((data) => Camera.fromJson(data)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor, inicia sesión de nuevo.');
    } else {
      throw Exception('Error al cargar cámaras: ${response.statusCode}');
    }
  }

  Future<void> updateThreshold(String camId, double newValue) async {
    // Ruta hacia el API View: /api/cameras/<cam_id>/threshold/
    final url = Uri.parse('$_baseUrl/api/cameras/$camId/threshold/');
    final response = await http.patch(
      url,
      headers: _getHeaders(),
      body: json.encode({"people_threshold": newValue.toInt()}),
    );
    
    if (response.statusCode != 200) {
      print('Error al actualizar umbral: ${response.body}');
    }
  }

  // ---------------------------------------------------------
  // ENDPOINTS TRADICIONALES DE DJANGO (App 'camaras')
  // ---------------------------------------------------------

  // En tu api_service.dart
  // Cambiamos el tipo de retorno de Future<double> a Future<Map<String, dynamic>>
  Future<Map<String, dynamic>> getDensity(String camId) async {
    final url = Uri.parse('$_baseUrl/camaras/$camId/density_data/');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        // Devolvemos el JSON completo que incluye 'values' (el arreglo de la gráfica)
        return json.decode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      print("Error obteniendo densidad para $camId: $e");
      return {};
    }
  }
  
  Future<void> startAnalysis() async {
    try {
      final url = Uri.parse('$_baseUrl/camaras/start_cameras/');
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        print("Análisis de YOLO iniciado correctamente");
      }
    } catch (e) {
      print("Error al iniciar análisis: $e");
    }
  }
}