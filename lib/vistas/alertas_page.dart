import 'package:flutter/material.dart';
import '../services/api_service.dart';

// IMPORTANTE: Descomenta o ajusta estos imports según el paquete de mapas que uses en tu proyecto.
// Si usas flutter_map:
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Si usas google_maps_flutter, comenta los de arriba y usa este:
// import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlertasPage extends StatefulWidget {
  final Function(double lat, double lon) onGoToMap;

  const AlertasPage({super.key, required this.onGoToMap});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  List<dynamic> _alertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
  }

  Future<void> _cargarAlertas() async {
    setState(() => _isLoading = true);
    try {
      final alertas = await ApiService().getSOSAlerts();
      setState(() => _alertas = alertas);
    } catch (e) {
      print("Error cargando alertas: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarComoAtendida(int idAlerta, int index) async {
    final alertaRemovida = _alertas.removeAt(index);
    setState(() {});

    try {
      await ApiService().markSOSAsAttended(idAlerta);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ Alerta atendida y cerrada"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _alertas.insert(index, alertaRemovida));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error al cerrar alerta: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // === FUNCIÓN: PANEL DE SNAPSHOT DE LA ALERTA ===
  void _mostrarSnapshot(Map<String, dynamic> alerta) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF232335),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Barra superior decorativa
                Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),

                // 2. Encabezado de la alerta
                Text("🚨 Emergencia SOS",
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(alerta['emisor'] ?? "Usuario Desconocido",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text("Hora: ${alerta['fecha']}",
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),

                // 3. Snapshot del Mapa (Contenedor visual)
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161625),
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // === MAPA REAL BLOQUEADO (SNAPSHOT) ===
                        IgnorePointer(
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            // AQUÍ USAMOS FLUTTER_MAP COMO EJEMPLO (Ajusta la sintaxis si tu versión es diferente)
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter:
                                    LatLng(alerta['lat'], alerta['lon']),
                                initialZoom: 16.0,
                                // interactiveFlags: InteractiveFlag.none, // Descomenta si tu versión de flutter_map lo requiere
                              ),
                              children: [
                                TileLayer(
                                  // Usamos un tema oscuro/claro de mapa según prefieras. Este es CartoDB Positron.
                                  urlTemplate:
                                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Marcador central parpadeante (simulado con color vivo encima del mapa)
                        const Icon(Icons.location_on,
                            size: 50, color: Colors.redAccent),

                        // Etiqueta de coordenadas
                        Positioned(
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                  "Lat: ${alerta['lat'].toStringAsFixed(5)} | Lon: ${alerta['lon'].toStringAsFixed(5)}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'monospace')),
                            ))
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 4. Botones de Acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("VOLVER"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15)),
                        icon: const Icon(Icons.open_in_full,
                            color: Colors.white, size: 18),
                        label: const Text("ABRIR MAPA",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onGoToMap(alerta['lat'], alerta['lon']);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161625),
      appBar: AppBar(
        title: const Text("Bandeja de Emergencias",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFDC3545),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _cargarAlertas)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _alertas.isEmpty
              ? const Center(
                  child: Text("No hay emergencias activas ✅",
                      style: TextStyle(color: Colors.green, fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _alertas.length,
                  itemBuilder: (context, index) {
                    final alerta = _alertas[index];

                    return Dismissible(
                      key: ValueKey(alerta['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("ATENDER",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            SizedBox(width: 10),
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 30),
                          ],
                        ),
                      ),
                      onDismissed: (direction) {
                        _marcarComoAtendida(alerta['id'], index);
                      },
                      child: Card(
                        color: const Color(0xFF232335),
                        margin: const EdgeInsets.only(bottom: 15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _mostrarSnapshot(alerta),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const Icon(Icons.warning,
                                    color: Colors.red, size: 40),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("SOS: ${alerta['emisor']}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text("Hora: ${alerta['fecha']}",
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.white38)
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
