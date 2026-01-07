import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/geolocation_helper.dart';
import '../../../../core/services/places_api_helper.dart';
import '../../../../core/utils/map_marker_factory.dart';
import '../../../../core/utils/map_polyline_factory.dart';
import '../../../../core/utils/geometry_utils.dart';
import '../../data/managers/route_search_manager.dart';

/// Estados posibles durante la selección
enum MapSelectionPhase { origin, destination, completed }

/// Controller: Manejar todo el estado y lógica del mapa
/// Propósito único: Coordinar estado, búsquedas y actualizaciones del mapa
class MapController extends ChangeNotifier {
  // Controllers de texto
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  
  // Estado del mapa
  GoogleMapController? _mapController;
  MapSelectionPhase phase = MapSelectionPhase.completed;
  
  // Posiciones
  LatLng? currentPosition;
  LatLng? originPosition;
  LatLng? destinationPosition;
  
  // UI State
  bool isLoading = true;
  String? errorMessage;
  
  // Búsqueda de lugares
  List<Map<String, dynamic>> originSuggestions = [];
  List<Map<String, dynamic>> destinationSuggestions = [];
  bool showOriginSuggestions = false;
  bool showDestinationSuggestions = false;
  bool isSelectSuggestionOrigin = false;
  bool isSelectSuggestionDestination = false;
  
  // Marcadores y rutas
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  
  // Manager de rutas
  final RouteSearchManager _routeManager = RouteSearchManager();
  List<RouteSearchResult> searchResults = [];
  int currentRouteIndex = 0;
  bool showRouteInfo = false;
  
  // Getters
  bool get canSearchRoutes => originPosition != null && destinationPosition != null;
  bool get hasRouteResults => searchResults.isNotEmpty;
  RouteSearchResult? get currentRoute => 
      hasRouteResults ? searchResults[currentRouteIndex] : null;
  
  /// Inicializar: obtener ubicación y cargar rutas
  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    
    // Obtener ubicación
    final result = await getLocationSafely();
    
    if (result.error != null) {
      errorMessage = result.error;
      isLoading = false;
      notifyListeners();
      return;
    }
    
    currentPosition = result.location;
    originPosition = currentPosition;
    originController.text = '';
    
    // Cargar rutas de buses
    await _routeManager.loadRoutesFromGeoJson('assets/data-buses/export.geojson');
    
