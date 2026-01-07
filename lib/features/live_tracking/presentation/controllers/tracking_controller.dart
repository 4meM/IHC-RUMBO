import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/journey_progress_bar.dart';

/// ============================================
/// TRACKING CONTROLLER
/// Gestión de estado para Live Tracking
/// ============================================

class TrackingController extends ChangeNotifier {
  // Estado del mapa
  GoogleMapController? _mapController;
  
  // Estado de ubicaciones
  LatLng? _userPosition;
  LatLng? _busPosition;
  LatLng? _origin;
  LatLng? _destination;
  
  // Estado de la ruta
  List<LatLng> _routePoints = [];
  String _busNumber = '';
  String _routeName = '';
  
  // Estado de features
  bool _isSiestaMode = false;
  
  // Estado del progreso del viaje
  JourneyStage _currentJourneyStage = JourneyStage.walking;
  
  // Estado de simulación interactiva
  bool _isUserOnBus = false;
  LatLng? _draggedUserPosition;
  
  // Marcadores y polylines
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Información calculada
  String _estimatedArrivalTime = '--:--';
  String _distanceToBus = '--';
  
  // Getters
  GoogleMapController? get mapController => _mapController;
  LatLng? get userPosition => _userPosition;
  LatLng? get busPosition => _busPosition;
  LatLng? get origin => _origin;
  LatLng? get destination => _destination;
  List<LatLng> get routePoints => _routePoints;
  String get busNumber => _busNumber;
  String get routeName => _routeName;
  bool get isSiestaMode => _isSiestaMode;
  JourneyStage get currentJourneyStage => _currentJourneyStage;
  bool get isUserOnBus => _isUserOnBus;
  LatLng? get draggedUserPosition => _draggedUserPosition;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  String get estimatedArrivalTime => _estimatedArrivalTime;
  String get distanceToBus => _distanceToBus;
  
  // Setters
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }
  
  void setUserPosition(LatLng position) {
    _userPosition = position;
    notifyListeners();
  }
  
  void setBusPosition(LatLng position) {
    _busPosition = position;
    notifyListeners();
  }
  
  void setOrigin(LatLng position) {
    _origin = position;
    notifyListeners();
  }
  
  void setDestination(LatLng position) {
    _destination = position;
    notifyListeners();
  }
  
  void setRoutePoints(List<LatLng> points) {
    _routePoints = points;
    notifyListeners();
  }
  
  void setBusNumber(String number) {
    _busNumber = number;
    notifyListeners();
  }
  
  void setRouteName(String name) {
    _routeName = name;
    notifyListeners();
  }
  
  void toggleSiestaMode() {
    _isSiestaMode = !_isSiestaMode;
    notifyListeners();
  }
  
  void setMarkers(Set<Marker> markers) {
    _markers = markers;
    notifyListeners();
  }
  
  void setPolylines(Set<Polyline> polylines) {
    _polylines = polylines;
    notifyListeners();
  }
  
  void setEstimatedArrivalTime(String time) {
    _estimatedArrivalTime = time;
    notifyListeners();
  }
  
  void setDistanceToBus(String distance) {
    _distanceToBus = distance;
    notifyListeners();
  }
  
  /// Actualizar etapa del viaje
  void setJourneyStage(JourneyStage stage) {
    _currentJourneyStage = stage;
    notifyListeners();
  }
  
  /// Avanzar a la siguiente etapa
  void advanceToNextStage() {
    final nextIndex = _currentJourneyStage.index + 1;
    if (nextIndex < JourneyStage.values.length) {
      _currentJourneyStage = JourneyStage.values[nextIndex];
      notifyListeners();
    }
  }
  
  /// Usuario sube al bus
  void setUserOnBus(bool onBus) {
    _isUserOnBus = onBus;
    notifyListeners();
  }
  
  /// Actualizar posición arrastrada del usuario
  void updateDraggedUserPosition(LatLng position) {
    _draggedUserPosition = position;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
