import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import '../../data/models/smart_bus_stop_model.dart';
import '../../data/helpers/walking_route_helper.dart';
import '../../data/helpers/streetview_sync_helper.dart';
import '../../data/services/compass_service.dart';

/// Widget que muestra mapa con ruta caminando + Street View del paradero
/// Responsabilidad: Vista combinada de navegación hacia paraderos
class SmartStopsARView extends StatefulWidget {
  final List<SmartBusStopModel> stops;
  final LatLng userLocation;
  final int initialSelectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final VoidCallback onCloseAR;

  const SmartStopsARView({
    Key? key,
    required this.stops,
    required this.userLocation,
    required this.initialSelectedIndex,
    required this.onSelectedIndexChanged,
    required this.onCloseAR,
  }) : super(key: key);

  @override
  State<SmartStopsARView> createState() => _SmartStopsARViewState();
}

class _SmartStopsARViewState extends State<SmartStopsARView> {
  late int _currentIndex;
  GoogleMapController? _mapController;
  WebViewController? _webViewController;
  LatLng? _streetViewPosition;
  bool _isMapReady = false;
  
  // Compass
  late CompassService _compassService;
  double _deviceHeading = 0.0;
  double _bearingToParadero = 0.0; // Dirección hacia el paradero
  late StreamSubscription<double> _headingSubscription;
  
  // Cache para los marcadores
  late Set<Marker> _cachedOtherMarkers;
  
  // Índice para el carrusel de buses
  int _busImageIndex = 0;
  final List<String> _busImages = [
    'assets/images/bus_image.png',
    'assets/images/bus2_image.png',
    'assets/images/bus3_image.png',
    'assets/images/bus4_image.png',
    'assets/images/bus5_image.png',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialSelectedIndex;
    _initializeWebView();
    _buildCachedMarkers();
    
    // Inicializar brújula (sin throttle, usaremos un simple check en el listener)
    _compassService = CompassService();
    _compassService.startListening();
    _updateBearingToParadero(); // Calcular bearing inicial
    _headingSubscription = _compassService.headingStream.listen((heading) {
      if (mounted && (_deviceHeading - heading).abs() > 1) {
        // Solo actualizar si el cambio es mayor a 1 grado
        setState(() {
          _deviceHeading = heading;
        });
      }
    });
  }
  
