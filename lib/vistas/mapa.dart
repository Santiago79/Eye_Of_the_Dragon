import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaPage extends StatelessWidget {
  const MapaPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF1E1E2F);
    const Color usfqRed = Color(0xFFDC3545);

    // Datos de ejemplo (Nodos y Relaciones de tu lógica Neo4j)
    final puntos = [
      {'nombre': 'Cámara Principal USFQ', 'lat': -0.1973, 'lon': -78.4355},
      {'nombre': 'Cámara Acceso Norte', 'lat': -0.1985, 'lon': -78.4380},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        elevation: 0,
        title: const Text(
          "MAPA DE SEGURIDAD",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Tabs cuadradas (estilo .square-tab de tu HTML/CSS)
          Container(
            color: const Color(0xFF2A2A3B),
            child: Row(
              children: [
                _buildTab("GENERAL", isSelected: true),
                _buildTab("ALERTAS", isSelected: false),
                _buildTab("NODOS", isSelected: false),
              ],
            ),
          ),
          
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(-0.1973, -78.4355),
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // CORRECCIÓN: User-Agent para evitar el bloqueo "Access Blocked"
                  userAgentPackageName: 'com.app_movil_cam_maps.usfq',
                  tileBuilder: (context, tileWidget, tile) {
                    // Filtro para simular el modo oscuro de tu Página Principal
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
                
                // Representación de aristas (Relaciones en Neo4j)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [LatLng(-0.1973, -78.4355), LatLng(-0.1985, -78.4380)],
                      color: const Color(0xFFFF5722), // Color naranja de tu JS
                      strokeWidth: 3,
                    ),
                  ],
                ),

                // Marcadores de Nodos (Cámaras)
                MarkerLayer(
                  markers: puntos.map((p) => Marker(
                    point: LatLng(p['lat'] as double, p['lon'] as double),
                    width: 40,
                    height: 40,
                    child: Tooltip(
                      message: p['nombre'] as String,
                      child: const Icon(
                        Icons.circle,
                        color: Color(0xFF28A745), // Verde de tu JS (Success)
                        size: 14,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: usfqRed,
        child: const Icon(Icons.my_location, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Widget _buildTab(String label, {required bool isSelected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.red : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}