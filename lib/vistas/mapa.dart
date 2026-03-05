import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // <--- Importamos Geolocator
import '../services/api_service.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final ApiService apiService = ApiService();
  
  // Coordenadas centrales de la USFQ
  static const LatLng centroUSFQ = LatLng(-0.1973, -78.4355);
  static const Color usfqRed = Color(0xFFDC3545);
  static const Color bgColor = Color(0xFF1E1E2F);

  List<dynamic> _simulatedNodes = [];
  List<dynamic> _realUsers = [];
  Timer? _timer;
  
  // Controlador del mapa para mover la cámara al centrar GPS
  final MapController _mapController = MapController();
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _fetchMapData();
    // Radar: Pide datos al servidor cada 2 segundos
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMapData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMapData() async {
    try {
      final simData = await apiService.getMapNodes();
      final usersData = await apiService.getUsersLocations();

      setState(() {
        // Parseo seguro: a veces Django manda un Dict {"nodes": [...]}, a veces un array directo [...]
        if (simData.containsKey('nodes')) {
          _simulatedNodes = simData['nodes'];
        } else {
          // Si el JSON base es la lista misma (o el snapshot root)
          _simulatedNodes = simData['points'] ?? simData['nodos'] ?? [];
        }
        
        _realUsers = usersData['users'] ?? [];
      });
    } catch (e) {
      print("Error actualizando mapa: $e");
    }
  }

  // =======================================================
  // LÓGICA DE GEOLOCALIZACIÓN Y PERMISOS
  // =======================================================
  Future<void> _enviarMiUbicacion() async {
    setState(() => _isLocating = true);
    try {
      // 1. Verificar si el servicio GPS del celular está encendido
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack("Por favor, enciende el GPS de tu celular.");
        setState(() => _isLocating = false);
        return;
      }

      // 2. Pedir permisos al usuario (Geoconsent)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack("Permisos de ubicación denegados.");
          setState(() => _isLocating = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showSnack("Permisos denegados permanentemente. Actívalos en Ajustes.");
        setState(() => _isLocating = false);
        return;
      }

      // 3. Obtener ubicación de alta precisión
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 4. Centrar el mapa en mi ubicación
      _mapController.move(LatLng(position.latitude, position.longitude), 18.5);

      // 5. Enviar a Django
      await apiService.updateLocation(
        position.latitude, 
        position.longitude, 
        position.accuracy
      );
      
      _showSnack("📍 Ubicación actualizada en el sistema", isSuccess: true);
      
      // Forzamos una actualización visual para vernos a nosotros mismos
      _fetchMapData();

    } catch (e) {
      _showSnack("Error de GPS: $e");
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? Colors.green : usfqRed,
      duration: const Duration(seconds: 2),
    ));
  }

  // =======================================================
  // DIBUJADO DE LA INTERFAZ
  // =======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MAPA DEL CAMPUS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Nodos activos: ${_simulatedNodes.length + _realUsers.length}", style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: centroUSFQ,
          initialZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.app_movil_cam_maps.usfq',
            tileBuilder: (context, tileWidget, tile) {
              return ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  -0.21, -0.72, -0.07, 0, 255,
                  -0.21, -0.72, -0.07, 0, 255,
                  -0.21, -0.72, -0.07, 0, 255,
                  0, 0, 0, 1, 0,
                ]),
                child: tileWidget,
              );
            },
          ),
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: false,
        backgroundColor: usfqRed,
        onPressed: _isLocating ? null : _enviarMiUbicacion,
        child: _isLocating 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.my_location, color: Colors.white, size: 24),
      ),
    );
  }

  // =======================================================
  // ASIGNACIÓN DE COLORES SEGÚN LA WEB
  // =======================================================
  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'estudiante': return Colors.blue;
      case 'personal administrativo': return Colors.green;
      case 'personal de limpieza': return Colors.orange;
      case 'profesor': return Colors.purpleAccent;
      case 'seguridad': return Colors.lightBlue;
      default: return Colors.grey;
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // 1. Dibujar los Nodos Simulados 
    for (var node in _simulatedNodes) {
      // Intentamos extraer lat y lon de forma segura
      double? lat = double.tryParse(node['lat']?.toString() ?? '');
      double? lon = double.tryParse(node['lon']?.toString() ?? '');
      
      if (lat != null && lon != null) {
        String categoria = node['categoria'] ?? 'desconocido';
        Color nodeColor = _getColorForCategory(categoria);

        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 10,
            height: 10,
            child: Container(
              decoration: BoxDecoration(
                color: nodeColor,
                shape: BoxShape.circle,
              ),
            ),
          )
        );
      }
    }

    // 2. Dibujar Usuarios/Guardias Reales
    for (var user in _realUsers) {
      double? lat = double.tryParse(user['lat']?.toString() ?? '');
      double? lon = double.tryParse(user['lon']?.toString() ?? '');
      
      if (lat != null && lon != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                _showSnack("${user['nombre']} - ${user['rol']}", isSuccess: true);
              },
              child: const Tooltip(
                message: "Usuario Real",
                child: Icon(Icons.person_pin_circle, color: usfqRed, size: 35),
              ),
            ),
          )
        );
      }
    }

    return markers;
  }
}