import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/geolocation_helper.dart';
import '../../../../core/services/places_api_helper.dart';
import '../../../../core/utils/map_marker_factory.dart';
import '../../../../core/utils/map_polyline_factory.dart';
import '../../../../core/utils/geometry_utils.dart';
import '../../data/managers/route_search_manager.dart';
import '../../data/services/smart_bus_stops_service.dart';
import '../../data/services/selected_stop_storage.dart';

/// Estados posibles durante la selección
enum MapSelectionPhase { origin, destination, completed }

/// Controller: Manejar todo el estado y lógica del mapa
/// Propósito único: Coordinar estado, búsquedas y actualizaciones del mapa
class MapController extends ChangeNotifier {
  // Singleton instance to preserve state across route pushes/pops
  static MapController? _instance;

  factory MapController() {
    _instance ??= MapController._internal();
    return _instance!;
  }

  MapController._internal();
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

  /// Calcula el pickup efectivo considerando la selección guardada
  LatLng? get currentEffectivePickup {
    final route = currentRoute;
    if (route == null) return null;

    final userLoc = originPosition ?? currentPosition;
    if (userLoc == null) return route.pickupPoint;

    try {
      final savedStopType = SelectedStopStorage.getSavedStopType(route.ref);
      if (savedStopType != null) {
        final stops = SmartBusStopsService.generateSmartStopsFromPoints(
          userLocation: userLoc,
          routePoints: route.routePoints,
          routeRef: route.ref,
        );
        if (stops.isNotEmpty) {
          try {
            final found = stops.firstWhere((s) => s.type.name == savedStopType);
            return found.location;
          } catch (_) {
            return stops.first.location;
          }
        }
      }
    } catch (_) {}

    return route.pickupPoint;
  }
  
  /// Inicializar: obtener ubicación y cargar rutas
  Future<void> initialize() async {
    if (_initialized) return;
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
    // Escuchar cambios en la selección de paraderos para actualizar marcadores
    SelectedStopStorage.notifier.addListener(() {
      // Si hay una ruta actual mostrada, refrescar marcadores y polylines
      if (currentRoute != null) {
        _displayRoute(currentRoute!);
        notifyListeners();
      } else {
        _updateMarkers();
      }
    });
    isLoading = false;
    notifyListeners();
    _moveToCurrentLocation();
    _initialized = true;
  }

  bool _initialized = false;
  
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

    // Agregar marcadores de pickup/dropoff solo si hay ruta activa y estamos mostrando info de ruta
    if (currentRoute != null && showRouteInfo) {
      // Usar pickup efectivo si existe selección guardada
      LatLng pickupToShow = currentRoute!.pickupPoint;
      try {
        final savedStopType = SelectedStopStorage.getSavedStopType(currentRoute!.ref);
        try {
          // ignore: avoid_print
          print('[MapController] _updateMarkers routeRef=${currentRoute!.ref} saved=$savedStopType');
        } catch (_) {}
        if (savedStopType != null && currentPosition != null) {
          final stops = SmartBusStopsService.generateSmartStopsFromPoints(
            userLocation: currentPosition!,
            routePoints: currentRoute!.routePoints,
            routeRef: currentRoute!.ref,
          );
          if (stops.isNotEmpty) {
            try {
              final found = stops.firstWhere((s) => s.type.name == savedStopType);
              pickupToShow = found.location;
              try {
                // ignore: avoid_print
                print('[MapController] matched saved stop -> type=${found.type.name} at $pickupToShow');
              } catch (_) {}
            } catch (_) {
              // fallback to first
              pickupToShow = stops.first.location;
            }
          }
        }
      } catch (_) {}

      markers.add(createPickupMarker(pickupToShow));
      markers.add(createDropoffMarker(currentRoute!.dropoffPoint));
    }

    try {
      // ignore: avoid_print
      final ids = markers.map((m) => m.markerId.value).join(',');
      print('[MapController] _updateMarkers end -> searchResults=${searchResults.length} showRouteInfo=$showRouteInfo markers=${markers.length} ids=[$ids]');
    } catch (_) {}
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
    
    // Determinar pickup efectivo (podría ser un paradero seleccionado por el usuario)
    LatLng effectivePickup = route.pickupPoint;
      try {
        final savedStopType = SelectedStopStorage.getSavedStopType(route.ref);
        try {
          // ignore: avoid_print
          print('[MapController] _displayRoute routeRef=${route.ref} saved=$savedStopType');
        } catch (_) {}
        if (savedStopType != null && originPosition != null) {
        final stops = SmartBusStopsService.generateSmartStopsFromPoints(
          userLocation: originPosition!,
          routePoints: route.routePoints,
          routeRef: route.ref,
        );
          dynamic found;
          if (stops.isNotEmpty) {
            try {
              found = stops.firstWhere((s) => s.type.name == savedStopType);
            } catch (_) {
              found = stops.first;
            }
          }
          if (found != null) {
            effectivePickup = found.location;
            try {
              // ignore: avoid_print
              print('[MapController] _displayRoute matched saved stop -> type=${found.type.name} at $effectivePickup');
            } catch (_) {}
          }
      }
    } catch (_) {}

    // Polyline de caminar al pickup
    if (originPosition != null) {
      polylines.add(createWalkingPolyline(
        'to_pickup',
        [originPosition!, effectivePickup],
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
    try {
      // ignore: avoid_print
      print('[MapController] resetSearch -> searchResults=${searchResults.length} showRouteInfo=$showRouteInfo markers=${markers.length}');
    } catch (_) {}
  }
  
  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
