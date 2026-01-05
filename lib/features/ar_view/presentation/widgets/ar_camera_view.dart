import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/ar_bus_marker.dart';
import '../../domain/entities/ar_user_location.dart';

class ARCameraView extends StatefulWidget {
  final ARUserLocation? userLocation;
  final List<ARBusMarker> nearbyBuses;

  const ARCameraView({
    Key? key,
    required this.userLocation,
    required this.nearbyBuses,
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
