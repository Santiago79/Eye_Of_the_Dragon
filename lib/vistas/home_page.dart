import 'package:flutter/material.dart';
import 'mapa.dart';
import "analisis_page.dart";
import "cameras_page.dart";

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF1E1E2F);
    const Color usfqRed = Color(0xFFDC3545);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        elevation: 0,
        title: const Text(
          "EYE OF THE DRAGON - DASHBOARD",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bienvenido,",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const Text(
                "Panel de Control",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              
              // Tarjeta: CÁMARAS
              _buildAppCard(
  context,
  title: "Cámaras",
  subtitle: "Accede a la transmisión en vivo y analítica de densidad.",
  icon: Icons.videocam_rounded,
  color: Colors.blueAccent,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CamerasPage()),
    );
  },
),
              const SizedBox(height: 20),
              
              // Tarjeta: MAPA
              _buildAppCard(
                context,
                title: "Mapa",
                subtitle: "Visualiza la ubicación de todas las cámaras en el mapa.",
                icon: Icons.map_rounded,
                color: Colors.greenAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapaPage()),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Tarjeta: ANÁLISIS - NAVEGACIÓN AÑADIDA
              _buildAppCard(
                context,
                title: "Análisis",
                subtitle: "Herramientas de reconocimiento y detección de video.",
                icon: Icons.analytics_rounded,
                color: usfqRed,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalisisPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3B),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}