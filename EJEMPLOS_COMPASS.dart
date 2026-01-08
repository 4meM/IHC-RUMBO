// 🧭 EJEMPLOS DE USO - COMPASS SERVICE
// Archivo: EJEMPLOS_COMPASS.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lib/features/trip_planner/data/services/compass_service.dart';

// ============================================================================
// EJEMPLO 1: USO BÁSICO - INICIAR Y DETENER LA BRÚJULA
// ============================================================================

class BasicCompassExample {
  late CompassService _compassService;

  void startCompass() {
    // Crear servicio
    _compassService = CompassService();

    // Iniciar a escuchar sensores
    _compassService.startListening();

    // Escuchar cambios en tiempo real
    _compassService.headingStream.listen((heading) {
      print('🧭 Heading actual: ${heading.toStringAsFixed(1)}°');
      print('📍 Dirección cardinal: ${CompassService.headingToDescription(heading)}');
    });
  }

  void stopCompass() {
    _compassService.stopListening();
  }
}

// ============================================================================
// EJEMPLO 2: CALCULAR DIRECCIÓN A UN PARADERO
// ============================================================================

class CalculateBearingExample {
  void calculateDirectionToStop() {
    // Ubicación del usuario
    final userLocation = LatLng(-16.3994, -71.5350);

    // Ubicación del paradero
    final stopLocation = LatLng(-16.4050, -71.5450);

    // Calcular bearing (dirección)
    final bearing = CompassService.calculateBearing(
      userLocation,
      stopLocation,
    );

    print('📍 Bearing (dirección al paradero): ${bearing.toStringAsFixed(1)}°');
    print('🧭 Dirección: ${CompassService.headingToDescription(bearing)}');
    print('📌 Cardinal simple: ${CompassService.getSimpleCardinalDirection(bearing)}');
  }
}

// ============================================================================
// EJEMPLO 3: OBTENER ÁNGULO RELATIVO (IZQUIERDA/DERECHA)
// ============================================================================

class RelativeAngleExample {
  void showRelativeAngle(double deviceHeading, double targetBearing) {
    // Calcular ángulo relativo
    final relativeAngle = CompassService.getRelativeAngle(
      deviceHeading,  // Donde apunta el dispositivo
      targetBearing,  // Donde está el paradero
    );

    // Interpretar resultado
    if (relativeAngle > 0) {
      print('➡️  PARADERO A LA DERECHA: ${relativeAngle.abs().toStringAsFixed(1)}°');
    } else if (relativeAngle < 0) {
      print('⬅️  PARADERO A LA IZQUIERDA: ${relativeAngle.abs().toStringAsFixed(1)}°');
    } else {
      print('⬆️  PARADERO ADELANTE: 0°');
    }
  }

  void exampleScenarios() {
    // Escenario 1: Dispositivo apunta Norte, paradero está al Este
    print('\n--- ESCENARIO 1 ---');
    double deviceHeading = 0;      // Apunta al Norte
    double targetBearing = 90;     // Paradero al Este
    showRelativeAngle(deviceHeading, targetBearing);
    // Salida: ➡️  PARADERO A LA DERECHA: 90°

    // Escenario 2: Dispositivo apunta Este, paradero está al Sur
    print('\n--- ESCENARIO 2 ---');
    deviceHeading = 90;    // Apunta al Este
    targetBearing = 180;   // Paradero al Sur
    showRelativeAngle(deviceHeading, targetBearing);
    // Salida: ➡️  PARADERO A LA DERECHA: 90°

    // Escenario 3: Dispositivo apunta Sur, paradero está al Sur
    print('\n--- ESCENARIO 3 ---');
    deviceHeading = 180;   // Apunta al Sur
    targetBearing = 180;   // Paradero al Sur
    showRelativeAngle(deviceHeading, targetBearing);
    // Salida: ⬆️  PARADERO ADELANTE: 0°

    // Escenario 4: Dispositivo apunta Oeste, paradero está al Norte
    print('\n--- ESCENARIO 4 ---');
    deviceHeading = 270;   // Apunta al Oeste
    targetBearing = 0;     // Paradero al Norte
    showRelativeAngle(deviceHeading, targetBearing);
    // Salida: ⬅️  PARADERO A LA IZQUIERDA: 90°
  }
}

