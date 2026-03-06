import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlertasPage extends StatefulWidget {
  // Recibimos esta función desde el HomePage para poder cambiar la pestaña
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161625),
      appBar: AppBar(
        title: const Text("Bandeja de Emergencias", style: TextStyle(color: Colors.white)), 
        backgroundColor: const Color(0xFFDC3545),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargarAlertas)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _alertas.isEmpty
              ? const Center(child: Text("No hay emergencias activas ✅", style: TextStyle(color: Colors.green, fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _alertas.length,
                  itemBuilder: (context, index) {
                    final alerta = _alertas[index];
                    return Card(
                      color: const Color(0xFF232335),
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red, size: 40),
                        title: Text("SOS: ${alerta['emisor']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("Hora: ${alerta['fecha']}\nLat: ${alerta['lat']}, Lon: ${alerta['lon']}", style: const TextStyle(color: Colors.white70)),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          icon: const Icon(Icons.map, color: Colors.white, size: 18),
                          label: const Text("MAPA", style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            // Llamamos a la función que nos pasó el HomePage
                            widget.onGoToMap(alerta['lat'], alerta['lon']);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}