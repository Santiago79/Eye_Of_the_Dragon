// lib/pages/sos_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  bool _isSending = false;

  Future<void> _dispararSOS() async {
    setState(() => _isSending = true);
    try {
      // 1. Verificamos permisos básicos de GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Activa el GPS de tu celular.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Permisos denegados.");
      }

      // 2. Obtenemos ubicación exacta
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 3. Enviamos alerta a Django
      await ApiService().sendSOSAlert(position.latitude, position.longitude);
      
      // 4. Mostramos confirmación
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.red.shade900,
            title: const Text("¡ALERTA ENVIADA!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text("La central ha recibido tu ubicación exacta. Mantén la calma.", style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161625),
      appBar: AppBar(title: const Text("MODO PATRULLAJE"), backgroundColor: const Color(0xFFDC3545)),
      body: Center(
        child: SingleChildScrollView( // <--- ¡LA CURA MÁGICA!
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.white24),
            const SizedBox(height: 20),
            const Text("UNIDAD DE SEGURIDAD USFQ", style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: _isSending ? null : _dispararSOS,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 40, spreadRadius: 15),
                  ],
                ),
                child: _isSending
                    ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4))
                    : const Center(
                        child: Text("SOS", style: TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold, letterSpacing: 5)),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            const Text("Presiona el botón solo en caso de\nemergencia real o incidente.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      ),
      ),
    );
  }
}