import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../data/models/smart_bus_stop_model.dart';
import '../../data/helpers/walking_route_helper.dart';
import '../../data/helpers/streetview_sync_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialSelectedIndex;
    _initializeWebView();
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
    });
    // Solo actualiza el índice, no navega
    widget.onSelectedIndexChanged(_currentIndex);
    _initializeWebView();
    _adjustMapBounds();
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

  /// Mapa de Google con polyline de ruta caminando
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

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: userPos,
        zoom: 15,
      ),
      onMapCreated: _onMapCreated,
      polylines: {polyline},
      markers: {originMarker, stopMarker},
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
