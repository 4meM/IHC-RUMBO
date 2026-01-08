import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as Math;
import '../../data/models/smart_bus_stop_model.dart';
import '../../data/services/compass_service.dart';

/// Widget que usa la cámara real para AR de paradas inteligentes
/// Muestra los paraderos sobreimpuestos en la vista de cámara en tiempo real
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;
  late CompassService _compassService;
  double _deviceHeading = 0.0; // Heading actual del dispositivo (0-360)
  
  // Cámara
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraInitialized = false;
  
  // Geolocalización
  late StreamSubscription<Position> _positionStream;
  LatLng? _currentPosition;
  
  // Estado del AR
  Map<int, StopARData> _stopsARData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: 0);
    
    // Inicializar compass service
    _compassService = CompassService();
    _compassService.startListening();
    _compassService.headingStream.listen((heading) {
      if (mounted) {
        setState(() {
          _deviceHeading = heading;
          _updateStopsARData();
        });
      }
    });
    
    // Inicializar cámara
    _initializeCamera();
    
    // Inicializar geolocalización
    _initializeGeolocation();
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _cameraInitialized = true);
        }
      }
    } catch (e) {
      print('Error al inicializar cámara: $e');
    }
  }
  
  void _initializeGeolocation() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualizar cada 5 metros
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _updateStopsARData();
        });
      }
    });
  }
  
  void _updateStopsARData() {
    if (_currentPosition == null) return;
    
    _stopsARData.clear();
    for (int i = 0; i < widget.stops.length; i++) {
      final stop = widget.stops[i];
      final distance = _calculateDistance(_currentPosition!, stop.location);
      final bearing = CompassService.calculateBearing(_currentPosition!, stop.location);
      final relativeAngle = bearing - _deviceHeading;
      
      _stopsARData[i] = StopARData(
        distance: distance,
        bearing: bearing,
        relativeAngle: relativeAngle,
        screenX: _calculateScreenX(bearing),
        screenY: _calculateScreenY(distance),
      );
    }
  }
  
  double _calculateScreenX(double bearing) {
    // Convertir bearing a ángulo de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final relativeAngle = bearing - _deviceHeading;
    // Normalizar ángulo: -90 a 90 grados en pantalla
    final normalizedAngle = relativeAngle % 360;
    final screenAngle = (normalizedAngle - 180) / 180 * (screenWidth / 2);
    return screenWidth / 2 + screenAngle;
  }
  
  double _calculateScreenY(double distance) {
    // Los paraderos más cercanos aparecen más arriba
    // Máximo: 1000m, aparece en bottom
    // Mínimo: 0m, aparece en top
    final screenHeight = MediaQuery.of(context).size.height;
    final normalizedDistance = Math.min(distance / 1000.0, 1.0);
    return screenHeight * (1.0 - normalizedDistance * 0.7); // 0.7 del alto disponible
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _compassService.stopListening();
    _compassService.dispose();
    _cameraController?.dispose();
    _positionStream.cancel();
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
        // Cámara en vivo como fondo
        if (_cameraInitialized && _cameraController != null)
          CameraPreview(_cameraController!)
        else
          Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // Capa de AR con paraderos sobreimpuestos
        if (_currentPosition != null)
          Positioned.fill(
            child: Stack(
              children: [
                // Paraderos AR
                ..._buildARStopsOverlay(),
                
                // Brújula en la esquina superior izquierda
                Positioned(
                  top: 80,
                  left: 20,
                  child: _buildCompassWidget(),
                ),
                
                // Indicador de información de ubicación actual
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brújula: ${_deviceHeading.toStringAsFixed(0)}°',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pitch: 79.5°',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Roll: -3.6°',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Center(
            child: Text(
              'Obteniendo ubicación...',
              style: TextStyle(color: Colors.white),
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

        // Panel inferior con detalles del paradero más cercano
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildClosestStopPanel(),
        ),
      ],
    );
  }

  /// Construye los paraderos como overlays AR en la pantalla de cámara
  List<Widget> _buildARStopsOverlay() {
    final List<Widget> stopsWidgets = [];
    
    for (int i = 0; i < widget.stops.length; i++) {
      final stop = widget.stops[i];
      final arData = _stopsARData[i];
      
      if (arData == null) continue;
      
      // Validar que el paradero esté en el rango visible (±130 grados para más cobertura)
      if (arData.relativeAngle.abs() > 130) continue;
      
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      
      // Calcular posición más precisa (rango expandido)
      final offsetX = (arData.relativeAngle / 130) * (screenWidth / 2);
      final centerX = screenWidth / 2 + offsetX;
      
      // Paraderos más cercanos aparecen más arriba
      final normalizedDistance = Math.min(arData.distance / 1000.0, 1.0);
      final centerY = screenHeight * (0.2 + normalizedDistance * 0.6);
      
      // Tamaño inversamente proporcional a la distancia
      final size = Math.max(40.0, 120.0 - (normalizedDistance * 50));
      
      stopsWidgets.add(
        Positioned(
          left: centerX - size / 2,
          top: centerY - size / 2,
          child: GestureDetector(
            onTap: () => _selectStop(i),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == i ? Colors.green : Colors.orange[400],
                boxShadow: [
                  BoxShadow(
                    color: (_currentIndex == i ? Colors.green : Colors.orange).withOpacity(0.7),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: Math.max(18.0, size * 0.4),
                  ),
                  SizedBox(height: size > 60 ? 4 : 2),
                  Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Math.max(12.0, size * 0.3),
                    ),
                  ),
                  if (size > 60)
                    Text(
                      _formatDistance(arData.distance),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return stopsWidgets;
  }

  /// Construye el widget de la brújula mejorada con aguja al paradero más cercano
  Widget _buildCompassWidget() {
    // Encontrar el paradero más cercano para la aguja
    int closestIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < widget.stops.length; i++) {
      final arData = _stopsARData[i];
      if (arData != null && arData.distance < minDistance) {
        minDistance = arData.distance;
        closestIndex = i;
      }
    }
    
    final closestData = _stopsARData[closestIndex];
    final closestBearing = closestData?.bearing ?? 0.0;
    
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.cyan,
          width: 3,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Brújula pintada
          CustomPaint(
            size: Size(110, 110),
            painter: CompassPainter(deviceHeading: _deviceHeading),
          ),
          // Aguja roja que apunta al paradero más cercano
          if (closestData != null)
            Transform.rotate(
              angle: closestBearing * Math.pi / 180.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Línea hacia arriba
                  Container(
                    width: 4,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.9),
                          blurRadius: 4,
                        )
                      ],
                    ),
                  ),
                  // Punta de flecha
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.9),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Punto central
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Panel que muestra el paradero más cercano
  Widget _buildClosestStopPanel() {
    if (_stopsARData.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Encontrar el paradero más cercano
    int closestIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < widget.stops.length; i++) {
      final arData = _stopsARData[i];
      if (arData != null && arData.distance < minDistance) {
        minDistance = arData.distance;
        closestIndex = i;
      }
    }
    
    final closestStop = widget.stops[closestIndex];
    final closestData = _stopsARData[closestIndex]!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: _getStopTypeColor(closestStop.type),
            width: 3,
          ),
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStopTypeColor(closestStop.type),
                ),
                child: Icon(Icons.location_on, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡PARADERO MUY CERCANO!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      closestStop.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPanelInfo('Distancia', _formatDistance(closestData.distance)),
              _buildPanelInfo('Rutas', '${closestStop.routes.length}'),
              _buildPanelInfo('Ocupación', '${(closestStop.crowdLevel * 100).toStringAsFixed(0)}%'),
              _buildPanelInfo('Asientos', '${closestStop.estimatedAvailableSeats}'),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDetailsModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStopTypeColor(closestStop.type),
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ver detalles',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
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

/// Datos de AR para un paradero individual
class StopARData {
  final double distance;
  final double bearing;
  final double relativeAngle;
  final double screenX;
  final double screenY;

  StopARData({
    required this.distance,
    required this.bearing,
    required this.relativeAngle,
    required this.screenX,
    required this.screenY,
  });
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
