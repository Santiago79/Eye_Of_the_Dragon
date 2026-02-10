import 'package:flutter/material.dart';

class CamerasPage extends StatefulWidget {
  const CamerasPage({super.key});

  @override
  State<CamerasPage> createState() => _CamerasPageState();
}

class _CamerasPageState extends State<CamerasPage> {
  static const Color bgColor = Color(0xFF1E1E2F);
  static const Color cardColor = Color(0xFF2A2A3B);
  static const Color usfqRed = Color(0xFFDC3545);

  // Simulación de datos del servicio de cámaras
  double threshold = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        title: const Text("SISTEMA DE MONITOREO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        actions: [
          _buildMemoryIndicator("RAM", "45%"),
          const SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Panel de Control Global (Basado en tu info de logs y sistema)
            _buildSystemStatus(),
            const SizedBox(height: 20),

            // Lista de Cámaras con Analítica (Basado en panel.html)
            _buildCameraCard(
              id: "CAM-01",
              nombre: "Acceso Principal USFQ",
              estado: "ACTIVO",
              detecciones: "12 personas",
            ),
            const SizedBox(height: 15),
            _buildCameraCard(
              id: "CAM-02",
              nombre: "Parqueadero Estudiantes",
              estado: "ALERTA",
              detecciones: "Densidad Alta",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF161625),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statusItem(Icons.storage, "LOGS", "CSV OK"),
          _statusItem(Icons.analytics, "DETECCIÓN", "Running"),
          _statusItem(Icons.speed, "LATENCIA", "45ms"),
        ],
      ),
    );
  }

  Widget _buildCameraCard({required String id, required String nombre, required String estado, required String detecciones}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: estado == "ALERTA" ? usfqRed : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estado == "ALERTA" ? usfqRed : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(estado, style: TextStyle(color: estado == "ALERTA" ? Colors.white : Colors.greenAccent, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Área de Video/Gráfica (Simulando el video_plot_container del HTML)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.videocam, color: Colors.white24, size: 50),
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Control de Threshold (Igual al slider de tu HTML)
          Row(
            children: [
              const Text("Sensibilidad:", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: threshold,
                  activeColor: usfqRed,
                  onChanged: (val) => setState(() => threshold = val),
                ),
              ),
              Text(threshold.toStringAsFixed(1), style: const TextStyle(color: Colors.white)),
            ],
          ),
          
          // Dato de los Logs
          Text("Último Log: $detecciones", style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMemoryIndicator(String label, String value) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text("$label: $value", style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ),
    );
  }

  Widget _statusItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: usfqRed, size: 20),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}