// ============================================================================
// EJEMPLO 4: CONVERSIÓN DE HEADING A DIRECCIÓN CARDINAL
// ============================================================================

class CardinalDirectionExample {
  void demonstrateDirections() {
    // Versión simple (8 direcciones)
    print('--- SIMPLES (8 Direcciones) ---');
    for (int i = 0; i < 360; i += 45) {
      final cardinal = CompassService.getSimpleCardinalDirection(i.toDouble());
      print('$i° = $cardinal');
    }
    // Salida:
    // 0° = N
    // 45° = NE
    // 90° = E
    // 135° = SE
    // 180° = S
    // 225° = SW
    // 270° = W
    // 315° = NW

    print('\n--- DESCRIPCIÓN EN ESPAÑOL ---');
    for (int i = 0; i < 360; i += 45) {
      final description = CompassService.headingToDescription(i.toDouble());
      print('$i° = $description');
    }
    // Salida:
    // 0° = Norte
    // 45° = Noreste
    // 90° = Este
    // 135° = Sureste
    // 180° = Sur
    // 225° = Suroeste
    // 270° = Oeste
    // 315° = Noroeste
  }
}

// ============================================================================
// EJEMPLO 5: INTEGRACIÓN EN UN WIDGET (CON ESTADO)
// ============================================================================

import 'package:flutter/material.dart';

class CompassDisplayWidget extends StatefulWidget {
  const CompassDisplayWidget({Key? key}) : super(key: key);

  @override
  State<CompassDisplayWidget> createState() => _CompassDisplayWidgetState();
}

class _CompassDisplayWidgetState extends State<CompassDisplayWidget> {
  late CompassService _compassService;
  double _currentHeading = 0.0;
  String _cardinal = 'Norte';

  @override
  void initState() {
    super.initState();

    // Crear y iniciar compass
    _compassService = CompassService();
    _compassService.startListening();

    // Escuchar cambios
    _compassService.headingStream.listen((heading) {
      if (mounted) {
        setState(() {
          _currentHeading = heading;
          _cardinal = CompassService.headingToDescription(heading);
        });
      }
    });
  }

  @override
  void dispose() {
    _compassService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mostrar grados
        Text(
          '${_currentHeading.toStringAsFixed(1)}°',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        // Mostrar dirección en español
        Text(
          _cardinal,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        // Mostrar flecha
        Icon(
          Icons.arrow_upward,
          size: 64,
          color: Colors.blue,
        ),
      ],
    );
  }
}

// ============================================================================
// EJEMPLO 6: MÚLTIPLES PARADEROS - COMPARAR DISTANCIAS
// ============================================================================

import 'lib/features/trip_planner/data/models/smart_bus_stop_model.dart';

class MultipleStopsCompassExample {
  late CompassService _compassService;
  final userLocation = LatLng(-16.3994, -71.5350);

  // 3 paraderos
  late List<SmartBusStopModel> stops;

  void setup() {
    _compassService = CompassService();
    _compassService.startListening();

    // Simular 3 paraderos (ajustado a la definición real de SmartBusStopModel)
    stops = [
      SmartBusStopModel(
        id: '1',
        name: 'Paradero 1',
        location: LatLng(-16.4000, -71.5360),
        type: SmartStopType.nearest,
        walkingDistance: 75,
        estimatedBusDistance: 200,
        estimatedWaitTime: 5,
        estimatedTravelTime: 10,
        crowdLevel: 0.3,
        estimatedAvailableSeats: 15,
        reason: 'Más cercano',
        routes: ['4A'],
      ),
      SmartBusStopModel(
        id: '2',
        name: 'Paradero 2',
        location: LatLng(-16.4050, -71.5450),
        type: SmartStopType.avoidTraffic,
        walkingDistance: 150,
        estimatedBusDistance: 300,
        estimatedWaitTime: 8,
        estimatedTravelTime: 15,
        crowdLevel: 0.2,
        estimatedAvailableSeats: 22,
        reason: 'Evita tráfico',
        routes: ['4A'],
      ),
      SmartBusStopModel(
        id: '3',
        name: 'Paradero 3',
        location: LatLng(-16.3950, -71.5300),
        type: SmartStopType.guaranteedSeats,
        walkingDistance: 120,
        estimatedBusDistance: 250,
        estimatedWaitTime: 6,
        estimatedTravelTime: 12,
        crowdLevel: 0.1,
        estimatedAvailableSeats: 28,
        reason: 'Más asientos',
        routes: ['4A'],
      ),
    ];
  }

