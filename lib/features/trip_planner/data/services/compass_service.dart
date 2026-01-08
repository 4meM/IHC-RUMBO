import 'dart:async';
import 'dart:math' as Math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Servicio que proporciona datos en tiempo real de la brújula del dispositivo
class CompassService {
  static final CompassService _instance = CompassService._internal();

  factory CompassService() {
    return _instance;
  }

  CompassService._internal();

  final _headingController = StreamController<double>.broadcast();
  StreamSubscription? _magnetometerSubscription;
  StreamSubscription? _accelerometerSubscription;

  double _currentHeading = 0.0; // Heading actual (0-360 grados)
  List<double> _magnetometerValues = [0, 0, 0];
  List<double> _accelerometerValues = [0, 0, 0];

  /// Stream de heading en tiempo real (0-360 grados)
  /// 0 = Norte, 90 = Este, 180 = Sur, 270 = Oeste
  Stream<double> get headingStream => _headingController.stream;

  /// Heading actual en grados (0-360)
  double get currentHeading => _currentHeading;

  /// Inicia a escuchar los sensores del dispositivo
  Future<void> startListening() async {
    try {
      // Escuchar magnetómetro (brújula)
      _magnetometerSubscription = magnetometerEvents.listen(
        (event) {
          _magnetometerValues = [event.x, event.y, event.z];
          _calculateHeading();
        },
        onError: (e) {
          print('Error de magnetómetro: $e');
        },
      );

      // Escuchar acelerómetro (orientación del dispositivo)
      _accelerometerSubscription = accelerometerEvents.listen(
        (event) {
          _accelerometerValues = [event.x, event.y, event.z];
          _calculateHeading();
        },
        onError: (e) {
          print('Error de acelerómetro: $e');
        },
      );

      print('✅ Compass service iniciado');
    } catch (e) {
      print('❌ Error iniciando compass: $e');
    }
  }

  /// Detiene de escuchar los sensores
  Future<void> stopListening() async {
    await _magnetometerSubscription?.cancel();
    await _accelerometerSubscription?.cancel();
    print('✅ Compass service detenido');
  }

  /// Calcula el heading basado en magnetómetro y acelerómetro
  void _calculateHeading() {
    // Implementación simplificada del cálculo de heading
    // En un caso real, usaría una librería como `flutter_compass`

    final x = _magnetometerValues[0];
    final y = _magnetometerValues[1];

    // Usar atan2 para calcular el ángulo
    var heading = Math.atan2(y, x) * (180 / Math.pi);

    // Convertir a rango 0-360
    heading = (heading + 360) % 360;

    // Aplicar suavizado para evitar fluctuaciones
    _currentHeading = _smoothHeading(_currentHeading, heading);

    // Emitir el nuevo heading
    _headingController.add(_currentHeading);
  }

  /// Suaviza el heading usando promedio móvil
  double _smoothHeading(double oldHeading, double newHeading) {
    // Evitar el salto de 360→0
    var diff = newHeading - oldHeading;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    // Aplicar factor de suavizado (0.1 = 10% nuevo valor, 90% valor anterior)
    return (oldHeading + diff * 0.1) % 360;
  }

  /// Calcula el bearing (dirección) desde un punto a otro
  /// Retorna valor de 0-360 grados
  /// 0 = Norte, 90 = Este, 180 = Sur, 270 = Oeste
  static double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * Math.pi / 180;
    final lat2 = to.latitude * Math.pi / 180;
    final dLon = (to.longitude - from.longitude) * Math.pi / 180;

    final y = Math.sin(dLon) * Math.cos(lat2);
    final x = Math.cos(lat1) * Math.sin(lat2) -
        Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);

    var bearing = Math.atan2(y, x) * 180 / Math.pi;

    // Convertir a rango 0-360
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  /// Calcula el ángulo relativo entre el heading del dispositivo y la dirección al paradero
  /// Retorna: ángulo de -180 a +180 grados
  /// Positivo = a la derecha, Negativo = a la izquierda
  static double getRelativeAngle(double deviceHeading, double targetBearing) {
    var angle = targetBearing - deviceHeading;

    // Normalizar a rango -180 a +180
    if (angle > 180) {
      angle -= 360;
    } else if (angle < -180) {
      angle += 360;
    }

    return angle;
  }

  /// Retorna dirección cardinal (N, NE, E, SE, S, SW, W, NW)
  static String getCardinalDirection(double heading) {
    final directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((heading + 11.25) / 22.5).toInt() % 16;
    return directions[index];
  }

  /// Retorna dirección cardinal simplificada (N, NE, E, SE, S, SW, W, NW)
  static String getSimpleCardinalDirection(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((heading + 22.5) / 45).toInt() % 8;
    return directions[index];
  }

  /// Convierte heading a descripción de dirección
  static String headingToDescription(double heading) {
    heading = heading % 360;

    if (heading < 22.5 || heading >= 337.5) return 'Norte';
    if (heading < 67.5) return 'Noreste';
    if (heading < 112.5) return 'Este';
    if (heading < 157.5) return 'Sureste';
    if (heading < 202.5) return 'Sur';
    if (heading < 247.5) return 'Suroeste';
    if (heading < 292.5) return 'Oeste';
    return 'Noroeste';
  }

  /// Limpiar recursos
  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _headingController.close();
  }
}
