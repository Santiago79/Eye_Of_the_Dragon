import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';

class AnalisisPage extends StatefulWidget {
  const AnalisisPage({super.key});

  @override
  State<AnalisisPage> createState() => _AnalisisPageState();
}

class _AnalisisPageState extends State<AnalisisPage> {
  static const Color bgColor = Color(0xFF161625);
  static const Color cardColor = Color(0xFF232335);
  static const Color usfqRed = Color(0xFFDC3545);

  // AHORA GUARDAMOS UNA LISTA DE RUTAS Y NOMBRES
  List<String> _rutasVideosSeleccionados = [];
  List<String> _nombresVideosSeleccionados = [];

  bool _isAnalyzing = false;
  List<dynamic> _activeAnalyses = [];

  final TextEditingController _inicioController =
      TextEditingController(text: "0");
  final TextEditingController _finController =
      TextEditingController(text: "60");
  final TextEditingController _thresholdController =
      TextEditingController(text: "5");

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  // ==========================================
  // 1. SELECCIONAR MÚLTIPLES VIDEOS
  // ==========================================
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true, // <--- MAGIA: Permite elegir varios
    );

    if (result != null) {
      setState(() {
        _rutasVideosSeleccionados = result.paths.whereType<String>().toList();
        _nombresVideosSeleccionados = result.names.whereType<String>().toList();
      });
    }
  }

  // ==========================================
  // 2. ENVIAR AL BACKEND (Usando tu ApiService)
  // ==========================================
  Future<void> _enviarAnalisis() async {
    if (_rutasVideosSeleccionados.isEmpty) {
      _showSnackBar("Por favor, selecciona al menos un video.");
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // Usamos la función que ya tenías lista en tu ApiService
      await ApiService().uploadVideoForAnalysis(
        filePaths: _rutasVideosSeleccionados,
        startTime: double.tryParse(_inicioController.text) ?? 0.0,
        endTime: double.tryParse(_finController.text) ?? 60.0,
        threshold: int.tryParse(_thresholdController.text) ?? 5,
      );

      _showSnackBar("🚀 Análisis en lote enviado a la cola");

      // Limpiamos el formulario
      setState(() {
        _rutasVideosSeleccionados.clear();
        _nombresVideosSeleccionados.clear();
      });

      _checkStatus();
    } catch (e) {
      _showSnackBar("Error de conexión: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _checkStatus() async {
    try {
      final threads = await ApiService().getAnalysisStatus();
      if (mounted) {
        setState(() {
          _activeAnalyses = threads;
        });
      }
    } catch (e) {
      print("Error obteniendo status: $e");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
          title: const Text("CVPack - Análisis Batch"),
          backgroundColor: usfqRed),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildUploadPanel(),
            const SizedBox(height: 25),
            _buildStatusPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPanel() {
    String textBoton = _rutasVideosSeleccionados.isEmpty
        ? "Seleccionar Videos"
        : "${_rutasVideosSeleccionados.length} video(s) seleccionado(s)";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(textBoton,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.video_library, color: Colors.white),
            onTap: _pickFile,
            tileColor: Colors.white10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),

          // Muestra la lista de nombres si seleccionó alguno
          if (_nombresVideosSeleccionados.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 5),
              child: Text(
                _nombresVideosSeleccionados.join(", "),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _timeField("Inicio (s)", _inicioController)),
              const SizedBox(width: 15),
              Expanded(child: _timeField("Fin (s)", _finController)),
              const SizedBox(width: 15),
              Expanded(child: _timeField("Umbral", _thresholdController)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _enviarAnalisis,
              style: ElevatedButton.styleFrom(
                  backgroundColor: usfqRed,
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("INICIAR ANÁLISIS MÚLTIPLE",
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hilos de Análisis",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _checkStatus,
                tooltip: "Actualizar estado",
              )
            ],
          ),
          const SizedBox(height: 15),
          _activeAnalyses.isEmpty
              ? const Text("No hay procesos activos.",
                  style: TextStyle(color: Colors.white38))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activeAnalyses.length,
                  itemBuilder: (context, index) {
                    final t = _activeAnalyses[index];
                    bool isFinished = t['status'] == 'finished';
                    bool isError = t['status'] == 'error';

                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(t['name'],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        subtitle: Text("Estado: ${t['status'].toUpperCase()}",
                            style: TextStyle(
                                color: isFinished
                                    ? Colors.green
                                    : (isError ? Colors.red : Colors.orange),
                                fontWeight: FontWeight.bold)),
                        trailing: isFinished
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : (isError
                                ? const Icon(Icons.error, color: Colors.red)
                                : const CircularProgressIndicator(
                                    strokeWidth: 2)),
                        onTap: isFinished
                            ? () {
                                if (t['report_files'] != null &&
                                    t['report_files'].isNotEmpty) {
                                  // Abre el popup enviando la lista completa de reportes generados
                                  _mostrarSelectorDeResultados(
                                      t['report_files']);
                                } else {
                                  _showSnackBar(
                                      "El reporte aún no está disponible.");
                                }
                              }
                            : null,
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  Widget _timeField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24)),
        focusedBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: usfqRed)),
      ),
    );
  }

  // ==================== ZOOM DE IMÁGENES ====================
  void _mostrarImagenGrande(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        );
      },
    );
  }

  // ==================== SELECTOR DE RESULTADOS MULTIPLES ====================
  void _mostrarSelectorDeResultados(List<dynamic> reportesList) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Selecciona el reporte a ver:",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reportesList.length,
                  itemBuilder: (context, idx) {
                    final rep = reportesList[idx];
                    final bool esResumen = rep['kind'] == 'summary';

                    return ListTile(
                      leading: Icon(
                          esResumen ? Icons.bar_chart : Icons.video_file,
                          color: usfqRed),
                      title: Text(rep['video_label'] ?? "Video ${idx + 1}",
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context); // Cierra el menú inferior
                        _mostrarResultados(rep); // Abre el popup de siempre
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== POPUP DE RESULTADOS INDIVIDUALES ====================
  void _mostrarResultados(Map<String, dynamic> reportes) {
    String baseUrl = ApiService().baseUrl;

    String fixUrl(String? path) {
      if (path == null || path.isEmpty) return "";
      if (path.startsWith('http')) return path;
      path = path.replaceAll('file://', '');
      if (!path.startsWith('/')) path = '/$path';
      if (!path.startsWith('/media')) path = '/media$path';
      return "$baseUrl$path";
    }

    String plotUrl = fixUrl(reportes['plot']);
    String frameUrl = fixUrl(reportes['frame']);
    String videoUrl = fixUrl(reportes['video']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(reportes['video_label'] ?? "Resultados",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reportes['plot'] != null) ...[
                  const Text("📊 Gráfica de Densidad",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _mostrarImagenGrande(plotUrl),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(plotUrl, fit: BoxFit.cover)),
                  ),
                  const SizedBox(height: 20),
                ],
                if (reportes['frame'] != null) ...[
                  const Text("📸 Máxima concentración",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _mostrarImagenGrande(frameUrl),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(frameUrl, fit: BoxFit.cover)),
                  ),
                  const SizedBox(height: 20),
                ],
                if (reportes['video'] != null && reportes['video'] != "") ...[
                  const Text("🎥 Video Procesado",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ReproductorVideo(urlVideo: videoUrl),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CERRAR",
                  style:
                      TextStyle(color: usfqRed, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
}

// ==================== WIDGET: REPRODUCTOR DE VIDEO ====================
class ReproductorVideo extends StatefulWidget {
  final String urlVideo;

  const ReproductorVideo({super.key, required this.urlVideo});

  @override
  State<ReproductorVideo> createState() => _ReproductorVideoState();
}

class _ReproductorVideoState extends State<ReproductorVideo> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.urlVideo))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      }).catchError((error) {
        print("Error cargando video: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(
        height: 150,
        child: Center(
            child:
                CircularProgressIndicator(color: _AnalisisPageState.usfqRed)),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white,
                size: 40,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
          ],
        )
      ],
    );
  }
}