  void displayAllStopsWithDirection(double deviceHeading) {
    print('\n=== PARADEROS VISIBLES ===');
    print('🧭 Dispositivo apunta: ${CompassService.headingToDescription(deviceHeading)}');
    print('');

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];

      // Calcular bearing
      final bearing = CompassService.calculateBearing(
        userLocation,
        stop.location,
      );

      // Calcular ángulo relativo
      final relativeAngle = CompassService.getRelativeAngle(
        deviceHeading,
        bearing,
      );

      // Interpretar posición
      String positionText;
      if (relativeAngle.abs() < 15) {
        positionText = '⬆️  ADELANTE';
      } else if (relativeAngle > 0) {
        positionText = '➡️  DERECHA (${relativeAngle.toStringAsFixed(0)}°)';
      } else {
        positionText = '⬅️  IZQUIERDA (${relativeAngle.abs().toStringAsFixed(0)}°)';
      }

      print('${i + 1}. ${stop.type.displayName}');
      print('   📍 Bearing: ${bearing.toStringAsFixed(0)}°');
      print('   📏 Distancia: ${stop.distance}m');
      print('   📌 Ubicación: $positionText');
      print('   👥 Ocupación: ${(stop.crowdLevel * 100).toStringAsFixed(0)}%');
      print('   🪑 Asientos: ${stop.availableSeats}');
      print('');
    }
  }
}

// ============================================================================
// EJEMPLO 7: DETECCIÓN DE ROTACIÓN COMPLETA (360°)
// ============================================================================

class RotationDetectionExample {
  late CompassService _compassService;
  double _lastHeading = 0.0;
  int _rotationCount = 0;

  void startDetection() {
    _compassService = CompassService();
    _compassService.startListening();

    _compassService.headingStream.listen((heading) {
      // Detectar si hay un "wrap around" de 360 a 0
      if (_lastHeading > 270 && heading < 90) {
        _rotationCount++;
        print('🔄 Rotación completada #$_rotationCount');
      }

      _lastHeading = heading;
    });
  }

  void stopDetection() {
    _compassService.stopListening();
    print('Total de rotaciones: $_rotationCount');
  }
}

// ============================================================================
// EJEMPLO 8: STREAMING EN TIEMPO REAL
// ============================================================================

class RealTimeStreamExample {
  void demonstrateStream() {
    final compassService = CompassService();
    compassService.startListening();

    // Escuchar stream y actualizar en tiempo real
    int updateCount = 0;
    compassService.headingStream.listen(
      (heading) {
        updateCount++;
        if (updateCount % 10 == 0) {
          // Mostrar cada 10 actualizaciones
          print(
            'Actualización #$updateCount: '
            'Heading=${heading.toStringAsFixed(1)}° '
            'Cardinal=${CompassService.getSimpleCardinalDirection(heading)}',
          );
        }
      },
      onError: (error) {
        print('❌ Error en stream: $error');
      },
      onDone: () {
        print('✅ Stream finalizado');
      },
    );
  }
}

// ============================================================================
// EJEMPLO 9: USAR EN PÁGINA ACTUAL (SMART_STOPS_AR_VIEW)
// ============================================================================

