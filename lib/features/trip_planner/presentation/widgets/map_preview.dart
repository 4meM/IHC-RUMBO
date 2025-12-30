import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/bus_route_model.dart';
import '../../data/services/geojson_parser_service.dart';
import 'route_navigation_controls.dart';

class MapPreview extends StatefulWidget {
  const MapPreview({super.key});

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

enum SelectionPhase { origin, destination, completed }

class _MapPreviewState extends State<MapPreview> {
  GoogleMapController? mapController;
  final LatLng _defaultCenter = const LatLng(-16.409, -71.537);
  
  LatLng? _currentPosition;
  LatLng? _originPosition;
  LatLng? _destinationPosition;
  
  bool _isLoading = true;
  String? _errorMessage;
  String? _mapStyle;
  
  SelectionPhase _phase = SelectionPhase.origin;
  
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  Set<Marker> _markers = {};
  
  List<Map<String, dynamic>> _originSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  bool _showOriginSuggestions = false;
  bool _showDestinationSuggestions = false;
  bool _isSelectingOrigin = false;
  bool _isSelectingDestination = false;
  
  final String _googleApiKey = 'AIzaSyABjCnncfqwu10vFn3BT7KWTLAewEgOl3I';
  
  // Rutas de buses
  final GeoJsonParserService _geoJsonService = GeoJsonParserService();
  List<RouteGroup> _routeGroups = [];
  int _currentRouteIndex = 0;
  bool _showRouteNavigation = false;
  Set<Polyline> _polylines = {};
  
  bool get _canContinue => 
    _originPosition != null && _destinationPosition != null;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeLocation();
    // No cargar todas las rutas al inicio, solo cuando se busque
    _originController.text = 'Tu Ubicación';
    
    _originController.addListener(() {
      final text = _originController.text;
      if (!_isSelectingOrigin && text.isNotEmpty && text != 'Tu Ubicación' && text != 'Ubicación seleccionada') {
        setState(() {
          _showOriginSuggestions = true;
        });
        _searchPlaces(text, isOrigin: true);
      } else if (text.isEmpty) {
        setState(() {
          _showOriginSuggestions = false;
          _originSuggestions.clear();
        });
      }
    });
    
    _destinationController.addListener(() {
      final text = _destinationController.text;
      if (!_isSelectingDestination && text.isNotEmpty && text != 'Ubicación seleccionada') {
        setState(() {
          _showDestinationSuggestions = true;
        });
        _searchPlaces(text, isOrigin: false);
      } else if (text.isEmpty) {
        setState(() {
          _showDestinationSuggestions = false;
          _destinationSuggestions.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style_minimal.json');
  }

  Future<void> _initializeLocation() async {
    try {
      print('🔍 Iniciando obtención de ubicación...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 GPS activado: $serviceEnabled');
      
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'GPS desactivado. Por favor activa la ubicación en tu dispositivo.';
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Permiso actual: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('🔐 Permiso después de solicitud: $permission');
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permisos de ubicación denegados permanentemente. Ve a Configuración para habilitarlos.';
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Permisos de ubicación denegados. La app necesita acceso a tu ubicación.';
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
        return;
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        print('✅ Obteniendo ubicación...');
        
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        print('📍 Ubicación obtenida: ${position.latitude}, ${position.longitude}');
        print('📍 Precisión: ${position.accuracy} metros');
        
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _originPosition = _currentPosition;
          _isLoading = false;
        });
        
        _updateMarkers();
        _moveToCurrentLocation();
      } else {
        setState(() {
          _errorMessage = 'Permisos insuficientes para obtener ubicación.';
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
      }
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      setState(() {
        _errorMessage = 'Error al obtener ubicación: ${e.toString()}';
        _isLoading = false;
      });
      _showErrorSnackBar(_errorMessage!);
    }
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null && mapController != null) {
      print('🗺️ Moviendo cámara a: $_currentPosition');
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    if (_originPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: _originPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Origen'),
        ),
      );
    }
    
    if (_destinationPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destino'),
        ),
      );
    }
  }

