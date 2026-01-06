import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/ar_bus_marker.dart';
import '../../domain/entities/ar_bus_stop.dart';
import '../../domain/entities/ar_user_location.dart';

class ARCameraLive extends StatefulWidget {
  final ARUserLocation? userLocation;
  final List<ARBusMarker> nearbyBuses;
  final ARBusStop? nearestBusStop;

  const ARCameraLive({
    Key? key,
    required this.userLocation,
    required this.nearbyBuses,
    this.nearestBusStop,
  }) : super(key: key);

  @override
  State<ARCameraLive> createState() => _ARCameraLiveState();
}

class _ARCameraLiveState extends State<ARCameraLive> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  // Sensores
  double _heading = 0.0; // Brújula (0-360 grados)
  double _pitch = 0.0; // Inclinación arriba/abajo
  double _roll = 0.0; // Inclinación izquierda/derecha

  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<MagnetometerEvent> _magnetometerSubscription;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSensors();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.first;

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _cameraController.initialize();
      setState(() {});
    } catch (e) {
      print('Error inicializando cámara: $e');
    }
  }

  void _initializeSensors() {
    // Acelerómetro para detectar pitch y roll
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        // Convertir aceleraciones a ángulos
        _pitch = math.atan2(event.y, math.sqrt(event.x * event.x + event.z * event.z)) * (180 / math.pi);
        _roll = math.atan2(event.x, math.sqrt(event.y * event.y + event.z * event.z)) * (180 / math.pi);
      });
    });

    // Magnetómetro para detectar orientación (brújula)
    _magnetometerSubscription =
        magnetometerEvents.listen((MagnetometerEvent event) {
      setState(() {
        _heading = math.atan2(event.y, event.x) * (180 / math.pi);
        if (_heading < 0) {
          _heading += 360;
        }
      });
    });

    // Giroscopio para mayor precisión (opcional)
    _gyroscopeSubscription =
        gyroscopeEvents.listen((GyroscopeEvent event) {
      // El giroscopio proporciona velocidad angular
      // Puede usarse para suavizar la detección
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _accelerometerSubscription.cancel();
    _magnetometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[AR CAMERA LIVE BUILD] userLocation=${widget.userLocation}, nearestBusStop=${widget.nearestBusStop?.name}');
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              // Vista de la cámara
              CameraPreview(_cameraController),

              // Overlay con información de sensores
              Positioned(
                top: 16,
                left: 16,
                child: _buildSensorInfo(),
              ),

              // Marcadores de paraderos superpuestos
              if (widget.userLocation != null) ...[
                // Paradero más cercano
                if (widget.nearestBusStop != null)
                  _buildBusStopOverlay(widget.nearestBusStop!),

                // Buses cercanos
                ..._buildBusOverlays(),
              ],

              // Brújula en la esquina inferior derecha
              Positioned(
                bottom: 32,
                right: 16,
                child: _buildCompass(),
              ),

              // Información de instrucciones
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildInstructions(),
              ),
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildSensorInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Brújula: ${_heading.toStringAsFixed(0)}°',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Pitch: ${_pitch.toStringAsFixed(1)}°',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
          Text(
            'Roll: ${_roll.toStringAsFixed(1)}°',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusStopOverlay(ARBusStop busStop) {
    // Calcular si el paradero está visible en la pantalla
    final isVisible = _isBusStopVisible(busStop);

    print('[AR OVERLAY] ${busStop.name}: visible=$isVisible, lat=${busStop.latitude}, lng=${busStop.longitude}');

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final position = _calculateScreenPosition(busStop);

    return Positioned(
      left: position['x'] as double,
      top: position['y'] as double,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marcador del paradero
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_filled,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 8),
          // Tarjeta de información
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.greenAccent, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  busStop.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rutas: ${busStop.routes.join(", ")}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBusOverlays() {
    return widget.nearbyBuses
        .where((bus) => _isBusVisible(bus))
        .map((bus) {
          final position = _calculateBusScreenPosition(bus);
          return Positioned(
            left: position['x'] as double,
            top: position['y'] as double,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.cyan,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.cyan, width: 1),
                  ),
                  child: Text(
                    'Bus ${bus.busNumber}',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        })
        .toList();
  }

  Widget _buildCompass() {
    return Transform.rotate(
      angle: _heading * (math.pi / 180),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.7),
          border: Border.all(color: Colors.cyan, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.navigation,
              color: Colors.red,
              size: 30,
            ),
            Positioned(
              top: 8,
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '📱 Mueve el teléfono para encontrar paraderos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Los marcadores aparecerán cuando apuntes en esa dirección',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Calcula si el paradero es visible en el campo de visión actual
  bool _isBusStopVisible(ARBusStop busStop) {
    if (widget.userLocation == null) {
      print('[AR DEBUG] No hay ubicación del usuario');
      return false;
    }

    final bearing = _calculateBearing(
      widget.userLocation!.latitude,
      widget.userLocation!.longitude,
      busStop.latitude,
      busStop.longitude,
    );

    // Campo de visión horizontal de ~60 grados (realista como AR Core)
    final fov = 60.0;
    final diff = (bearing - _heading).abs();
    final normalizedDiff = diff > 180 ? 360 - diff : diff;

    final isVisible = normalizedDiff < fov;
    print('[AR DEBUG] ${busStop.name}: bearing=$bearing, heading=$_heading, diff=${diff.toStringAsFixed(1)}, normalized=$normalizedDiff, visible=$isVisible, fov=$fov');

    return isVisible;
  }

  /// Calcula si el bus es visible en el campo de visión actual
  bool _isBusVisible(ARBusMarker bus) {
    final bearing = bus.bearing;
    final fov = 60.0;
    final diff = (bearing - _heading).abs();
    final normalizedDiff = diff > 180 ? 360 - diff : diff;

    return normalizedDiff < fov;
  }

  /// Calcula la posición en pantalla del paradero
  Map<String, double> _calculateScreenPosition(ARBusStop busStop) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    if (widget.userLocation == null) {
      return {'x': centerX - 40, 'y': centerY - 40};
    }

    final bearing = _calculateBearing(
      widget.userLocation!.latitude,
      widget.userLocation!.longitude,
      busStop.latitude,
      busStop.longitude,
    );

    // Mapear bearing a posición horizontal
    final diff = bearing - _heading;
    final fov = 60.0;
    final screenX = (diff.abs() / fov) * (screenSize.width / 2);

    // Mapear pitch a posición vertical
    final screenY = ((_pitch + 30) / 60) * screenSize.height;

    final finalX = centerX + (diff > 0 ? screenX : -screenX) - 40;
    final finalY = screenY - 40;
    
    print('[AR SCREEN] ${busStop.name}: screenSize=${screenSize.width}x${screenSize.height}, diff=$diff, screenX=$screenX, screenY=$screenY, final=($finalX, $finalY)');

    return {
      'x': finalX,
      'y': finalY,
    };
  }

  /// Calcula la posición en pantalla del bus
  Map<String, double> _calculateBusScreenPosition(ARBusMarker bus) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;

    final bearing = bus.bearing;
    final diff = bearing - _heading;
    final fov = 50.0;
    final screenX = (diff.abs() / fov) * (screenSize.width / 2);
    final screenY = ((_pitch + 30) / 60) * screenSize.height;

    return {
      'x': centerX + (diff > 0 ? screenX : -screenX) - 30,
      'y': screenY - 30,
    };
  }

  /// Calcula el bearing entre dos puntos
  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _degreesToRadians(lng2 - lng1);
    final y = math.sin(dLng) * math.cos(_degreesToRadians(lat2));
    final x = math.cos(_degreesToRadians(lat1)) * math.sin(_degreesToRadians(lat2)) -
        math.sin(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) * math.cos(dLng);
    var bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
