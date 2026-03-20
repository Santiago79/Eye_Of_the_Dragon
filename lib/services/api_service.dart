import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/camera_model.dart';

class ApiService {
  // IP centralizada para todo el servicio
  final String _baseUrl = "http://10.42.175.164:8000";
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

  // ---------------------------------------------------------
  // ENDPOINTS DE ANÁLISIS DE VIDEO (DRF API)
  // ---------------------------------------------------------

  // 1. Iniciar un análisis subiendo archivos
  Future<Map<String, dynamic>> uploadVideoForAnalysis({
    required List<String> filePaths,
    required double startTime,
    required double endTime,
    required int threshold,
    List<Map<String, dynamic>> areas = const [],
  }) async {
    // Apuntamos a la nueva ruta correcta que configuramos en Django
    final url = Uri.parse('$_baseUrl/cvpack/api/video-analysis/start/');

    var request = http.MultipartRequest('POST', url);

    // Añadimos el token JWT
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // Añadimos los datos de configuración
    request.fields['start_time'] = startTime.toString();
    request.fields['end_time'] = endTime.toString();
    request.fields['people_threshold'] = threshold.toString();
    request.fields['areas'] =
        json.encode(areas); // Django espera un string JSON

    // Adjuntamos los archivos físicos
    for (String path in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('video_files', path));
    }

    // Enviamos la petición
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("Error del backend: ${response.body}");
      throw Exception('Falló al subir los videos: ${response.statusCode}');
    }
  }

  // 2. Consultar el estado de los hilos de análisis
  Future<List<dynamic>> getAnalysisStatus() async {
    // Apuntamos a la nueva ruta correcta de status
    final url = Uri.parse('$_baseUrl/cvpack/api/video-analysis/status/');

    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      return decodedData['threads'] ?? [];
    } else {
      throw Exception(
          'Error al obtener estado de análisis: ${response.statusCode}');
    }
  }

  // ---------------------------------------------------------
  // ENDPOINTS DEL MAPA (App 'mapas' - API)
  // ---------------------------------------------------------

  // 1. Obtener nodos simulados
  Future<Map<String, dynamic>> getMapNodes() async {
    // NUEVA URL: Agregamos "/api/" para usar el endpoint JWT
    final url = Uri.parse('$_baseUrl/mapas/api/nodes_snapshot/');

    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Error al obtener nodos del mapa: ${response.statusCode}');
    }
  }

  // 2. Obtener usuarios reales (Guardias, etc.)
  Future<Map<String, dynamic>> getUsersLocations() async {
    // NUEVA URL: Agregamos "/api/" para usar el endpoint JWT
    final url = Uri.parse('$_baseUrl/mapas/api/users_snapshot/');

    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Error al obtener ubicaciones de usuarios: ${response.statusCode}');
    }
  }

  // 3. Enviar mi propia ubicación GPS al servidor
  Future<void> updateLocation(double lat, double lon, double accuracy) async {
    // NUEVA URL: Agregamos "/api/" para usar el endpoint JWT
    final url = Uri.parse('$_baseUrl/mapas/api/update_my_location/');

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: json.encode({"lat": lat, "lon": lon, "accuracy": accuracy}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar ubicación: ${response.body}');
    }
  }

  // =======================================================
  // EXTRAER ROL DEL JWT
  // =======================================================
  Future<String> getUserRole() async {
    String? token = await getToken();
    if (token == null || token.isEmpty) return 'seguridad';

    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'seguridad';

      final payloadStr = parts[1];
      // Normalizamos el Base64 para que Dart no se queje
      String normalized = base64.normalize(payloadStr);
      final String decodedStr = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> payloadMap = json.decode(decodedStr);

      return payloadMap['rol'] ?? 'seguridad';
    } catch (e) {
      print("Error decodificando JWT: $e");
      return 'seguridad';
    }
  }

  // =======================================================
  // ALERTAS SOS
  // =======================================================
  Future<void> sendSOSAlert(double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/mapas/api/sos/enviar/');

    // Asumo que tienes una función _getHeaders() en tu clase
    // Si la tuya no usa 'await', quítale el await de abajo
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({"lat": lat, "lon": lon}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar SOS: ${response.body}');
    }
  }

  Future<List<dynamic>> getSOSAlerts() async {
    final url = Uri.parse('$_baseUrl/mapas/api/sos/listar/');

    // Igual aquí, ajusta el _getHeaders() según cómo lo tengas
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['alertas'] ?? [];
    } else {
      throw Exception('Error al obtener alertas: ${response.body}');
    }
  }

  Future<void> markSOSAsAttended(int alertId) async {
    final url = Uri.parse('$_baseUrl/mapas/api/sos/ack_mobile/$alertId/');

    final response = await http.post(
      url,
      headers:
          _getHeaders(), // Asegúrate de usar la función que inyecta tu Token JWT
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Error al marcar la alerta como atendida: ${response.body}');
    }
  }
}
