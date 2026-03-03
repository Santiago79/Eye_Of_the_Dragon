import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/camera_model.dart';
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

  List<Camera> allCameras = [];
  Map<String, List<double>> cameraHistories = {};
  int camerasToShow = 1;
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchCameras();
    // Actualización automática cada 3 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateDensities();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Carga inicial de las cámaras
  Future<void> _fetchCameras() async {
    try {
      final data = await ApiService().getCameras();
      if (!mounted) return;
      
      setState(() {
        allCameras = data;
        if (allCameras.length < camerasToShow) {
          camerasToShow = allCameras.isEmpty ? 0 : allCameras.length;
        }
        isLoading = false;
      });

      // Pedimos la primera lectura de densidad
      _updateDensities();

    } catch (e) {
      debugPrint("Error al cargar cámaras: $e");
      setState(() => isLoading = false);
    }
  }

  // Actualiza solo la telemetría (se llama cada 3 segundos)
  // En tu cameras_page.dart
  Future<void> _updateDensities() async {
    if (allCameras.isEmpty) return;

    for (var cam in allCameras) {
      String id = cam.camId;
      
      // Ahora recibimos el mapa completo con toda la info de la API
      Map<String, dynamic> data = await ApiService().getDensity(id);
      
      if (!mounted) return;
      
      if (data.isNotEmpty && data.containsKey('values')) {
        setState(() {
          // Extraemos el arreglo 'values' que manda Django
          List<dynamic> rawValues = data['values'];
          
          // Lo convertimos a una lista de double que la gráfica pueda leer
          List<double> newHistory = rawValues.map((e) => (e as num).toDouble()).toList();
          
          // Si el arreglo viene muy corto, lo rellenamos con ceros por delante
          if (newHistory.length < 20) {
            int padding = 20 - newHistory.length;
            newHistory = [...List.filled(padding, 0.0), ...newHistory];
          } 
          // Si viene muy largo (Django manda 50 por defecto), nos quedamos con los últimos 20
          else if (newHistory.length > 20) {
            newHistory = newHistory.sublist(newHistory.length - 20);
          }

          // Sobrescribimos la historia completa en nuestra variable
          cameraHistories[id] = newHistory;
          
          // Actualizamos el contador de personas con el valor más reciente del arreglo
          cam.peopleCount = newHistory.last.toInt();
        });
      }
    }
  }

  Future<void> _updateThreshold(String camId, double value) async {
    try {
      await ApiService().updateThreshold(camId, value);
    } catch (e) {
      debugPrint("Error Threshold: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Le preguntamos al dispositivo su orientación actual
    final orientation = MediaQuery.of(context).orientation;
    final bool isPortrait = orientation == Orientation.portrait;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth > 600;
        
        // 2. NUEVA LÓGICA DE COLUMNAS:
        // Si solo hay 1 cámara a mostrar -> 1 columna.
        // Si hay más de 1 cámara -> 1 columna si el celular está vertical, 2 si está horizontal.
        int crossAxisCount = 1;
        if (camerasToShow > 1) {
          crossAxisCount = isPortrait ? 1 : 2;
        }

        // 3. Ajustamos la proporción (aspect ratio) basándonos en las columnas reales que se van a dibujar
        double aspect = (crossAxisCount == 1) 
            ? (isTablet ? 1.6 : 1.15) // Diseño cómodo para 1 columna (vertical)
            : (isTablet ? 1.2 : 0.85); // Diseño para 2 columnas (horizontal)

        return Scaffold(
          backgroundColor: backgroundColor,
          // ... (el resto del Scaffold se queda exactamente igual)
          appBar: AppBar(
            title: const Text("EOTD MONITOR", 
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
            backgroundColor: usfqRed.withOpacity(0.8),
            elevation: 0,
            actions: [
              if (allCameras.isNotEmpty) _buildGridSelector(),
              const SizedBox(width: 10),
            ],
          ),
          body: isLoading
              ? Center(child: CircularProgressIndicator(color: usfqRed))
              : allCameras.isEmpty
                  ? const Center(child: Text("No hay cámaras activas", style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: camerasToShow,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: aspect, 
                      ),
                      itemBuilder: (context, index) => _buildCameraGridItem(allCameras[index]),
                    ),
        );
      },
    );
  }

  Widget _buildGridSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: camerasToShow == 0 ? null : camerasToShow,
        dropdownColor: cardColor,
        underline: const SizedBox(),
        icon: const Icon(Icons.grid_view, color: Colors.white, size: 18),
        items: List.generate(allCameras.length, (index) => index + 1)
            .map((val) => DropdownMenuItem(
                  value: val, 
                  child: Text(" $val ", style: const TextStyle(color: Colors.white))
                )).toList(),
        onChanged: (val) => setState(() => camerasToShow = val ?? 1),
      ),
    );
  }

  Widget _buildCameraGridItem(Camera cameraData) {
    final String camId = cameraData.camId;
    final bool isActive = cameraData.isActive;
    final int threshold = cameraData.peopleThreshold;
    final List<double> history = cameraHistories[camId] ?? List.filled(20, 0.0);

    return GestureDetector(
      // Al tocar, llamamos a la función que crea el efecto Blur
      onTap: () => _showExpandedCamera(cameraData, camId),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.white10 : usfqRed.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            _buildHeader(cameraData.name.toUpperCase(), isActive, cameraData.peopleCount),
            
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: isActive 
                  ? AspectRatio(
                      aspectRatio: 16 / 9,
                      child: MjpegPlayer(
                        url: "${ApiService().baseUrl}/camaras/$camId/live_feed/", 
                        fit: BoxFit.contain
                      ),
                    )
                  : const Icon(Icons.videocam_off, color: Colors.white24, size: 40),
              ),
            ),

            if (isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: _buildChart(history, threshold),
              ),
            
            if (camerasToShow <= 2)
              _buildThresholdSlider(cameraData, camId),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showExpandedCamera(Camera cameraData, String camId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Tinte oscuro para el fondo
      barrierDismissible: true, // Permite cerrar tocando afuera
      barrierLabel: "ExpandedCamera",
      transitionDuration: const Duration(milliseconds: 300), // Velocidad de la animación
      
      // La animación de "Zoom" (ScaleTransition)
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
      
      pageBuilder: (context, animation, secondaryAnimation) {
        // StatefulBuilder nos permite actualizar el slider dentro del popup
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            final bool isActive = cameraData.isActive;
            // Obtenemos la última historia disponible
            final List<double> history = cameraHistories[camId] ?? List.filled(20, 0.0);
            
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // <--- EL EFECTO BLUR
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9, // 90% del ancho
                    height: MediaQuery.of(context).size.height * 0.65, // 65% del alto
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: usfqRed.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                      ]
                    ),
                    child: Column(
                      children: [
                        // Encabezado del Popup con botón de cerrar
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cameraData.name.toUpperCase(), 
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              )
                            ],
                          ),
                        ),
                        
                        // Video Expandido
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.black,
                            child: isActive 
                              ? MjpegPlayer(
                                  url: "${ApiService().baseUrl}/camaras/$camId/live_feed/", 
                                  fit: BoxFit.contain
                                )
                              : const Icon(Icons.videocam_off, color: Colors.white24, size: 60),
                          ),
                        ),

                        // Gráfica y Slider (Reutilizamos tus funciones existentes)
                        if (isActive)
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              children: [
                                _buildChart(history, cameraData.peopleThreshold),
                                const SizedBox(height: 15),
                                // Slider adaptado para el popup usando setStateLocal
                                Row(
                                  children: [
                                    const Icon(Icons.group, color: Colors.white54),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 2,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        ),
                                        child: Slider(
                                          value: cameraData.peopleThreshold.toDouble(),
                                          min: 1, max: 30, activeColor: usfqRed,
                                          onChanged: (val) {
                                            // Actualiza el UI del popup
                                            setStateLocal(() => cameraData.peopleThreshold = val.toInt());
                                            // Actualiza el UI de la pantalla principal atrás
                                            setState(() {}); 
                                          },
                                          onChangeEnd: (val) => _updateThreshold(camId, val),
                                        ),
                                      ),
                                    ),
                                    Text("${cameraData.peopleThreshold}", 
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildChart(List<double> history, int threshold) {
    // Verificamos si el conteo actual supera el umbral para pintar de rojo
    final double currentCount = history.isNotEmpty ? history.last : 0.0;
    final bool isAlert = currentCount > threshold;
    
    // Color dinámico de la gráfica
    final Color chartColor = isAlert ? usfqRed : Colors.greenAccent;

    return SizedBox(
      height: 100, // <--- Altura ampliada para que no se vea aplastada
      child: LineChart(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          // Calculamos el máximo para que la curva nunca se salga por arriba
          maxY: math.max((threshold + 5).toDouble(), currentCount + 5),
          
          // --- CONFIGURACIÓN DE LOS NÚMEROS (EJE Y DERECHO) ---
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30, // Espacio reservado para que los números no pisen la gráfica
                interval: threshold >= 11 ? 5.0 : 2.0,
                getTitlesWidget: (value, meta) {
                  // Ocultamos el 0 y el tope máximo para mantener los bordes limpios
                  if (value == 0 || value == meta.max) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white54, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // --- LÍNEAS DE LA GRÁFICA ---
          lineBarsData: [
            // 1. Línea punteada del límite (Threshold)
            LineChartBarData(
              spots: [FlSpot(0, threshold.toDouble()), FlSpot(19, threshold.toDouble())],
              color: usfqRed.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
            // 2. Curva principal de detecciones
            LineChartBarData(
              spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: chartColor,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true, 
                color: chartColor.withOpacity(0.15)
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader(String name, bool active, int currentCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(name, 
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis),
          ),
          if (active)
            Text("👁 $currentCount", style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildSmallBadge(active),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider(Camera cameraData, String camId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Icon(Icons.group, color: Colors.white54, size: 14),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                value: cameraData.peopleThreshold.toDouble(),
                min: 1, max: 30, activeColor: usfqRed,
                onChanged: (val) => setState(() => cameraData.peopleThreshold = val.toInt()),
                onChangeEnd: (val) => _updateThreshold(camId, val),
              ),
            ),
          ),
          Text("${cameraData.peopleThreshold}", 
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.1) : usfqRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(active ? "LIVE" : "OFFLINE", 
        style: TextStyle(color: active ? Colors.green : usfqRed, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}