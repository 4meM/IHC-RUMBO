import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/ar_bus_marker.dart';
import '../../domain/entities/ar_bus_stop.dart';
import '../../domain/entities/ar_user_location.dart';

class ARCameraView extends StatefulWidget {
  final ARUserLocation? userLocation;
  final List<ARBusMarker> nearbyBuses;
  final ARBusStop? nearestBusStop;

  const ARCameraView({
    Key? key,
    required this.userLocation,
    required this.nearbyBuses,
    this.nearestBusStop,
  }) : super(key: key);

  @override
  State<ARCameraView> createState() => _ARCameraViewState();
}

class _ARCameraViewState extends State<ARCameraView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo simulado de cámara
        Container(
          color: Colors.black87,
          child: Center(
            child: CustomPaint(
              painter: ARGridPainter(),
              size: Size.infinite,
            ),
          ),
        ),

        // Mostrar paradero más cercano si existe
        if (widget.userLocation != null && widget.nearestBusStop != null)
          ..._buildBusStopMarker(context),

        // Mostrar buses cercanos con animaciones AR
        if (widget.userLocation != null)
          ..._buildARMarkers(context),

        // HUD (Información en pantalla)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildARHUD(),
        ),

        // Brújula/Orientación
        Positioned(
          bottom: 32,
          right: 16,
          child: _buildCompass(),
        ),
      ],
    );
  }

  List<Widget> _buildBusStopMarker(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    final busStop = widget.nearestBusStop!;

    // Calcular distancia aproximada (simplificado)
    const earthRadiusKm = 6371;
    final dLat = _degreesToRadians(
      busStop.latitude - widget.userLocation!.latitude,
    );
    final dLng = _degreesToRadians(
      busStop.longitude - widget.userLocation!.longitude,
    );

    final a = (dLat / 2) * (dLat / 2) + (dLng / 2) * (dLng / 2);
    final c = 2 * (a.abs());
    final distance = earthRadiusKm * c * 1000; // metros

    // Calcular bearing (dirección)
    final bearing = _calculateBearing(
      widget.userLocation!.latitude,
      widget.userLocation!.longitude,
      busStop.latitude,
      busStop.longitude,
    );

    final angle = bearing * (math.pi / 180);

    // Mapear distancia a posición en pantalla
    final screenDistance = (distance / 1000) * math.min(centerX, centerY);

    final offsetX = screenDistance * math.sin(angle);
    final offsetY = -screenDistance * math.cos(angle);

    return [
      Positioned(
        left: centerX + offsetX - 50,
        top: centerY + offsetY - 50,
        child: ScaleTransition(
          scale: _animationController,
          child: _buildBusStopIcon(busStop, distance),
        ),
      ),
    ];
  }

  Widget _buildBusStopIcon(ARBusStop busStop, double distance) {
    final isVeryClose = distance < 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícono de paradero
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isVeryClose
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (isVeryClose ? Colors.green : Colors.blue)
                    .withOpacity(0.8),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.directions_bus_filled,
                size: 50,
                color: Colors.white,
              ),
              if (isVeryClose)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow.shade600,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Información del paradero
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isVeryClose ? Colors.greenAccent : Colors.cyan,
              width: 2,
            ),
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
                '${distance.toStringAsFixed(0)} m',
                style: TextStyle(
                  color: isVeryClose ? Colors.greenAccent : Colors.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildARMarkers(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    return widget.nearbyBuses.map((bus) {
      final angle = bus.bearing * (math.pi / 180);
      final distance = bus.distance;

      // Mapear distancia a posición en pantalla (1000m = borde de pantalla)
      final screenDistance = (distance / 1000) * math.min(centerX, centerY);

      final offsetX = screenDistance * math.sin(angle);
      final offsetY = -screenDistance * math.cos(angle);

      return Positioned(
        left: centerX + offsetX - 40,
        top: centerY + offsetY - 40,
        child: ScaleTransition(
          scale: _animationController,
          child: _buildBusMarker(bus, distance),
        ),
      );
    }).toList();
  }

  Widget _buildBusMarker(ARBusMarker bus, double distance) {
    final scale = math.max(0.5, 1.0 - (distance / 1000) * 0.5);

    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono de bus con gradiente
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.cyan,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.directions_bus,
                  size: 40,
                  color: Colors.white,
                ),
                // Indicador de movimiento
                Positioned(
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${bus.speed.toStringAsFixed(0)} km/h',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Información del bus
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Autobús ${bus.busNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  bus.routeName,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${(distance / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(
                    color: Colors.lightBlue,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARHUD() {
    if (widget.userLocation == null) {
      return const SizedBox.shrink();
    }

    final location = widget.userLocation!;
    final busCount = widget.nearbyBuses.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AR VIEW',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACTIVO',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ubicación: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            'Precisión: ${location.accuracy.toStringAsFixed(1)} m',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.directions_bus,
                size: 14,
                color: Colors.cyan,
              ),
              const SizedBox(width: 4),
              Text(
                '$busCount autobuses cercanos',
                style: const TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompass() {
    if (widget.userLocation == null) {
      return const SizedBox.shrink();
    }

    final heading = widget.userLocation!.heading;

    return Transform.rotate(
      angle: heading * (math.pi / 180),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.7),
          border: Border.all(color: Colors.cyan, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Puntos cardinales
            Positioned(
              top: 4,
              child: const Text(
                'N',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
            Positioned(
              left: 4,
              child: const Text(
                'O',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
            Positioned(
              right: 4,
              child: const Text(
                'E',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
            // Aguja de brújula
            Transform.rotate(
              angle: -heading * (math.pi / 180),
              child: Container(
                width: 2,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pintor personalizado para la cuadrícula AR
class ARGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 0.5;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const gridSpacing = 50.0;

    // Líneas verticales
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Líneas horizontales
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Círculos de distancia
    final radiusPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const distances = [100, 200, 300]; // En unidades relativas
    for (final distance in distances) {
      canvas.drawCircle(
        Offset(centerX, centerY),
        distance.toDouble(),
        radiusPaint,
      );
    }

    // Centro (usuario)
    canvas.drawCircle(
      Offset(centerX, centerY),
      8,
      Paint()..color = Colors.greenAccent,
    );
  }

  @override
  bool shouldRepaint(ARGridPainter oldDelegate) => false;
}

// Extensiones de helper
extension ARCameraViewHelper on _ARCameraViewState {
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

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
}
