class Camera {
  final String camId;
  final String name;
  final String rtspUrl;
  int peopleThreshold;
  final bool isActive;
  int peopleCount;

  Camera({
    required this.camId,
    required this.name,
    required this.rtspUrl,
    required this.peopleThreshold,
    required this.isActive,
    this.peopleCount = 0,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    String resolvedId = json['id']?.toString() ?? json['cam_id']?.toString() ?? '1';

    return Camera(
      camId: resolvedId,
      name: json['name'] ?? 'Cámara',
      rtspUrl: json['rtsp_url'] ?? '',
      peopleThreshold: json['people_threshold'] ?? 5,
      isActive: json['is_active'] ?? false,
    );
  }
}