  /// Construye los marcadores en caché
  void _buildCachedMarkers() {
    _cachedOtherMarkers = {};
    for (int i = 0; i < widget.stops.length; i++) {
      if (i != _currentIndex) {
        final stop = widget.stops[i];
        _cachedOtherMarkers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: stop.location,
            infoWindow: InfoWindow(title: 'Paradero ${i + 1}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            onTap: () => _navigateToStop(i),
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _headingSubscription.cancel();
    _compassService.stopListening();
    _compassService.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Sincroniza el índice actual con el padre y permite el pop normal.
        try {
          widget.onSelectedIndexChanged(_currentIndex);
        } catch (_) {}
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildBusCarousel(),
            _buildWalkingMapSection(),
            _buildStreetViewSection(),
          ],
        ),
      ),
    );
  }

  /// Construye el AppBar con navegación entre paraderos
  AppBar _buildAppBar() {
    final currentStop = widget.stops[_currentIndex];
    
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          try {
            widget.onSelectedIndexChanged(_currentIndex);
          } catch (_) {}
          try {
            widget.onCloseAR();
          } catch (_) {}
        },
      ),
      title: Text(
        currentStop.type.toString().split('.').last,
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: Colors.blue[700],
      actions: _buildNavigationActions(),
    );
  }

  /// Botones de navegación entre paraderos
  List<Widget> _buildNavigationActions() {
    return [
      if (_currentIndex > 0)
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => _navigateToStop(_currentIndex - 1),
        ),
      Text(
        '${_currentIndex + 1}/${widget.stops.length}',
        style: const TextStyle(fontSize: 14),
      ),
      if (_currentIndex < widget.stops.length - 1)
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => _navigateToStop(_currentIndex + 1),
        ),
    ];
  }

  /// Navega a otro paradero
  void _navigateToStop(int index) {
    setState(() {
      _currentIndex = index;
      _isMapReady = false;
      _buildCachedMarkers(); // Reconstruir marcadores al cambiar de paradero
      _updateBearingToParadero(); // Actualizar bearing al nuevo paradero
    });
    // Solo actualiza el índice, no navega
    widget.onSelectedIndexChanged(_currentIndex);
    _initializeWebView();
    _adjustMapBounds();
  }
  
  /// Calcula el bearing (dirección) hacia el paradero seleccionado
  void _updateBearingToParadero() {
    final currentStop = widget.stops[_currentIndex];
    _bearingToParadero = _calculateBearing(
      widget.userLocation,
      currentStop.location,
    );
  }
  
  /// Calcula el bearing entre dos puntos (0-360 grados)
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  /// Inicializa el WebView con Street View
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterPostMessage',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = message.message;
            final decoded = data != null ? data : '{}';
            final pos = decoded.isNotEmpty ? decoded : '{}';
            final map = pos is String ? pos : '{}';
            final json = map is String ? map : '{}';
            final parsed = jsonDecode(json);
            if (parsed is Map && parsed['lat'] != null && parsed['lng'] != null) {
              setState(() {
                _streetViewPosition = LatLng(parsed['lat'], parsed['lng']);
              });
            }
          } catch (_) {}
        },
      )
      ..loadHtmlString(_buildStreetViewHtml());
  }

  /// Sección superior: Mapa con ruta caminando (40% altura)
  Widget _buildWalkingMapSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        children: [
          _buildMapHeader(),
          Expanded(child: _buildGoogleMap()),
        ],
      ),
    );
  }

  /// Sección de carrusel de buses con imágenes reales
  Widget _buildBusCarousel() {
    final currentStop = widget.stops[_currentIndex];
    final distance = _calculateDistance(widget.userLocation, currentStop.location);
    
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Nombre de la ruta
          Text(
            'Ruta ${widget.stops[_currentIndex].type.toString().split('.').last}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Carrusel de imágenes de buses
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _busImageIndex = (_busImageIndex - 1 + _busImages.length) % _busImages.length;
                  });
                },
                icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
              ),
              SizedBox(
                width: 180,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    _busImages[_busImageIndex],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _busImageIndex = (_busImageIndex + 1) % _busImages.length;
                  });
                },
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Información de distancia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_walk, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${distance.toStringAsFixed(0)}m',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Bus ${_busImageIndex + 1}/${_busImages.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Header del mapa con distancia
  Widget _buildMapHeader() {
    final currentStop = widget.stops[_currentIndex];
    final distance = _calculateDistance(widget.userLocation, currentStop.location);
    
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.directions_walk, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            'Ruta a pie: ${distance.toStringAsFixed(0)}m',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula la distancia entre dos puntos
  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000; // metros
    final dLat = (to.latitude - from.latitude) * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(from.latitude * math.pi / 180) *
        math.cos(to.latitude * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Mapa de Google con polyline de ruta caminando (optimizado)
  Widget _buildGoogleMap() {
    final currentStop = widget.stops[_currentIndex];
    final userPos = _streetViewPosition ?? widget.userLocation;
    final route = StreetViewSyncHelper.updateWalkingRoute(
      newPosition: userPos,
      stopLocation: currentStop.location,
    );

    final polyline = WalkingRouteHelper.createWalkingPolyline(
      polylineId: 'walking_route',
      points: route,
    );

    final originMarker = WalkingRouteHelper.createOriginMarker(
      position: userPos,
    );

    final stopMarker = WalkingRouteHelper.createStopMarker(
      position: currentStop.location,
      stopName: currentStop.type.toString().split('.').last,
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: userPos,
            zoom: 15,
          ),
          onMapCreated: _onMapCreated,
          polylines: {polyline},
          markers: {originMarker, stopMarker, ..._cachedOtherMarkers},
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        // Brújula flotante en la esquina superior izquierda
        Positioned(
          top: 12,
          left: 12,
          child: _buildCompassWidget(),
        ),
      ],
    );
  }
  
  /// Widget de brújula flotante optimizada
  Widget _buildCompassWidget() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.95),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.cyan,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Brújula con direcciones (optimizada con RepaintBoundary)
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(90, 90),
              painter: _CompassPainter(
                heading: _deviceHeading,
                bearingToParadero: _bearingToParadero,
              ),
              willChange: true,
            ),
          ),
          // Punto central
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.6),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Callback cuando el mapa está listo
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() => _isMapReady = true);
    _adjustMapBounds();
  }

  /// Ajusta el mapa para mostrar ambos puntos
  void _adjustMapBounds() {
    if (_mapController == null || !_isMapReady) return;

    final currentStop = widget.stops[_currentIndex];
    final bounds = WalkingRouteHelper.calculateBounds(
      origin: widget.userLocation,
      destination: currentStop.location,
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  /// Sección inferior: Street View (60% altura)
  Widget _buildStreetViewSection() {
    return Expanded(
      child: Column(
        children: [
          _buildStreetViewHeader(),
          Expanded(child: _buildStreetView()),
        ],
      ),
    );
  }

  /// Header de Street View
  Widget _buildStreetViewHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.cyan[50],
      child: Row(
        children: [
          Icon(Icons.streetview, color: Colors.cyan[700]),
          const SizedBox(width: 8),
          const Text(
            'Vista de la calle desde tu ubicación',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// WebView con Google Street View
  Widget _buildStreetView() {
    if (_webViewController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return WebViewWidget(controller: _webViewController!);
  }

  /// Genera el HTML para Street View apuntando al paradero
  String _buildStreetViewHtml() {
    final currentStop = widget.stops[_currentIndex];
    final userLat = widget.userLocation.latitude;
    final userLng = widget.userLocation.longitude;
    final stopLat = currentStop.location.latitude;
    final stopLng = currentStop.location.longitude;

    // Calcular el heading (dirección) hacia el paradero
    final heading = _calculateHeading(
      widget.userLocation,
      currentStop.location,
    );

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
      <style>
        html, body {
          height: 100%;
          margin: 0;
          padding: 0;
        }
        #map {
          height: 100%;
        }
      </style>
    </head>
    <body>
      <div id="map"></div>
      <script>
        function initMap() {
          const userLocation = { lat: $userLat, lng: $userLng };
          const stopLocation = { lat: $stopLat, lng: $stopLng };
          
          const panorama = new google.maps.StreetViewPanorama(
            document.getElementById('map'),
            {
              position: userLocation,
              pov: {
                heading: $heading,
                pitch: 0
              },
              zoom: 1,
              addressControl: false,
              linksControl: true,
              panControl: true,
              enableCloseButton: false,
              fullscreenControl: false
            }
          );
          // Canal JS: enviar posición a Flutter cuando el usuario se mueva
          panorama.addListener('position_changed', function() {
            var pos = panorama.getPosition();
            if (window.FlutterPostMessage) {
              window.FlutterPostMessage.postMessage(JSON.stringify({lat: pos.lat(), lng: pos.lng()}));
            }
          });
        }
      </script>
      <script async defer
        src="https://maps.googleapis.com/maps/api/js?key=AIzaSyABjCnncfqwu10vFn3BT7KWTLAewEgOl3I&callback=initMap">
      </script>
    </body>
    </html>
    ''';
  }

  /// Calcula el heading (dirección en grados) de origen a destino
  double _calculateHeading(LatLng from, LatLng to) {
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    
    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }
}

/// CustomPainter para dibujar la brújula (optimizado)
class _CompassPainter extends CustomPainter {
  final double heading;
  final double bearingToParadero; // Bearing hacia el destino
  
  // Caché de paint objects
  late final Paint _redPaint = Paint()
    ..color = Colors.red
    ..strokeWidth = 2;
  
  late final Paint _greenPaint = Paint()
    ..color = Colors.green
    ..strokeWidth = 3;
  
  late final Paint _whitePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  _CompassPainter({
    required this.heading,
    required this.bearingToParadero,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Dibujar círculo blanco de fondo
    canvas.drawCircle(center, radius - 2, _whitePaint);
    
    // Guardar estado del canvas
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);
    
    // Dibujar línea N (roja)
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 8),
      Offset(center.dx, center.dy - radius / 2),
      _redPaint,
    );
    
    // Dibujar texto N
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - radius + 12),
    );
    
    canvas.restore();
    
    // Dibujar puntos cardinales
    _drawCardinalPoint(canvas, center, radius, 'E', 0);
    _drawCardinalPoint(canvas, center, radius, 'S', 180);
    _drawCardinalPoint(canvas, center, radius, 'W', 270);
    
    // Dibujar línea verde apuntando al paradero (sin rotación, es absoluta)
    final rad = bearingToParadero * math.pi / 180;
    final endX = center.dx + (radius - 12) * math.sin(rad);
    final endY = center.dy - (radius - 12) * math.cos(rad);
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(endX, endY),
      _greenPaint,
    );
    
    // Dibujar círculo pequeño en el destino
    canvas.drawCircle(Offset(endX, endY), 4, _greenPaint);
  }
  
  void _drawCardinalPoint(Canvas canvas, Offset center, double radius, String label, double angle) {
    final rad = angle * math.pi / 180;
    final x = center.dx + (radius - 8) * math.sin(rad);
    final y = center.dy - (radius - 8) * math.cos(rad);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }
  
  @override
  bool shouldRepaint(_CompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.bearingToParadero != bearingToParadero;
  }
}
