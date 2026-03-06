// lib/globals.dart
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

// Este notificador avisará al mapa cuando deba centrarse en una emergencia
final ValueNotifier<LatLng?> sosLocationNotifier = ValueNotifier(null);