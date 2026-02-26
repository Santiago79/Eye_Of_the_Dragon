import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MjpegPlayer extends StatefulWidget {
  final String url;
  final BoxFit fit;
  const MjpegPlayer({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  State<MjpegPlayer> createState() => _MjpegPlayerState();
}

class _MjpegPlayerState extends State<MjpegPlayer> {
  final StreamController<Uint8List> _frameController = StreamController();
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  void _startStreaming() async {
  _client = http.Client();
  try {
    final request = http.Request('GET', Uri.parse(widget.url));
    // Si usas autenticación JWT, descomenta la siguiente línea:
    // request.headers['Authorization'] = 'Bearer TU_TOKEN_AQUI';

    final response = await _client!.send(request);

    List<int> chunks = [];

    response.stream.listen(
      (List<int> chunk) {
        chunks.addAll(chunk);

        while (true) {
          // 1. Buscamos el inicio de una imagen JPEG (Marcador SOI: 0xFF 0xD8)
          int startIdx = -1;
          for (int i = 0; i < chunks.length - 1; i++) {
            if (chunks[i] == 0xff && chunks[i + 1] == 0xd8) {
              startIdx = i;
              break;
            }
          }

          // Si no hay inicio, descartamos basura y esperamos más datos
          if (startIdx == -1) {
            // Dejamos el último byte por si es el inicio de un marcador 0xFF
            if (chunks.length > 1) {
              chunks = chunks.sublist(chunks.length - 1);
            }
            break; 
          }

          // 2. Buscamos el final de la imagen JPEG (Marcador EOI: 0xFF 0xD9)
          int endIdx = -1;
          for (int i = startIdx; i < chunks.length - 1; i++) {
            if (chunks[i] == 0xff && chunks[i + 1] == 0xd9) {
              endIdx = i + 2; // Incluimos los dos bytes del marcador de fin
              break;
            }
          }

          // 3. Si tenemos inicio y fin, extraemos el frame puro
          if (endIdx != -1) {
            final frameData = Uint8List.fromList(chunks.sublist(startIdx, endIdx));
            
            if (!_frameController.isClosed) {
              _frameController.add(frameData);
            }

            // Eliminamos el frame procesado del buffer y seguimos buscando en el resto
            chunks = chunks.sublist(endIdx);
          } else {
            // Tenemos inicio pero no fin, necesitamos esperar al siguiente chunk
            // Limpiamos la basura que haya antes del startIdx para no procesarla de nuevo
            if (startIdx > 0) {
              chunks = chunks.sublist(startIdx);
            }
            break;
          }
        }
      },
      onError: (e) {
        print("Error en el stream MJPEG: $e");
        _startStreaming(); // Reintento automático si falla la red
      },
      cancelOnError: false,
    );
  } catch (e) {
    print("Error crítico conectando al servidor de video: $e");
    // Reintentar después de un par de segundos si el servidor está caído
    Future.delayed(const Duration(seconds: 2), _startStreaming);
  }
}

  @override
  void dispose() {
    _client?.close();
    _frameController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Uint8List>(
      stream: _frameController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2));
        }
        return Image.memory(
          snapshot.data!, 
          fit: widget.fit, 
          gaplessPlayback: true, // Vital para fluidez
        );
      },
    );
  }
}