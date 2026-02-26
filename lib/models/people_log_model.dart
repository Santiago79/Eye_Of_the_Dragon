class PeopleLog {
  final int id;
  final String cameraId;
  final DateTime timestamp;
  final int peopleCount;

  PeopleLog({
    required this.id,
    required this.cameraId,
    required this.timestamp,
    required this.peopleCount,
  });

  factory PeopleLog.fromJson(Map<String, dynamic> json) {
    return PeopleLog(
      id: json['id'],
      cameraId: json['camera_id'],
      timestamp: DateTime.parse(json['timestamp']),
      peopleCount: json['people_count'],
    );
  }
}