import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';               // Para el Timer
import 'package:latlong2/latlong.dart'; // Para las coordenadas
import '../globals.dart';          // Nuestro walkie-talkie
import 'package:geolocator/geolocator.dart'; // <-- OBLIGATORIO PARA EL GPS

// Importa tus pantallas
import 'mapa.dart'; // O el nombre correcto de tu archivo de mapa
import "analisis_page.dart";
import "cameras_page.dart";
import "sos_page.dart";       // <--- IMPORTA LA NUEVA PÁGINA
import "alertas_page.dart";   // <--- IMPORTA LA NUEVA PÁGINA

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _rol = "";
  bool _isLoading = true;

  // --- NUEVAS VARIABLES PARA EL RADAR ---
  Timer? _sosTimer;
  Timer? _rastreadorGlobalTimer; // <-- NUEVA VARIABLE PARA EL GPS
  int _cantidadAlertasAnterior = 0;

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

 Future<void> _cargarRol() async {
    String rolExtraido = await ApiService().getUserRole();
    setState(() {
      _rol = rolExtraido;
      _isLoading = false;
    });

    // Si es admin, encendemos el radar de notificaciones en tiempo real
    if (_rol == 'administrador') {
      _iniciarRadarSOS();
    }
    _iniciarRastreadorGlobal();
  }

  bool _esPrimerEscaneo = true;

  void _iniciarRadarSOS() {
    _sosTimer?.cancel(); // <--- SEGURO DE VIDA
    _sosTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final alertas = await ApiService().getSOSAlerts();
        if (!_esPrimerEscaneo && alertas.length > _cantidadAlertasAnterior) {
          final nuevaAlerta = alertas.first;
          _mostrarNotificacion(nuevaAlerta);
        }
        _cantidadAlertasAnterior = alertas.length;
        _esPrimerEscaneo = false;
      } catch (e) {}
    });
  }

  // ===================================================
  // RASTREADOR GPS GLOBAL (SEGUNDO PLANO)
  // ===================================================
  void _iniciarRastreadorGlobal() {
    _reportarUbicacionSilenciosa();
    
    _rastreadorGlobalTimer?.cancel(); // <--- SEGURO DE VIDA
    _rastreadorGlobalTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _reportarUbicacionSilenciosa();
    });
  }

  Future<void> _reportarUbicacionSilenciosa() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      // ¡AQUÍ ESTABA EL ERROR! Faltaba pedir el permiso la primera vez.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // Si a pesar de pedirlo lo denegó, nos salimos sin congelar la app
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5)
      );
      
      await ApiService().updateLocation(pos.latitude, pos.longitude, pos.accuracy);
    } catch (e) {
      try {
        Position? lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          await ApiService().updateLocation(lastPos.latitude, lastPos.longitude, lastPos.accuracy);
        }
      } catch (_) {}
    }
  }

  void _mostrarNotificacion(Map<String, dynamic> alerta) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 8), // Dura 8 segundos en pantalla
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text("🚨 ¡SOS de ${alerta['emisor']}!", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        action: SnackBarAction(
          label: "IR AL MAPA",
          textColor: Colors.white,
          backgroundColor: Colors.black45,
          onPressed: () {
            // 1. Mandamos la señal por el walkie-talkie
            sosLocationNotifier.value = LatLng(alerta['lat'], alerta['lon']);
            // 2. Forzamos el cambio al tab del mapa (Índice 1 en el Admin)
            setState(() => _selectedIndex = 1);
          },
        ),
      ),
    );
  }

