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
    
    _refreshTimer?.cancel(); // <--- MATA CUALQUIER CLON PREVIO
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateDensities();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

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

      _updateDensities();
    } catch (e) {
      debugPrint("Error al cargar cámaras: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateDensities() async {
    if (allCameras.isEmpty) return;

    for (var cam in allCameras) {
      String id = cam.camId;
      Map<String, dynamic> data = await ApiService().getDensity(id);
      
      if (!mounted) return;
      
      if (data.isNotEmpty && data.containsKey('values')) {
        setState(() {
          List<dynamic> rawValues = data['values'];
          List<double> newHistory = rawValues.map((e) => (e as num).toDouble()).toList();
          
          if (newHistory.length < 20) {
            int padding = 20 - newHistory.length;
            newHistory = [...List.filled(padding, 0.0), ...newHistory];
          } else if (newHistory.length > 20) {
            newHistory = newHistory.sublist(newHistory.length - 20);
          }

          cameraHistories[id] = newHistory;
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("EOTD MONITOR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
        backgroundColor: usfqRed.withOpacity(0.8),
        elevation: 0,
        actions: [
          if (allCameras.isNotEmpty) _buildGridSelector(),
          const SizedBox(width: 10),
        ],
      ),
      // OrientationBuilder nos dice si el teléfono está vertical u horizontal
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (isLoading) {
            return Center(child: CircularProgressIndicator(color: usfqRed));
          }
          if (allCameras.isEmpty) {
            return const Center(child: Text("No hay cámaras activas", style: TextStyle(color: Colors.white54)));
          }

          final bool isPortrait = orientation == Orientation.portrait;

          // Si solo mostramos 1 cámara y estamos en horizontal, usamos el diseño dividido
          if (!isPortrait && camerasToShow == 1) {
            return _buildLandscapeSingleCamera(allCameras[0]);
          }

          // Si estamos en vertical, o si hay varias cámaras en horizontal, usamos GridView
          return _buildGridView(isPortrait);
        },
      ),
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

  // =========================================================
  // DISEÑO 1: GRIDVIEW (Para Vertical y Múltiples Cámaras)
  // =========================================================
  Widget _buildGridView(bool isPortrait) {
    int crossAxisCount = isPortrait ? 1 : 2;

    if (crossAxisCount == 1) {
      // SOLUCIÓN TABLET: Una lista normal que se expande sin límites de altura
      return ListView.separated(
        padding: const EdgeInsets.all(15),
        itemCount: camerasToShow,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) => _buildCameraCard(allCameras[index]),
      );
    } else {
      // Si el celular está acostado (2 columnas), mantenemos el GridView
      return GridView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: camerasToShow,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          mainAxisExtent: 420, // Le damos un poquito más de respiro al diseño horizontal
        ),
        itemBuilder: (context, index) => _buildCameraCard(allCameras[index]),
      );
    }
  }

  // Tarjeta individual para el GridView
  Widget _buildCameraCard(Camera cameraData) {
    final String camId = cameraData.camId;
    final bool isActive = cameraData.isActive;
    final int threshold = cameraData.peopleThreshold;
    final List<double> history = cameraHistories[camId] ?? List.filled(20, 0.0);

    return GestureDetector(
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
            
            // EL VIDEO CON ASPECT RATIO 16:9 FORZADO
            Container(
              width: double.infinity,
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: isActive 
                  ? MjpegPlayer(key: ValueKey(camId),url: "${ApiService().baseUrl}/camaras/$camId/live_feed/", fit: BoxFit.contain)
                  : const Icon(Icons.videocam_off, color: Colors.white24, size: 40),
              ),
            ),

            // LA GRÁFICA Y SLIDER (Se empujan abajo naturalmente)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isActive) Expanded(child: _buildChart(history, threshold)),
                    if (camerasToShow <= 2) _buildThresholdSlider(cameraData, camId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DISEÑO 2: LADO A LADO (Horizontal con 1 sola cámara)
  // =========================================================
  Widget _buildLandscapeSingleCamera(Camera cameraData) {
    final String camId = cameraData.camId;
    final bool isActive = cameraData.isActive;
    final int threshold = cameraData.peopleThreshold;
    final List<double> history = cameraHistories[camId] ?? List.filled(20, 0.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LADO IZQUIERDO: VIDEO (65% del espacio)
        Expanded(
          flex: 65,
          child: Container(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? Colors.white10 : usfqRed.withOpacity(0.3)),
            ),
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: isActive 
                      ? MjpegPlayer(key: ValueKey(camId), url: "${ApiService().baseUrl}/camaras/$camId/live_feed/", fit: BoxFit.contain)
                      : const Icon(Icons.videocam_off, color: Colors.white24, size: 40),
                  ),
                ),
                Positioned(
                  top: 10, left: 10, right: 10,
                  child: _buildHeader(cameraData.name.toUpperCase(), isActive, cameraData.peopleCount, transparent: true),
                ),
              ],
            ),
          ),
        ),

        // LADO DERECHO: GRÁFICA Y CONTROLES (35% del espacio)
        Expanded(
          flex: 35,
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 15, 15, 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Análisis en Vivo", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (isActive) Expanded(child: _buildChart(history, threshold)),
                const SizedBox(height: 20),
                const Text("Umbral de Alerta:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                _buildThresholdSlider(cameraData, camId),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // COMPONENTES REUTILIZABLES (Los tuyos, sin tocar la lógica)
  // =========================================================

  Widget _buildHeader(String name, bool active, int currentCount, {bool transparent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: transparent ? Colors.black45 : Colors.transparent,
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
    return Row(
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

  Widget _buildChart(List<double> history, int threshold) {
    final double currentCount = history.isNotEmpty ? history.last : 0.0;
    final bool isAlert = currentCount > threshold;
    final Color chartColor = isAlert ? usfqRed : Colors.greenAccent;

    return LineChart(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: math.max((threshold + 5).toDouble(), currentCount + 5),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: threshold >= 11 ? 5.0 : 2.0,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, threshold.toDouble()), FlSpot(19, threshold.toDouble())],
            color: usfqRed.withOpacity(0.5),
            barWidth: 1,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: chartColor,
            barWidth: 2,
            belowBarData: BarAreaData(show: true, color: chartColor.withOpacity(0.15)),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  // El Popup con el efecto Blur
  void _showExpandedCamera(Camera cameraData, String camId) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: true,
      barrierLabel: "ExpandedCamera",
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            final bool isActive = cameraData.isActive;
            final List<double> history = cameraHistories[camId] ?? List.filled(20, 0.0);
            
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.65,
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
                        
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.black,
                            child: isActive 
                              ? AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: MjpegPlayer(key: ValueKey(camId),url: "${ApiService().baseUrl}/camaras/$camId/live_feed/", fit: BoxFit.contain),
                                )
                              : const Icon(Icons.videocam_off, color: Colors.white24, size: 60),
                          ),
                        ),

                        if (isActive)
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              children: [
                                SizedBox(height: 100, child: _buildChart(history, cameraData.peopleThreshold)),
                                const SizedBox(height: 15),
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
                                            setStateLocal(() => cameraData.peopleThreshold = val.toInt());
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
}