import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../globals.dart';
import '../services/api_service.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final ApiService apiService = ApiService();
  
  // Coordenadas centrales de la USFQ
  static const LatLng centroUSFQ = LatLng(-0.1973, -78.4355);
  static const Color usfqRed = Color(0xFFDC3545);
  static const Color bgColor = Color(0xFF1E1E2F);
  static const Color cardColor = Color(0xFF232335); // Color para el panel de filtros

  List<dynamic> _simulatedNodes = [];
  List<dynamic> _realUsers = [];
  Timer? _timer;
  
  final MapController _mapController = MapController();
  bool _isLocating = false;
  LatLng? _sosPuntoCritico; // Aquí guardaremos dónde fue la emergencia
  Timer? _sosMarcadorTimer; // Para borrar el marcador después de unos segundos

  // =======================================================
  // NUEVO: ESTADO DE LOS FILTROS
  // =======================================================
  final Map<String, bool> _filtrosActivos = {
    'estudiante': true,
    'profesor': true,
    'personal administrativo': true,
    'personal de limpieza': true,
    'seguridad': true,
    'desconocido': true,
  };

  @override
  void initState() {
    super.initState();
    _fetchMapData();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Solo pedimos datos a Django si la pantalla del mapa sigue viva en el celular
      if (mounted) {
        _fetchMapData();
      }
    });

    sosLocationNotifier.addListener(_volarHaciaSOS);
  }

 void _volarHaciaSOS() {
    final latlng = sosLocationNotifier.value;
    if (latlng != null) {
      _mapController.move(latlng, 19.5);
      
      setState(() {
        _sosPuntoCritico = latlng; // Guardamos el punto
      });

      // El marcador rojo desaparecerá automáticamente después de 30 segundos
      _sosMarcadorTimer?.cancel();
      _sosMarcadorTimer = Timer(const Duration(seconds: 30), () {
        if (mounted) setState(() => _sosPuntoCritico = null);
      });

      sosLocationNotifier.value = null; 
      _showSnack("📍 Mostrando ubicación de emergencia", isSuccess: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    sosLocationNotifier.removeListener(_volarHaciaSOS); 
    super.dispose();
  }

  Future<void> _fetchMapData() async {
    try {
      final simData = await apiService.getMapNodes();
      final usersData = await apiService.getUsersLocations();

      setState(() {
        if (simData.containsKey('nodes')) {
          _simulatedNodes = simData['nodes'];
        } else {
          _simulatedNodes = simData['points'] ?? simData['nodos'] ?? [];
        }
        _realUsers = usersData['users'] ?? [];
      });
    } catch (e) {
      print("Error actualizando mapa: $e");
    }
  }

  Future<void> _enviarMiUbicacion() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack("Por favor, enciende el GPS de tu celular.");
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack("Permisos de ubicación denegados.");
          setState(() => _isLocating = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showSnack("Permisos denegados permanentemente. Actívalos en Ajustes.");
        setState(() => _isLocating = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      _mapController.move(LatLng(position.latitude, position.longitude), 18.5);

      await apiService.updateLocation(
        position.latitude, 
        position.longitude, 
        position.accuracy
      );
      
      _showSnack("📍 Ubicación actualizada en el sistema", isSuccess: true);
      _fetchMapData();

    } catch (e) {
      _showSnack("Error de GPS: $e");
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? Colors.green : usfqRed,
      duration: const Duration(seconds: 2),
    ));
  }

  // =======================================================
  // NUEVO: PANEL DESLIZANTE DE FILTROS
  // =======================================================
  void _mostrarMenuFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // StatefulBuilder permite actualizar los checkboxes sin cerrar el panel
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtros del Mapa", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ..._filtrosActivos.keys.map((String categoria) {
                    return CheckboxListTile(
                      title: Text(
                        categoria.toUpperCase(), 
                        style: const TextStyle(color: Colors.white70, fontSize: 14)
                      ),
                      activeColor: _getColorForCategory(categoria),
                      checkColor: Colors.white,
                      value: _filtrosActivos[categoria],
                      onChanged: (bool? value) {
                        // 1. Actualizamos el switch visual en el panel
                        setModalState(() {
                          _filtrosActivos[categoria] = value ?? true;
                        });
                        // 2. Actualizamos el mapa en el fondo
                        setState(() {});
                      },
                    );
                  }),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: usfqRed,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MAPA DEL CAMPUS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Nodos activos: ${_simulatedNodes.length + _realUsers.length}", style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
      // Usamos un Stack para poner los botones flotantes en las esquinas inferiores
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: centroUSFQ,
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.app_movil_cam_maps.usfq',
                tileBuilder: (context, tileWidget, tile) {
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
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          
          // NUEVO: BOTÓN DE FILTROS (Izquierda)
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: "btn_filtros",
              backgroundColor: cardColor,
              onPressed: _mostrarMenuFiltros,
              child: const Icon(Icons.filter_list, color: Colors.white, size: 24),
            ),
          ),

          // BOTÓN DE UBICACIÓN (Derecha)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: "btn_loc",
              backgroundColor: usfqRed,
              onPressed: _isLocating ? null : _enviarMiUbicacion,
              child: _isLocating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.my_location, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'estudiante': return Colors.blue;
      case 'personal administrativo': return Colors.green;
      case 'personal de limpieza': return Colors.orange;
      case 'profesor': return Colors.purpleAccent;
      case 'seguridad': return Colors.lightBlue;
      default: return Colors.grey;
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // 1. Dibujar los Nodos Simulados 
    for (var node in _simulatedNodes) {
      double? lat = double.tryParse(node['lat']?.toString() ?? '');
      double? lon = double.tryParse(node['lon']?.toString() ?? '');
      
      if (lat != null && lon != null) {
        String categoria = (node['categoria'] ?? 'desconocido').toString().toLowerCase();
        
        // REVISIÓN DEL FILTRO: Solo dibujamos si la categoría está activa
        if (_filtrosActivos[categoria] == true || (_filtrosActivos.containsKey(categoria) == false && _filtrosActivos['desconocido'] == true)) {
          Color nodeColor = _getColorForCategory(categoria);

          markers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 10,
              height: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          );
        }
      }
    }

    // 2. Dibujar Usuarios/Guardias Reales
    for (var user in _realUsers) {
      double? lat = double.tryParse(user['lat']?.toString() ?? '');
      double? lon = double.tryParse(user['lon']?.toString() ?? '');
      
      if (lat != null && lon != null) {
        String rol = (user['rol'] ?? 'seguridad').toString().toLowerCase();

        // REVISIÓN DEL FILTRO: Los usuarios reales suelen ser 'seguridad' o 'administrador'.
        if (_filtrosActivos[rol] == true || _filtrosActivos['seguridad'] == true) {
          markers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  _showSnack("${user['nombre']} - ${user['rol']}", isSuccess: true);
                },
                child: const Tooltip(
                  message: "Usuario Real",
                  child: Icon(Icons.person_pin_circle, color: usfqRed, size: 35),
                ),
              ),
            )
          );
        }
      }
    }

    // 3. Dibujar el SOS si hay una emergencia activa
    if (_sosPuntoCritico != null) {
      markers.add(
        Marker(
          point: _sosPuntoCritico!,
          width: 80, height: 80,
          child: const Tooltip(
            message: "¡EMERGENCIA AQUÍ!",
            child: Icon(Icons.emergency_share, color: Colors.redAccent, size: 60),
          ),
        )
      );
    }

    return markers;
  }
}