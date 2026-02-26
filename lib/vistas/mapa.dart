import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart'; // Asegúrate de que la ruta sea correcta

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

  // Aquí guardaremos los datos que vengan de Neo4j vía Django
  late Future<Map<String, dynamic>> mapData;

  @override
  void initState() {
    super.initState();
    // Este método debería traer tanto nodos (puntos) como relaciones (aristas)
    mapData = _loadMapData();
  }

  Future<Map<String, dynamic>> _loadMapData() async {
    // Por ahora, simulamos la respuesta del backend basada en tu lógica de Neo4j
    // Mañana preguntas al chico de la web por el endpoint de 'mapas'
    await Future.delayed(const Duration(seconds: 1)); 
    return {
      "puntos": [
        {'nombre': 'Cámara Principal USFQ', 'lat': -0.1973, 'lon': -78.4355, 'status': 'OK'},
        {'nombre': 'Cámara Acceso Norte', 'lat': -0.1985, 'lon': -78.4380, 'status': 'ALERTA'},
      ],
      "relaciones": [
        [const LatLng(-0.1973, -78.4355), const LatLng(-0.1985, -78.4380)],
      ]
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        elevation: 0,
        title: const Text(
          "MAPA",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
            onPressed: () => setState(() { mapData = _loadMapData(); }),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: mapData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: usfqRed));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error cargando mapa", style: TextStyle(color: Colors.white54)));
          }

          final puntos = snapshot.data!['puntos'] as List;
          final relaciones = snapshot.data!['relaciones'] as List<List<LatLng>>;

          return FlutterMap(
            options: const MapOptions(
              initialCenter: centroUSFQ,
              initialZoom: 19.0,
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
              
              // Dibujado dinámico de Relaciones (Aristas de Neo4j)
              PolylineLayer(
                polylines: relaciones.map((puntosRuta) => Polyline(
                  points: puntosRuta,
                  color: const Color(0xFFFF5722).withOpacity(0.7), 
                  strokeWidth: 3,
                )).toList(),
              ),

              // Dibujado dinámico de Nodos (Cámaras)
              MarkerLayer(
                markers: puntos.map((p) => Marker(
                  point: LatLng(p['lat'], p['lon']),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showCameraPreview(context, p['nombre']),
                    child: Tooltip(
                      message: p['nombre'],
                      child: Icon(
                        Icons.circle,
                        color: p['status'] == 'OK' ? const Color(0xFF28A745) : usfqRed,
                        size: 14,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: usfqRed,
        child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        onPressed: () {},
      ),
    );
  }

  // Pequeño extra: Mostrar el nombre al tocar el punto
  void _showCameraPreview(BuildContext context, String nombre) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Seleccionado: $nombre"),
        backgroundColor: usfqRed,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}