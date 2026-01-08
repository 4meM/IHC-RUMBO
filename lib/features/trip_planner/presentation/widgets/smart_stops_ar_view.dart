import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as Math;
import '../../data/models/smart_bus_stop_model.dart';
import '../../data/services/compass_service.dart';

/// Widget que simula una vista de AR/Cámara para las paradas inteligentes
/// Con brújula rotatoria en tiempo real
class SmartStopsARView extends StatefulWidget {
  final List<SmartBusStopModel> stops;
  final LatLng userLocation;
  final VoidCallback onCloseAR;

  const SmartStopsARView({
    Key? key,
    required this.stops,
    required this.userLocation,
    required this.onCloseAR,
  }) : super(key: key);

  @override
  State<SmartStopsARView> createState() => _SmartStopsARViewState();
}

class _SmartStopsARViewState extends State<SmartStopsARView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late CompassService _compassService;
  double _deviceHeading = 0.0; // Heading actual del dispositivo (0-360)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Inicializar compass service
    _compassService = CompassService();
    _compassService.startListening();
    
    // Escuchar cambios de heading en tiempo real
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
    _pageController.dispose();
    _compassService.stopListening();
    _compassService.dispose();
    super.dispose();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo de AR simulado (gradiente azul cielo)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue[900]!,
                Colors.blue[700]!,
                Colors.cyan[300]!,
              ],
            ),
          ),
        ),

        // Centro: Brújula + Paraderos orbitando (Vista AR mejorada)
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Círculos de referencia AR
              ..._buildARCircles(),
              
              // Paraderos como puntos flotantes alrededor de la brújula
              ..._buildFloatingStops(),
              
              // Brújula en el centro
              _buildCompass(),
            ],
          ),
        ),

        // Información en la parte superior (compacta)
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paraderos: ${widget.stops.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Orientación: ${_deviceHeading.toStringAsFixed(0)}°',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Botón cerrar
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: widget.onCloseAR,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.black87),
            ),
          ),
        ),

        // Indicadores de página
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.stops.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index ? Colors.white : Colors.white54,
                ),
              ),
            ),
          ),
        ),

        // Botón para ver detalles (inferior)
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: _showDetailsModal,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black38)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ver detalles del paradero',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Dibuja círculos de referencia AR alrededor del centro
  List<Widget> _buildARCircles() {
    final sizes = [150.0, 250.0, 350.0];
    return sizes.map((size) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
      );
    }).toList();
  }

  /// Construye los paraderos como puntos flotantes alrededor de la brújula
  List<Widget> _buildFloatingStops() {
    final List<Widget> stops = [];
    final baseRadius = 180.0; // Radio de órbita de los paraderos

    for (int i = 0; i < widget.stops.length; i++) {
      final stop = widget.stops[i];
      
      // Ángulo del paradero
      final angle = (i * 120.0 * Math.pi / 180.0); // Distribuir espaciadamente
      
      // Calcular posición basada en el heading del dispositivo
      final adjustedAngle = angle - (_deviceHeading * Math.pi / 180.0);
      final dx = baseRadius * Math.cos(adjustedAngle);
      final dy = baseRadius * Math.sin(adjustedAngle);

      stops.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: GestureDetector(
            onTap: () => _selectStop(i),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == i ? Colors.green : Colors.orange[400],
                boxShadow: [
                  BoxShadow(
                    color: (_currentIndex == i ? Colors.green : Colors.orange).withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 22),
                  SizedBox(height: 2),
                  Text(
                    '${(i + 1)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return stops;
  }

  void _selectStop(int index) {
    setState(() => _currentIndex = index);
  }

  void _showDetailsModal() {
    final stop = widget.stops[_currentIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles del Paradero ${_currentIndex + 1}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildDetailRow('Distancia a caminar', _formatDistance(stop.walkingDistance)),
            _buildDetailRow('Tiempo en Bus', _formatTime(stop.estimatedTravelTime)),
            _buildDetailRow('Espera estimada', _formatTime(stop.estimatedWaitTime)),
            _buildDetailRow('Asientos disponibles', '${stop.estimatedAvailableSeats}'),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Seleccionar este Paradero',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  /// Construye la brújula mejorada en el centro
  Widget _buildCompass() {
    return Transform.rotate(
      angle: _deviceHeading * Math.pi / 180.0,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Brújula con direcciones
            CustomPaint(
              size: Size(150, 150),
              painter: CompassPainter(deviceHeading: _deviceHeading),
            ),
            // Aguja en el centro
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopARCard(SmartBusStopModel stop) {
    final bearing = CompassService.calculateBearing(widget.userLocation, stop.location);
    final relativeAngle = CompassService.getRelativeAngle(_deviceHeading, bearing);
    final distance = _calculateDistance(widget.userLocation, stop.location);
    final cardinalDirection = CompassService.getSimpleCardinalDirection(bearing);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Brújula rotatoria en tiempo real
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Brújula de fondo (no rota)
                CustomPaint(
                  size: Size(120, 120),
                  painter: CompassPainter(
                    deviceHeading: _deviceHeading,
                  ),
                ),
                
                // Indicador de dirección al paradero (flecha que apunta)
                Transform.rotate(
                  angle: relativeAngle * Math.pi / 180,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 4,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _getStopTypeColor(stop.type),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 0,
                        height: 0,
                        decoration: ShapeDecoration(
                          shape: StarBorder(
                            side: BorderSide(
                              color: _getStopTypeColor(stop.type),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStopTypeColor(stop.type),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          
          // Información del paradero
          Text(
            stop.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            stop.type.displayName,
            style: TextStyle(
              color: _getStopTypeColor(stop.type),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          
          // Información de dirección y distancia
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Text(
                  '${cardinalDirection}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Text(
                  _formatDistance(distance),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Text(
                  '${bearing.toStringAsFixed(0)}°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(SmartBusStopModel stop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Razón de recomendación
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStopTypeColor(stop.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStopTypeColor(stop.type).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: _getStopTypeColor(stop.type),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stop.reason,
                      style: TextStyle(
                        color: _getStopTypeColor(stop.type),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Grilla de información
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildInfoItem(
                  icon: Icons.directions_walk,
                  label: 'Caminar',
                  value: _formatDistance(stop.walkingDistance),
                  color: Colors.blue,
                ),
                _buildInfoItem(
                  icon: Icons.directions_bus,
                  label: 'En Bus',
                  value: _formatTime(stop.estimatedTravelTime),
                  color: Colors.orange,
                ),
                _buildInfoItem(
                  icon: Icons.schedule,
                  label: 'Espera',
                  value: _formatTime(stop.estimatedWaitTime),
                  color: Colors.purple,
                ),
                _buildInfoItem(
                  icon: Icons.event_seat,
                  label: 'Asientos',
                  value: '${stop.estimatedAvailableSeats}',
                  color: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Nivel de congestión
            Row(
              children: [
                Text(
                  'Nivel de Ocupación:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stop.crowdLevel,
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        stop.crowdLevel > 0.7
                            ? Colors.red
                            : stop.crowdLevel > 0.4
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${(stop.crowdLevel * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Botón de selección
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Paradero seleccionado: ${stop.name}'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(Icons.check_circle),
                label: Text('Seleccionar este Paradero'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStopTypeColor(stop.type),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStopTypeColor(SmartStopType type) {
    switch (type) {
      case SmartStopType.nearest:
        return Colors.blue;
      case SmartStopType.avoidTraffic:
        return Colors.orange;
      case SmartStopType.guaranteedSeats:
        return Colors.green;
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000;
    final dLat = (p2.latitude - p1.latitude) * 3.14159 / 180;
    final dLon = (p2.longitude - p1.longitude) * 3.14159 / 180;
    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(p1.latitude * 3.14159 / 180) *
            Math.cos(p2.latitude * 3.14159 / 180) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }
}

/// CustomPainter que dibuja una brújula rotatoria
class CompassPainter extends CustomPainter {
  final double deviceHeading;

  CompassPainter({required this.deviceHeading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dibujar círculo de fondo
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Dibujar borde del círculo
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Guardar el estado del canvas
    canvas.save();

    // Rotar según el heading del dispositivo
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-deviceHeading * Math.pi / 180); // Rotación negativa para que el mapa rote
    canvas.translate(-center.dx, -center.dy);

    // Dibujar líneas cardinales (N, E, S, W)
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // N (Norte) - arriba
    textPainter.text = TextSpan(
      text: 'N',
      style: TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - radius + 10),
    );

    // E (Este) - derecha
    textPainter.text = TextSpan(
      text: 'E',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx + radius - 20, center.dy - textPainter.height / 2),
    );

    // S (Sur) - abajo
    textPainter.text = TextSpan(
      text: 'S',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + radius - 20),
    );

    // W (Oeste) - izquierda
    textPainter.text = TextSpan(
      text: 'W',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - radius + 5, center.dy - textPainter.height / 2),
    );

    // Dibujar líneas de dirección cardinal
    // Línea N
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 20),
      Offset(center.dx, center.dy - radius / 2),
      paint,
    );

    // Dibujar pequeños círculos en intervalos de 45 grados
    final smallRadius = radius - 15;
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * Math.pi / 180;
      final x = center.dx + smallRadius * Math.sin(angle);
      final y = center.dy - smallRadius * Math.cos(angle);
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.fill,
      );
    }

    // Restaurar el estado del canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) {
    return oldDelegate.deviceHeading != deviceHeading;
  }
}
