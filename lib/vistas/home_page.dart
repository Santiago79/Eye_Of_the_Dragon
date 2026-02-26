import 'package:flutter/material.dart';
import 'mapa.dart';
import "analisis_page.dart";
import "cameras_page.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildDashboard(),
      const MapaPage(),
      const AnalisisPage(),
      const CamerasPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF161625);
    const Color usfqRed = Color(0xFFDC3545);

    return PopScope(
      // canPop: false bloquea que el botón físico/gesto de atrás cierre la app directamente
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Si el usuario intenta ir "atrás" y no está en el Inicio, lo mandamos al Inicio (index 0)
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          // Si ya está en el Inicio y presiona atrás, podrías mostrar un diálogo 
          // o simplemente no hacer nada para obligar a usar el botón de Logout.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Usa el botón de salida para cerrar sesión"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _selectedIndex == 0 
          ? AppBar(
              backgroundColor: usfqRed,
              elevation: 0,
              // --- CAMBIO CLAVE: Elimina la flecha automática de la izquierda ---
              automaticallyImplyLeading: false, 
              title: const Text(
                "EYE OF THE DRAGON",
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            )
          : null,
        
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),

        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E1E2F),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: usfqRed,
          unselectedItemColor: Colors.white54,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Inicio"),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Mapa"),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: "Análisis"),
            BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: "Cámaras"),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    const Color usfqRed = Color(0xFFDC3545);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bienvenido,", style: TextStyle(color: Colors.white70, fontSize: 18)),
            const Text("Panel de Control", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            _buildAppCard(
              title: "Cámaras",
              subtitle: "Transmisión en vivo y analítica.",
              icon: Icons.videocam_rounded,
              color: Colors.blueAccent,
              onTap: () => _onItemTapped(3),
            ),
            const SizedBox(height: 20),
            
            _buildAppCard(
              title: "Mapa",
              subtitle: "Ubicación de cámaras en tiempo real.",
              icon: Icons.map_rounded,
              color: Colors.greenAccent,
              onTap: () => _onItemTapped(1),
            ),
            const SizedBox(height: 20),
            
            _buildAppCard(
              title: "Análisis",
              subtitle: "Reconocimiento y detección de video.",
              icon: Icons.analytics_rounded,
              color: usfqRed,
              onTap: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard({
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
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
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 14)),
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