  void _onMapTap(LatLng position) {
    if (_phase == SelectionPhase.origin) {
      setState(() {
        _originPosition = position;
        _originController.text = 'Ubicación seleccionada';
        _phase = SelectionPhase.destination;
      });
      _updateMarkers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ahora toca el destino en el mapa'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (_phase == SelectionPhase.destination) {
      setState(() {
        _destinationPosition = position;
        _destinationController.text = 'Ubicación seleccionada';
      });
      _updateMarkers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Listo! Ahora puedes continuar'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _onOriginFieldTap() {
    setState(() {
      _phase = SelectionPhase.origin;
      _originPosition = null;
      _destinationPosition = null;
      _originController.text = 'Tu Ubicación';
      _destinationController.text = '';
    });
    _updateMarkers();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toca el mapa para seleccionar origen'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _onDestinationFieldTap() {
    if (_originPosition == null) return;
    
    setState(() {
      _phase = SelectionPhase.destination;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toca el mapa para seleccionar destino'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _onContinue() async {
    if (!_canContinue) return;
    
    if (_originPosition == null || _destinationPosition == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Buscar las mejores rutas
    final bestRoutes = await _geoJsonService.findBestRoutes(
      origin: _originPosition!,
      destination: _destinationPosition!,
      maxWalkingDistanceMeters: 500,
    );
    
    if (bestRoutes.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se encontraron rutas que conecten origen y destino.\nIntenta aumentar la distancia de caminata.';
      });
      return;
    }
    
    setState(() {
      _routeGroups = bestRoutes.map((r) => r.route).toList();
      _phase = SelectionPhase.completed;
      _showRouteNavigation = true;
      _currentRouteIndex = 0;
      _isLoading = false;
    });
    
    print('🎯 Mostrando ${_routeGroups.length} rutas óptimas');
    _showCurrentRoute();
  }
  
  void _showCurrentRoute() {
    if (_routeGroups.isEmpty) return;
    
    final group = _routeGroups[_currentRouteIndex];
    setState(() {
      _polylines = group.toPolylines();
    });
    
    // Centrar mapa en la primera ruta disponible
    final route = group.outbound ?? group.return_;
    if (route != null && route.coordinates.isNotEmpty && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(route.coordinates.first),
      );
    }
  }
  
  void _nextRoute() {
    setState(() {
      // Comportamiento circular: después del último vuelve al primero
      _currentRouteIndex = (_currentRouteIndex + 1) % _routeGroups.length;
    });
    _showCurrentRoute();
  }
  
  void _previousRoute() {
    if (_currentRouteIndex > 0) {
      setState(() {
        _currentRouteIndex--;
      });
      _showCurrentRoute();
    }
  }
  
  void _closeRouteNavigation() {
    setState(() {
      _showRouteNavigation = false;
      _polylines.clear();
    });
  }

  Future<void> _searchPlaces(String query, {required bool isOrigin}) async {
    if (query.length < 3) {
      setState(() {
        if (isOrigin) {
          _showOriginSuggestions = false;
        } else {
          _showDestinationSuggestions = false;
        }
      });
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleApiKey&location=-16.409,-71.537&radius=50000&language=es&components=country:pe',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            if (isOrigin) {
              _originSuggestions = List<Map<String, dynamic>>.from(
                data['predictions'].map((p) => {
                  'description': p['description'],
                  'place_id': p['place_id'],
                }),
              );
              _showOriginSuggestions = true;
            } else {
              _destinationSuggestions = List<Map<String, dynamic>>.from(
                data['predictions'].map((p) => {
                  'description': p['description'],
                  'place_id': p['place_id'],
                }),
              );
              _showDestinationSuggestions = true;
            }
          });
        }
      }
    } catch (e) {
      print('Error buscando lugares: $e');
    }
  }

  Future<void> _selectPlace(String placeId, {required bool isOrigin}) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey&language=es',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          final name = data['result']['name'];

          setState(() {
            if (isOrigin) {
              _isSelectingOrigin = true;
              _originPosition = LatLng(lat, lng);
              _originController.text = name;
              _showOriginSuggestions = false;
              _originSuggestions.clear();
            } else {
              _isSelectingDestination = true;
              _destinationPosition = LatLng(lat, lng);
              _destinationController.text = name;
              _showDestinationSuggestions = false;
              _destinationSuggestions.clear();
              // Cerrar teclado cuando se completa el destino
              FocusScope.of(context).unfocus();
            }
          });

          // Resetear flags después de un breve delay
          Future.delayed(const Duration(milliseconds: 100), () {
            setState(() {
              if (isOrigin) {
                _isSelectingOrigin = false;
              } else {
                _isSelectingDestination = false;
              }
            });
          });

          _updateMarkers();
          
          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLng(LatLng(lat, lng)),
            );
          }
        }
      }
    } catch (e) {
      print('Error obteniendo detalles del lugar: $e');
    }
  }


  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool enabled = true,
    bool isActive = false,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextField(
                      controller: controller,
                      enabled: enabled,
                      readOnly: false,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: enabled 
                          ? 'Escribe o selecciona en el mapa'
                          : 'Selecciona origen primero',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                color: AppColors.primary,
                onPressed: enabled ? onTap : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(List<Map<String, dynamic>> suggestions, {required bool isOrigin}) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on, color: Colors.grey, size: 20),
            title: Text(
              suggestion['description'],
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {
              _selectPlace(suggestion['place_id'], isOrigin: isOrigin);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Obteniendo tu ubicación...'),
          ],
        ),
      );
    }
    
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) async {
            mapController = controller;
            if (_mapStyle != null) {
              await controller.setMapStyle(_mapStyle);
            }
            _moveToCurrentLocation();
          },
          onTap: _onMapTap,
          initialCameraPosition: CameraPosition(
            target: _currentPosition ?? _defaultCenter,
            zoom: 15.0,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          buildingsEnabled: false,
          trafficEnabled: false,
        ),
        
        Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: Column(
            children: [
              _buildLocationField(
                controller: _originController,
                label: 'De:',
                icon: Icons.location_on,
                iconColor: AppColors.success,
                onTap: _onOriginFieldTap,
                isActive: _phase == SelectionPhase.origin,
              ),
              if (_showOriginSuggestions && _originSuggestions.isNotEmpty)
                _buildSuggestionsList(_originSuggestions, isOrigin: true),
              const SizedBox(height: 12),
              _buildLocationField(
                controller: _destinationController,
                label: 'Hasta:',
                icon: Icons.location_on,
                iconColor: AppColors.error,
                onTap: _onDestinationFieldTap,
                enabled: _originPosition != null,
                isActive: _phase == SelectionPhase.destination,
              ),
              if (_showDestinationSuggestions && _destinationSuggestions.isNotEmpty)
                _buildSuggestionsList(_destinationSuggestions, isOrigin: false),
            ],
          ),
        ),
        
        if (_canContinue && !_showRouteNavigation)
          Positioned(
            bottom: 120,
            right: 24,
            child: FloatingActionButton(
              onPressed: _onContinue,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        
        if (_showRouteNavigation && _routeGroups.isNotEmpty)
          Positioned(
            bottom: 200,
            left: 24,
            child: RouteNavigationControls(
              currentGroup: _routeGroups.isNotEmpty ? _routeGroups[_currentRouteIndex] : null,
              currentIndex: _currentRouteIndex,
              totalRoutes: _routeGroups.length,
              onPrevious: _previousRoute,
              onNext: _nextRoute,
              onClose: _closeRouteNavigation,
            ),
          ),
        
        if (_errorMessage != null)
          Positioned(
            top: 180,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
