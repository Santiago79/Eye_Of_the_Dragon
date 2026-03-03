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
    return Camera(
      camId: json['cam_id'],
      name: json['name'],
      rtspUrl: json['rtsp_url'],
      peopleThreshold: json['people_threshold'],
      isActive: json['is_active'],
    );
  }
}