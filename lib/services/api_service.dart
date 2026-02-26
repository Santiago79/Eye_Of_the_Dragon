import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/camera_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  // Configuración de la URL base según tu terminal de Arch
  static const String baseUrl = "http://10.123.186.26:8001";
  
  // Variable para almacenar el token (deberías setearla al hacer login)
  // En api_service.dart temporalmente:
static String? _token = "PEGA_AQUÍ_EL_TOKEN_LARGO_DEL_LOGIN";

  static void setToken(String token) {
    _token = token;
  }

  // Helper para headers
  Map<String, String> _getHeaders() {
    return {
      "Content-Type": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }

  // ---------------------------------------------------------
  // SECCIÓN: CÁMARAS
  // ---------------------------------------------------------

  Future<List<Camera>> getCameras() async {
    final url = Uri.parse('$baseUrl/api/cameras/');
    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final dynamic decodedData = json.decode(response.body);
      
      List<dynamic> jsonResponse;
      // Verificamos si Django devuelve los datos en la llave 'results' (paginación)
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

  // Método para el Slider corregido con el prefijo /api/
  Future<void> updateThreshold(String camId, int newValue) async {
    final url = Uri.parse('$baseUrl/api/cameras/$camId/threshold/');
    final response = await http.patch(
      url,
      headers: _getHeaders(),
      body: json.encode({"people_threshold": newValue}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar umbral: ${response.body}');
    }
  }

    // En ApiService.dart
  Future<void> startAnalysis() async {
    try {
      // Nota: Esta ruta no suele llevar /api/ porque está en camaras/urls.py
      final url = Uri.parse('$baseUrl/camaras/start_cameras/');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print("Análisis de YOLO iniciado correctamente");
      }
    } catch (e) {
      print("Error al iniciar análisis: $e");
    }
  }

  // ---------------------------------------------------------
  // SECCIÓN: CVPACK (Análisis de Video)
  // ---------------------------------------------------------

  Future<void> uploadVideoForAnalysis(String filePath, int start, int end) async {
    final url = Uri.parse('$baseUrl/api/cvpack/analyze/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(_getHeaders());
    
    request.files.add(await http.MultipartFile.fromPath('video', filePath));
    request.fields['start_time'] = start.toString();
    request.fields['end_time'] = end.toString();

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Error en el análisis: ${response.body}');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Asegúrate que este sea el nombre que usaste al guardar
  }
}