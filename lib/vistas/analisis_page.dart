import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
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
  
  File? _selectedFile;
  String? fileName;
  bool _isAnalyzing = false;
  List<dynamic> _activeAnalyses = [];

  final TextEditingController _inicioController = TextEditingController(text: "0");
  final TextEditingController _finController = TextEditingController(text: "60");

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
        fileName = result.files.first.name;
      });
    }
  }

  Future<void> _enviarAnalisis() async {
    if (_selectedFile == null) return;
    setState(() => _isAnalyzing = true);

    try {
      String? token = await ApiService().getToken(); 
      String baseUrl = ApiService().baseUrl;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/cvpack/api/video-analysis/start/")
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['start_time'] = _inicioController.text;
      request.fields['end_time'] = _finController.text;
      request.fields['people_threshold'] = "5"; 
      
      request.files.add(await http.MultipartFile.fromPath(
        'video_files', 
        _selectedFile!.path,
        filename: p.basename(_selectedFile!.path),
      ));

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("🚀 Análisis enviado a la cola");
        _checkStatus();
      } else {
        var respStr = await response.stream.bytesToString();
        _showSnackBar("Error ${response.statusCode}: $respStr");
      }
    } catch (e) {
      _showSnackBar("Error de conexión: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _checkStatus() async {
    try {
      String? token = await ApiService().getToken();
      String baseUrl = ApiService().baseUrl;

      final response = await http.get(
        Uri.parse("$baseUrl/cvpack/api/video-analysis/status/"),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _activeAnalyses = data['threads'];
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
      appBar: AppBar(title: const Text("CVPack - Análisis"), backgroundColor: usfqRed),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            title: Text(fileName ?? "Seleccionar Video", style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.attach_file, color: Colors.white),
            onTap: _pickFile,
            tileColor: Colors.white10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _timeField("Inicio (s)", _inicioController)),
              const SizedBox(width: 15),
              Expanded(child: _timeField("Fin (s)", _finController)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _enviarAnalisis,
              style: ElevatedButton.styleFrom(
                backgroundColor: usfqRed,
                padding: const EdgeInsets.symmetric(vertical: 15)
              ),
              child: _isAnalyzing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("ANALIZAR VIDEO", style: TextStyle(fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hilos de Análisis", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _checkStatus,
                tooltip: "Actualizar estado",
              )
            ],
          ),
          const SizedBox(height: 15),
          _activeAnalyses.isEmpty 
            ? const Text("No hay procesos activos.", style: TextStyle(color: Colors.white38))
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
                      title: Text(t['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text("Estado: ${t['status'].toUpperCase()}", 
                        style: TextStyle(
                          color: isFinished ? Colors.green : (isError ? Colors.red : Colors.orange),
                          fontWeight: FontWeight.bold
                        )
                      ),
                      trailing: isFinished 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : (isError ? const Icon(Icons.error, color: Colors.red) : const CircularProgressIndicator(strokeWidth: 2)),
                      onTap: isFinished ? () {
                        if (t['report_files'] != null && t['report_files'].isNotEmpty) {
                          _mostrarResultados(t['report_files'][0]);
                        } else {
                          _showSnackBar("El reporte aún no está disponible.");
                        }
                      } : null,
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
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: usfqRed)),
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

  // ==================== POPUP DE RESULTADOS ====================
  void _mostrarResultados(Map<String, dynamic> reportes) {
    String baseUrl = ApiService().baseUrl;

    // Helper para armar la URL completa y limpiar el "file://"
    String fixUrl(String? path) {
      if (path == null || path.isEmpty) return "";
      if (path.startsWith('http')) return path;
      
      // 1. Limpiamos el texto problemático "file://"
      path = path.replaceAll('file://', '');
      
      // 2. Aseguramos que tenga el formato web correcto
      if (!path.startsWith('/')) path = '/$path';
      if (!path.startsWith('/media')) path = '/media$path'; 
      
      return "$baseUrl$path";
    }

    // Convertimos las rutas relativas en URLs absolutas
    String plotUrl = fixUrl(reportes['plot']);
    String frameUrl = fixUrl(reportes['frame']);
    String videoUrl = fixUrl(reportes['video']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Resultados del Análisis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reportes['plot'] != null) ...[
                  const Text("📊 Gráfica de Densidad (Toca para ampliar)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _mostrarImagenGrande(plotUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(plotUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (reportes['frame'] != null) ...[
                  const Text("📸 Máxima concentración (Toca para ampliar)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _mostrarImagenGrande(frameUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(frameUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (reportes['video'] != null) ...[
                  const Text("🎥 Video Procesado", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // AQUÍ INCRUSTAMOS EL REPRODUCTOR
                  ReproductorVideo(urlVideo: videoUrl),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CERRAR", style: TextStyle(color: usfqRed, fontWeight: FontWeight.bold)),
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
    // Inicializamos el video apuntando a tu URL de Django arreglada
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
        child: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
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
                _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
                size: 40,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
            ),
          ],
        )
      ],
    );
  }
}