/*
Esto es exactamente lo que hace SmartStopsARView:

class _SmartStopsARViewState extends State<SmartStopsARView> {
  late CompassService _compassService;
  double _deviceHeading = 0.0;
  int _currentStopIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Crear y iniciar compass
    _compassService = CompassService();
    _compassService.startListening();
    
    // Escuchar cambios
    _compassService.headingStream.listen((heading) {
      if (mounted) {
        setState(() {
          _deviceHeading = heading;
        });
      }
    });
  }

  @override
  void dispose() {
    _compassService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stops[_currentStopIndex];
    
    // Calcular bearing al paradero actual
    final bearing = CompassService.calculateBearing(
      widget.userLocation,
      stop.location,
    );
    
    // Calcular ángulo relativo
    final relativeAngle = CompassService.getRelativeAngle(
      _deviceHeading,
      bearing,
    );
    
    return Stack(
      children: [
        // Pantalla simulada de AR (PageView)
        PageView(
          children: [
            _buildStopARCard(stop, bearing, relativeAngle),
            // ... más paraderos
          ],
        ),
      ],
    );
  }

  Widget _buildStopARCard(
    SmartBusStopModel stop,
    double bearing,
    double relativeAngle,
  ) {
    return Column(
      children: [
        // Brújula rotatoria
        CustomPaint(
          painter: CompassPainter(_deviceHeading),
          size: const Size(120, 120),
        ),
        // Información
        Text('${bearing.toStringAsFixed(0)}°'),
        Text(CompassService.getSimpleCardinalDirection(bearing)),
        Text('${stop.distance}m'),
      ],
    );
  }
}
*/

// ============================================================================
// EJEMPLO 10: DEBUGGING - MOSTRAR TODOS LOS VALORES
// ============================================================================

class DebugCompassExample {
  void debugAllValues() {
    final userLoc = LatLng(-16.3994, -71.5350);
    final stopLoc = LatLng(-16.4050, -71.5450);
    final deviceHeading = 45.0; // Ejemplo: apunta Noreste

    print('\n=== DEBUG - TODOS LOS VALORES ===');

    // Bearing
    final bearing = CompassService.calculateBearing(userLoc, stopLoc);
    print('Bearing: ${bearing.toStringAsFixed(1)}°');

    // Dirección cardinal del bearing
    final cardinal = CompassService.getSimpleCardinalDirection(bearing);
    print('Cardinal (bearing): $cardinal');

    // Descripción del bearing
    final description = CompassService.headingToDescription(bearing);
    print('Descripción (bearing): $description');

    // Ángulo relativo
    final relativeAngle = CompassService.getRelativeAngle(deviceHeading, bearing);
    print('Ángulo relativo: ${relativeAngle.toStringAsFixed(1)}°');

    // Interpretación
    if (relativeAngle > 0) {
      print('Posición: A LA DERECHA');
    } else if (relativeAngle < 0) {
      print('Posición: A LA IZQUIERDA');
    } else {
      print('Posición: ADELANTE');
    }

    // Device heading info
    print('\nDispositivo apunta: ${CompassService.headingToDescription(deviceHeading)}');
    print('Device Heading: ${deviceHeading.toStringAsFixed(1)}°');

    // Distancia
    final distance = _calculateDistance(userLoc, stopLoc);
    print('\nDistancia: ${distance.toStringAsFixed(0)}m');
  }

  // Haversine formula para distancia
  double _calculateDistance(LatLng from, LatLng to) {
    const double radius = 6371000; // Radio de la Tierra en metros

    final double dLat = _toRadians(to.latitude - from.latitude);
    final double dLng = _toRadians(to.longitude - from.longitude);

    final double sinDLat = (dLat / 2).sin();
    final double sinDLng = (dLng / 2).sin();

    final double a = sinDLat * sinDLat +
        (from.latitude).cos() *
            (to.latitude).cos() *
            sinDLng *
            sinDLng;

    final double c = 2 * a.sqrt().atan2((1 - a).sqrt());

    return radius * c;
  }

  double _toRadians(double degrees) => degrees * (3.14159265359 / 180);
}

// ============================================================================
// EJECUTAR EJEMPLOS
// ============================================================================

void main() {
  print('🧭 EJEMPLOS DE COMPASS SERVICE\n');

  print('--- EJEMPLO 4: DIRECCIONES CARDINALES ---');
  CardinalDirectionExample().demonstrateDirections();

  print('\n--- EJEMPLO 3: ÁNGULOS RELATIVOS ---');
  RelativeAngleExample().exampleScenarios();

  print('\n--- EJEMPLO 10: DEBUG ---');
  DebugCompassExample().debugAllValues();
}
