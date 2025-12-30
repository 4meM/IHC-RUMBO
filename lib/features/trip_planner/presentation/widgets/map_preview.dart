import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPreview extends StatefulWidget {
  const MapPreview({super.key});

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  GoogleMapController? mapController;
  final LatLng _defaultCenter = const LatLng(-16.409, -71.537);
  
  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeLocation();
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
          _isLoading = false;
        });
        
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
          initialCameraPosition: CameraPosition(
            target: _currentPosition ?? _defaultCenter,
            zoom: 15.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: false,
          buildingsEnabled: false,
          trafficEnabled: false,
        ),
        if (_errorMessage != null)
          Positioned(
            top: 16,
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
