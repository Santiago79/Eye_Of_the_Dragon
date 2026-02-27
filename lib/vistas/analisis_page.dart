import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
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
    _checkStatus(); // Cargar estado inicial
  }

  // 1. SELECCIÓN DE ARCHIVO
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
        fileName = result.files.first.name;
      });
    }
  }

  // 2. LANZAR ANÁLISIS (POST)
  Future<void> _enviarAnalisis() async {
    if (_selectedFile == null) return;
    setState(() => _isAnalyzing = true);

    try {
      // Importante: Sacar el token de tu ApiService/SecureStorage
      String? token = await ApiService().getToken(); 

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.123.186.26:8001/cvpack/video-analysis/")
      );

      // Headers de Autorización para saltar el @login_required
      request.headers['Authorization'] = 'Bearer $token';

      // Campos según tu VideoAnalysisForm en Django
      request.fields['start_time'] = _inicioController.text;
      request.fields['end_time'] = _finController.text;
      request.fields['people_threshold'] = "5"; // Valor por defecto
      
      // El nombre del campo DEBE ser video_files según tu views.py
      request.files.add(await http.MultipartFile.fromPath(
        'video_files', 
        _selectedFile!.path,
        filename: p.basename(_selectedFile!.path),
      ));

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 302) {
        _showSnackBar("🚀 Análisis enviado");
        _checkStatus();
      } else {
        _showSnackBar("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Error de conexión");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // 3. CONSULTAR ESTADO (GET)
  Future<void> _checkStatus() async {
    try {
      String? token = await ApiService().getToken();
      final response = await http.get(
        Uri.parse("http://10.123.186.26:8001/cvpack/status/"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _activeAnalyses = data['threads'];
        });
      }
    } catch (e) {
      print("Error status: $e");
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
            // Panel de subida
            _buildUploadPanel(),
            const SizedBox(height: 25),
            // Panel de hilos activos
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
              style: ElevatedButton.styleFrom(backgroundColor: usfqRed),
              child: _isAnalyzing ? const CircularProgressIndicator() : const Text("ANALIZAR VIDEO"),
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
          const Text("Hilos de Análisis", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _activeAnalyses.isEmpty 
            ? const Text("No hay procesos activos.", style: TextStyle(color: Colors.white38))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _activeAnalyses.length,
                itemBuilder: (context, index) {
                  final t = _activeAnalyses[index];
                  return ListTile(
                    title: Text(t['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                    subtitle: Text("Estado: ${t['status']}", style: TextStyle(color: t['status'] == 'running' ? Colors.orange : Colors.green)),
                    trailing: t['status'] == 'finished' ? const Icon(Icons.download, color: Colors.white) : const CircularProgressIndicator(strokeWidth: 2),
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
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60)),
    );
  }
}