@override
  void dispose() {
    _sosTimer?.cancel();             // Apagamos el radar del admin
    _rastreadorGlobalTimer?.cancel();// Apagamos el rastreador GPS
    super.dispose();
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

    // Pantalla de espera mientras leemos el Token
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: usfqRed)),
      );
    }

    bool isAdmin = _rol == 'administrador';

    // 1. PANTALLAS SEGÚN EL ROL
    final List<Widget> pagesAdmin = [
      _buildDashboard(isAdmin),
      const MapaPage(),         // Índice 1
      
      // Le pasamos la función a la bandeja de alertas
      AlertasPage(
        onGoToMap: (lat, lon) {
          sosLocationNotifier.value = LatLng(lat, lon);
          setState(() => _selectedIndex = 1);
        },
      ),      
      
      const AnalisisPage(),     // Índice 3
      const CamerasPage(),      // Índice 4
    ];

    final List<Widget> pagesGuardia = [
      _buildDashboard(isAdmin),
      const SosPage(),          // Índice 1
      const AnalisisPage(),     // Índice 2
      const CamerasPage(),      // Índice 3
    ];

    final List<Widget> currentPages = isAdmin ? pagesAdmin : pagesGuardia;

    // Protección de índices
    if (_selectedIndex >= currentPages.length) {
      _selectedIndex = 0;
    }

    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
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
          children: currentPages,
        ),

        // 2. BOTONES DEL MENÚ INFERIOR SEGÚN EL ROL
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E1E2F),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: usfqRed,
          unselectedItemColor: Colors.white54,
          elevation: 10,
          items: isAdmin
              ? const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Inicio"),
                  BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Mapa"),
                  BottomNavigationBarItem(icon: Icon(Icons.warning_rounded), label: "Alertas"),
                  BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: "Análisis"),
                  BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: "Cámaras"),
                ]
              : const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Inicio"),
                  BottomNavigationBarItem(icon: Icon(Icons.emergency), label: "SOS"),
                  BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: "Análisis"),
                  BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: "Cámaras"),
                ],
        ),
      ),
    );
  }

  // 3. EL DASHBOARD DINÁMICO
  Widget _buildDashboard(bool isAdmin) {
    const Color usfqRed = Color(0xFFDC3545);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bienvenido, ${isAdmin ? 'Administrador' : 'Agente'}", style: const TextStyle(color: Colors.white70, fontSize: 18)),
            const Text("Panel de Control", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            if (isAdmin) ...[
              // --- TARJETAS DE ADMINISTRADOR ---
              _buildAppCard(
                title: "Mapa Táctico",
                subtitle: "Ubicación de cámaras y personal.",
                icon: Icons.map_rounded,
                color: Colors.greenAccent,
                onTap: () => _onItemTapped(1),
              ),
              const SizedBox(height: 20),
              _buildAppCard(
                title: "Bandeja de Alertas",
                subtitle: "Gestión de incidentes y SOS.",
                icon: Icons.warning_rounded,
                color: Colors.orangeAccent,
                onTap: () => _onItemTapped(2),
              ),
              const SizedBox(height: 20),
              _buildAppCard(
                title: "Análisis de Video",
                subtitle: "Reconocimiento y densidad.",
                icon: Icons.analytics_rounded,
                color: usfqRed,
                onTap: () => _onItemTapped(3),
              ),
              const SizedBox(height: 20),
              _buildAppCard(
                title: "Cámaras en Vivo",
                subtitle: "Transmisión de red CCTV.",
                icon: Icons.videocam_rounded,
                color: Colors.blueAccent,
                onTap: () => _onItemTapped(4),
              ),
            ] else ...[
              // --- TARJETAS DE GUARDIA DE SEGURIDAD ---
              _buildAppCard(
                title: "EMERGENCIA SOS",
                subtitle: "Enviar alerta inmediata a la central.",
                icon: Icons.emergency,
                color: Colors.redAccent,
                onTap: () => _onItemTapped(1), // Manda al índice 1 (SOS) del guardia
              ),
              const SizedBox(height: 20),
              _buildAppCard(
                title: "Análisis Rápido",
                subtitle: "Analizar video sospechoso local.",
                icon: Icons.analytics_rounded,
                color: usfqRed,
                onTap: () => _onItemTapped(2), // Manda al índice 2 del guardia
              ),
              const SizedBox(height: 20),
              _buildAppCard(
                title: "Cámaras de Sector",
                subtitle: "Verificar actividad en el área.",
                icon: Icons.videocam_rounded,
                color: Colors.blueAccent,
                onTap: () => _onItemTapped(3), // Manda al índice 3 del guardia
              ),
            ]
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