    _updateMarkers();
    isLoading = false;
    notifyListeners();
    _moveToCurrentLocation();
  }
  
  /// Configurar el controller del mapa de Google
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    _moveToCurrentLocation();
  }
  
  /// Mover cámara a ubicación actual
  void _moveToCurrentLocation() {
    if (currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentPosition!, zoom: 17.0),
        ),
      );
    }
  }
  
  /// Actualizar marcadores en el mapa
  void _updateMarkers() {
    markers.clear();
    
    if (originPosition != null) {
      markers.add(createOriginMarker(originPosition!));
    }
    
    if (destinationPosition != null) {
      markers.add(createDestinationMarker(destinationPosition!));
    }
    
    // Agregar marcadores de pickup/dropoff si hay ruta activa
    if (currentRoute != null) {
      markers.add(createPickupMarker(currentRoute!.pickupPoint));
      markers.add(createDropoffMarker(currentRoute!.dropoffPoint));
    }
    
    notifyListeners();
  }
  
  /// Tap en el mapa para seleccionar origen o destino
  Future<void> onMapTap(LatLng position) async {
    if (phase == MapSelectionPhase.origin) {
      originPosition = position;
      phase = MapSelectionPhase.completed;
      notifyListeners(); // Notificar INMEDIATAMENTE para cancelar el borde de color
      
      isSelectSuggestionOrigin = true;
      originController.text = 'Obteniendo dirección...';
      _updateMarkers();
      
      final address = await latLngToAddress(position);
      originController.text = address;
      isSelectSuggestionOrigin = false;
      originSuggestions = [];
      showOriginSuggestions = false;
      notifyListeners();
    } else if (phase == MapSelectionPhase.destination) {
      destinationPosition = position;
      phase = MapSelectionPhase.completed;
      notifyListeners(); // Notificar INMEDIATAMENTE para cancelar el borde de color
      
      isSelectSuggestionDestination = true;
      destinationController.text = 'Obteniendo dirección...';
      _updateMarkers();
      
      final address = await latLngToAddress(position);
      destinationController.text = address;
      isSelectSuggestionDestination = false;
      destinationSuggestions = [];
      showDestinationSuggestions = false;
      notifyListeners();
    }
  }

  /// Activar modo de selección de origen en el mapa
  void enableOriginSelection() {
    // Cancelar modo selección de destino si estaba activo
    if (phase == MapSelectionPhase.destination) {
      phase = MapSelectionPhase.completed;
    }
    
    phase = MapSelectionPhase.origin;
    originController.clear();
    originPosition = null;
    
    // Ocultar sugerencias de destino
    showDestinationSuggestions = false;
    destinationSuggestions = [];
    
    _updateMarkers();
    notifyListeners();
  }

  /// Activar modo de selección de destino en el mapa
  void enableDestinationSelection() {
    // Cancelar modo selección de origen si estaba activo
    if (phase == MapSelectionPhase.origin) {
      phase = MapSelectionPhase.completed;
    }
    
    phase = MapSelectionPhase.destination;
    destinationController.clear();
    destinationPosition = null;
    
    // Ocultar sugerencias de origen
    showOriginSuggestions = false;
    originSuggestions = [];
    
    _updateMarkers();
    notifyListeners();
  }
  
  /// Buscar lugares mientras el usuario escribe
  Future<void> searchOriginPlaces(String query) async {
    if (query.isEmpty || query == 'Tu Ubicación' || query == 'Ubicación seleccionada') {
      originSuggestions = [];
      showOriginSuggestions = false;
      notifyListeners();
      return;
    }
    
    final results = await searchPlacesInArequipa(query);
    originSuggestions = results;
    showOriginSuggestions = results.isNotEmpty;
    notifyListeners();
  }
  
  Future<void> searchDestinationPlaces(String query) async {
    if (query.isEmpty || query == 'Ubicación seleccionada') {
      destinationSuggestions = [];
      showDestinationSuggestions = false;
      notifyListeners();
      return;
    }
    
    final results = await searchPlacesInArequipa(query);
    destinationSuggestions = results;
    showDestinationSuggestions = results.isNotEmpty;
    notifyListeners();
  }
  
  /// Seleccionar una sugerencia de origen
  Future<void> selectOriginSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['place_id'] as String;
    final latLng = await placeIdToLatLng(placeId);
    
    if (latLng != null) {
      originPosition = latLng;
      isSelectSuggestionOrigin = true;
      originController.text = suggestion['main_text'] ?? suggestion['description'];
      isSelectSuggestionOrigin = false;
      showOriginSuggestions = false;
      originSuggestions = [];
      phase = MapSelectionPhase.completed; // No activar automáticamente el destino
      _updateMarkers();
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    }
  }
  
  /// Seleccionar una sugerencia de destino
  Future<void> selectDestinationSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['place_id'] as String;
    final latLng = await placeIdToLatLng(placeId);
    
    if (latLng != null) {
      destinationPosition = latLng;
      isSelectSuggestionDestination = true;
      destinationController.text = suggestion['main_text'] ?? suggestion['description'];
      isSelectSuggestionDestination = false;
      showDestinationSuggestions = false;
      destinationSuggestions = [];
      phase = MapSelectionPhase.completed;
      _updateMarkers();
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    }
  }
  
  /// Buscar rutas de buses entre origen y destino
  void searchRoutes() {
    if (!canSearchRoutes) return;
    
    isLoading = true;
    notifyListeners();
    
    searchResults = _routeManager.searchBestRoutes(
      origin: originPosition!,
      destination: destinationPosition!,
      maxWalkingDistance: 1000.0,
      maxResults: 5,
    );
    
    currentRouteIndex = 0;
    showRouteInfo = searchResults.isNotEmpty;
    
    if (searchResults.isNotEmpty) {
      _displayRoute(searchResults.first);
    }
    
    isLoading = false;
    notifyListeners();
  }
  
  /// Mostrar una ruta específica en el mapa
  void _displayRoute(RouteSearchResult route) {
    polylines.clear();
    
    // Polyline de caminar al pickup
    if (originPosition != null) {
      polylines.add(createWalkingPolyline(
        'to_pickup',
        [originPosition!, route.pickupPoint],
      ));
    }
    
    // Polyline de la ruta del bus (COMPLETA - desde inicio hasta fin)
    polylines.add(createBusRoutePolyline(route.ref, route.routePoints));
    
    // Polyline de caminar al destino
    if (destinationPosition != null) {
      polylines.add(createWalkingPolyline(
        'to_destination',
        [route.dropoffPoint, destinationPosition!],
      ));
    }
    
    _updateMarkers();
    
    // Ajustar cámara para mostrar toda la ruta
    if (_mapController != null && originPosition != null && destinationPosition != null) {
      final bounds = calculateBounds([originPosition!, destinationPosition!]);
      final expandedBounds = expandBounds(bounds, 500);
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(expandedBounds, 100),
      );
    }
  }
  
  /// Navegar a la siguiente ruta
  void nextRoute() {
    if (searchResults.isEmpty) return;
    
    currentRouteIndex = (currentRouteIndex + 1) % searchResults.length;
    _displayRoute(searchResults[currentRouteIndex]);
  }
  
  /// Navegar a la ruta anterior
  void previousRoute() {
    if (searchResults.isEmpty) return;
    
    currentRouteIndex = (currentRouteIndex - 1 + searchResults.length) % searchResults.length;
    _displayRoute(searchResults[currentRouteIndex]);
  }
  
  /// Reset para nueva búsqueda
  void resetSearch() {
    phase = MapSelectionPhase.origin;
    originPosition = currentPosition;
    destinationPosition = null;
    originController.text = 'Tu Ubicación';
    destinationController.text = '';
    searchResults = [];
    currentRouteIndex = 0;
    showRouteInfo = false;
    polylines.clear();
    _updateMarkers();
  }
  
  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
