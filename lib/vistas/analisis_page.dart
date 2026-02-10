import 'package:flutter/material.dart';

class AnalisisPage extends StatefulWidget {
  const AnalisisPage({super.key});

  @override
  State<AnalisisPage> createState() => _AnalisisPageState();
}

class _AnalisisPageState extends State<AnalisisPage> {
  String seccionActiva = "DETECCIÓN"; // Simula las pestañas del HTML
  static const Color bgColor = Color(0xFF1E1E2F);
  static const Color cardColor = Color(0xFF2A2A3B);
  static const Color usfqRed = Color(0xFFDC3545);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        title: const Text("ANÁLISIS DE VIDEO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Pestañas (Tabs) igual que en tu HTML .square-tab
          Container(
            color: const Color(0xFF161625),
            child: Row(
              children: [
                _buildTab("DETECCIÓN"),
                _buildTab("HILOS"),
                _buildTab("HISTORIAL"),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Área de Carga (Simulando el Dropzone/Form de tu HTML)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: usfqRed.withOpacity(0.5), width: 1),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: Colors.white54, size: 50),
                        const SizedBox(height: 15),
                        const Text(
                          "Subir video para análisis",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Formatos soportados: MP4, AVI",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: usfqRed),
                          child: const Text("SELECCIONAR ARCHIVO"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "RESULTADOS RECIENTES",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 15),

                  // Galería de Resultados (Simulando la rejilla de thumbnails del HTML)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: 4, // Ejemplos
                    itemBuilder: (context, index) {
                      return _buildResultCard(index);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isActive = seccionActiva == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => seccionActiva = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? usfqRed : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        image: const DecorationImage(
          image: NetworkImage("https://via.placeholder.com/150"), // Aquí iría el frame analizado
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 8,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Detección #102", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("Persona detectada", style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 9)),
              ],
            ),
          ),
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}