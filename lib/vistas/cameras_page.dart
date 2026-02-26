import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../models/mjpeg_player.dart';

class CamerasPage extends StatefulWidget {
  const CamerasPage({super.key});

  @override
  State<CamerasPage> createState() => _CamerasPageState();
}

class _CamerasPageState extends State<CamerasPage> {
  final Color usfqRed = const Color(0xFFE2231A);
  final Color backgroundColor = const Color(0xFF0F0F0F);
  final Color cardColor = const Color(0xFF1A1A1A);

  List<dynamic> cameras = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCameras();
  }

  Future<void> _fetchCameras() async {
    try {
      // Usamos tu ApiService para traer la lista de cámaras
      final data = await ApiService().getCameras();
      setState(() {
        cameras = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error cargando cámaras: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // En lib/pages/cameras_page.dart
Future<void> _updateThreshold(String camId, double value) async {
  // Asegúrate de que esta URL sea EXACTAMENTE la que sale en el log del terminal
  final url = Uri.parse("http://10.123.186.26:8001/camaras/cambiar_threshold/$camId/"); 
  
  try {
    final response = await http.post(
      url,
      // Django necesita el body así para leerlo con request.POST.get
      body: {'threshold': value.toInt().toString()}, 
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");
  } catch (e) {
    print("Error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("SISTEMA EOTD", 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCameras,
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: usfqRed))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: cameras.length,
              itemBuilder: (context, index) {
                return _buildCameraCard(cameras[index]);
              },
            ),
    );
  }

  Widget _buildCameraCard(dynamic cameraData) {
    // CAMBIO CLAVE: Accedemos como objeto, no como mapa
    final String camId = cameraData.camId.toString(); 
    final String name = cameraData.name ?? "Cámara";
    final bool isActive = cameraData.isActive ?? false;
    
    // Usamos el valor que viene del objeto Camera
    int threshold = cameraData.peopleThreshold; 

    final String streamUrl = "http://10.123.186.26:8001/camaras/$camId/live_feed/";

    return Container(
      // ... resto del código del container igual ...
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive ? Colors.white10 : usfqRed.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: Nombre y Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildBadge(isActive),
            ],
          ),
          const SizedBox(height: 15),
          
          // Contenedor de Video (Procesamiento YOLO)
          Container(
            height: 200,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isActive 
              ? MjpegPlayer(url: streamUrl, fit: BoxFit.cover)
              : const Center(
                  child: Text("SISTEMA DESACTIVADO", 
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
                ),
          ),
          
          const SizedBox(height: 20),
          
          // Control de Límite (Threshold)
          Row(
            children: [
              const Icon(Icons.group_outlined, color: Colors.white54, size: 18),
              const SizedBox(width: 10),
              const Text("LÍMITE:", style: TextStyle(color: Colors.white70, fontSize: 11)),
              Expanded(
                child: // Busca el Slider dentro de _buildCameraCard y reemplázalo con este:
                  Slider(
                    value: cameraData.peopleThreshold.toDouble(), // Acceso con punto
                    min: 1,
                    max: 30,
                    activeColor: usfqRed,
                    inactiveColor: Colors.white10,
                    onChanged: (val) {
                      setState(() {
                        // CAMBIO CLAVE: Asignación directa a la propiedad del objeto
                        cameraData.peopleThreshold = val.toInt(); 
                      });
                    },
                    onChangeEnd: (val) => _updateThreshold(camId, val),
                  ),
              ),
              Container(
                width: 35,
                alignment: Alignment.centerRight,
                child: Text("${threshold.toInt()}", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          
          const Divider(color: Colors.white10, height: 25),
          
          // ID del dispositivo
          Text("ID DISPOSITIVO: $camId", 
            style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.1) : usfqRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? Colors.green.withOpacity(0.5) : usfqRed.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 3,
            backgroundColor: active ? Colors.green : usfqRed,
          ),
          const SizedBox(width: 6),
          Text(
            active ? "LIVE" : "OFFLINE",
            style: TextStyle(
              color: active ? Colors.green : usfqRed,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}