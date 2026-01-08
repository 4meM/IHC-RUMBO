import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import '../../../../core/constants/app_colors.dart';
import '../../data/helpers/tracking_marker_helper.dart';
import '../../data/helpers/tracking_calculation_helper.dart';
import '../../data/helpers/tracking_polyline_helper.dart';
import '../../data/helpers/journey_simulation_helper.dart';
import '../controllers/tracking_controller.dart';
import '../widgets/tracking_bottom_bar.dart';
import '../widgets/tracking_info_card.dart';
import '../widgets/journey_progress_bar.dart';
import '../widgets/chat_bottom_sheet.dart';
import '../widgets/sos_bottom_sheet.dart';
import '../widgets/info_bottom_sheet.dart';
import '../../../trip_planner/presentation/controllers/map_controller.dart';

/// ============================================
/// LIVE TRACKING PAGE - REFACTORIZADO
/// De 615 líneas → ~180 líneas
/// Usando helpers, controller y widgets modulares
/// ============================================

class LiveTrackingPage extends StatefulWidget {
  final String busNumber;
  final String routeName;
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng>? routePoints;
  final LatLng? initialBusPosition;
  final LatLng? pickupPoint;
  final LatLng? dropoffPoint;

  const LiveTrackingPage({
    super.key,
    required this.busNumber,
    required this.routeName,
    this.origin,
    this.destination,
    this.routePoints,
    this.initialBusPosition,
    this.pickupPoint,
    this.dropoffPoint,
  });

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> with SingleTickerProviderStateMixin {
  late TrackingController _controller;
  String? _mapStyle;
  Timer? _busSimulationTimer;
  Timer? _journeyCheckTimer;
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _userWalkingIcon;
  
  // Animación para el marcador del usuario
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Lista de buses en simulación
  final List<_BusSimulation> _buses = [];
  static const int _totalBuses = 10;
  
  // Control de notificaciones
  bool _hasShownBusDialog = false;
  bool _hasShownDropoffAlert = false;
  
  // Bus específico en el que está el usuario
  String? _userBusId;
  
  // Control de arrastre
  bool _isDragging = false;
  bool _hasUserDraggedOnce = false; // Para ocultar el hint después del primer arrastre
  bool _isFollowingFinger = false; // El marcador sigue al dedo
  GoogleMapController? _mapController;
  
  // Polyline para caminar al paradero
  List<LatLng> _walkToPickupPath = [];
  // Polyline para caminar del dropoff al destino
  List<LatLng> _walkToDestinationPath = [];

  // Ubicación inicial (Arequipa, Perú) - fallback
  static const LatLng _defaultPosition = LatLng(-16.409047, -71.537451);

  @override
  void initState() {
    super.initState();
    _controller = TrackingController();
    _loadMapStyle();
    _initializeTracking();
    _initializeBusSimulation();
    
    // Inicializar animación de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_busIcon == null) {
      _createBusIcon();
    }
    if (_userWalkingIcon == null) {
      _createUserWalkingIcon();
    }
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style_minimal.json');
  }

  /// Crear icono de bus personalizado
  Future<void> _createBusIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/bus_icon.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 80,
        targetHeight: 80,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List resizedImage = byteData!.buffer.asUint8List();
      
      _busIcon = BitmapDescriptor.fromBytes(resizedImage);
    } catch (e) {
      _busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    if (mounted) setState(() {});
  }
  
  /// Crear icono circular personalizado para el usuario caminando (más pequeño)
  Future<void> _createUserWalkingIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 100.0; // MUCHO MÁS GRANDE para fácil arrastre
    
    // Círculo exterior (borde blanco)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, borderPaint);
    
    // Círculo interior (morado/púrpura)
    final circlePaint = Paint()
      ..color = const Color(0xFF9C27B0) // Morado
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 5, circlePaint);
    
    // Dibujar ícono de persona caminando (más grande)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Cabeza (más grande)
    canvas.drawCircle(const Offset(size / 2, size / 2 - 12), 10, iconPaint);
    
    // Cuerpo (más largo)
    final bodyPath = Path()
      ..moveTo(size / 2, size / 2 - 2)
      ..lineTo(size / 2, size / 2 + 18);
    canvas.drawPath(bodyPath, iconPaint..strokeWidth = 5..style = PaintingStyle.stroke);
    
    // Brazos (más anchos)
    final armPath = Path()
      ..moveTo(size / 2 - 10, size / 2 + 4)
      ..lineTo(size / 2 + 10, size / 2 + 4);
    canvas.drawPath(armPath, iconPaint..strokeWidth = 4);
    
    // Piernas (en movimiento, más largas)
    final leg1Path = Path()
      ..moveTo(size / 2, size / 2 + 18)
      ..lineTo(size / 2 - 8, size / 2 + 34);
    canvas.drawPath(leg1Path, iconPaint..strokeWidth = 5);
    
    final leg2Path = Path()
      ..moveTo(size / 2, size / 2 + 18)
      ..lineTo(size / 2 + 8, size / 2 + 30);
    canvas.drawPath(leg2Path, iconPaint..strokeWidth = 5);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    _userWalkingIcon = BitmapDescriptor.fromBytes(bytes);
    if (mounted) setState(() {});
  }

  /// Inicializar tracking con datos reales o defaults
  void _initializeTracking() {
    // Configurar datos básicos
    _controller.setBusNumber(widget.busNumber);
    _controller.setRouteName(widget.routeName);

    // Usar datos reales de la ruta si están disponibles
    final userPos = widget.origin ?? _defaultPosition;
    final busPos = widget.initialBusPosition ?? const LatLng(-16.405, -71.535);
    final origin = widget.origin ?? userPos;
    final destination = widget.destination ?? const LatLng(-16.400, -71.530);
    final routePoints = widget.routePoints ?? [userPos, busPos, destination];

    _controller.setUserPosition(userPos);
    _controller.updateDraggedUserPosition(userPos);
    _controller.setBusPosition(busPos);
    _controller.setOrigin(origin);
    _controller.setDestination(destination);
    _controller.setRoutePoints(routePoints);
    
    // Configurar caminos para arrastrar
    if (widget.pickupPoint != null) {
      _walkToPickupPath = [origin, widget.pickupPoint!];
    }
    if (widget.dropoffPoint != null && widget.destination != null) {
      _walkToDestinationPath = [widget.dropoffPoint!, destination];
    }

    // Crear marcadores usando helper (incluye pickup y dropoff amarillos)
    final markers = createTrackingMarkers(
      userPosition: userPos,
      busPosition: busPos,
      origin: origin,
      destination: destination,
      busNumber: widget.busNumber,
      pickupPoint: widget.pickupPoint,
      dropoffPoint: widget.dropoffPoint,
    );
    _controller.setMarkers(markers);

    // Crear polylines (ruta del bus + caminar entrecortado)
    final walkToPickup = widget.pickupPoint != null 
        ? [origin, widget.pickupPoint!] 
        : null;
    final walkToDestination = widget.dropoffPoint != null 
        ? [widget.dropoffPoint!, destination] 
        : null;
    
    final polylines = createTrackingPolylines(
      busRoute: routePoints,
      walkToPickup: walkToPickup,
      walkToDestination: walkToDestination,
    );
    _controller.setPolylines(polylines);

    _updateTrackingInfo();
    
    // Iniciar timer para verificar eventos del viaje
    _startJourneyEventChecker();
  }
  
  /// Iniciar verificación de eventos del viaje
  void _startJourneyEventChecker() {
    _journeyCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      _checkJourneyEvents();
    });
  }
  
  /// Verificar eventos del viaje
  void _checkJourneyEvents() {
    final userPos = _controller.draggedUserPosition ?? _controller.userPosition;
    if (userPos == null) return;
    
    switch (_controller.currentJourneyStage) {
      case JourneyStage.walking:
        _checkArrivedAtPickup(userPos);
        break;
      case JourneyStage.waiting:
        _checkBusArrival(userPos);
        break;
      case JourneyStage.onBus:
        _checkNearDropoff(userPos);
        break;
      case JourneyStage.gettingOff:
        _checkArrivedAtDestination(userPos);
        break;
      case JourneyStage.arrived:
        break;
    }
  }
  
  /// Verificar si llegó al paradero (pickup)
  void _checkArrivedAtPickup(LatLng userPos) {
    if (widget.pickupPoint == null) return;
    
    if (isAtSameLocation(userPos, widget.pickupPoint!)) {
      _controller.setJourneyStage(JourneyStage.waiting);
      _hasShownBusDialog = false; // Resetear para mostrar el dialog cuando llegue el bus
      _showNotification('¡Llegaste al paradero! Espera el bus', Icons.check_circle);
    }
  }
  
  /// Verificar si el bus está llegando
  void _checkBusArrival(LatLng userPos) {
    if (widget.pickupPoint == null || _controller.routePoints == null) return;
    if (_hasShownBusDialog) return; // No mostrar el dialog múltiples veces
    
    // Buscar cualquier bus que esté cerca del paradero
    for (var bus in _buses) {
      final busPos = _getPositionOnRoute(_controller.routePoints!, bus.routeProgress);
      
      // Verificar si el bus está cerca del paradero (50 metros)
      final distanceStr = calculateDistanceInKm(busPos, widget.pickupPoint!);
      final distance = (double.tryParse(distanceStr) ?? 0.0) * 1000; // Convertir a metros
      
      if (distance < 50) { // Bus está a menos de 50 metros del paradero
        _hasShownBusDialog = true;
        _userBusId = bus.id; // Guardar el ID del bus específico
        _showBoardBusDialog();
        break;
      }
    }
  }
  
  /// Verificar si está cerca del dropoff
  void _checkNearDropoff(LatLng userPos) {
    if (widget.dropoffPoint == null) return;
    if (_hasShownDropoffAlert) return;
    
    if (isNearLocation(userPos, widget.dropoffPoint!)) {
      _hasShownDropoffAlert = true;
      _showGetOffBusDialog();
    }
  }
  
  /// Verificar si llegó al destino
  void _checkArrivedAtDestination(LatLng userPos) {
    if (_controller.destination == null) return;
    
    if (isAtSameLocation(userPos, _controller.destination!)) {
      _controller.setJourneyStage(JourneyStage.arrived);
      _showArrivalDialog();
    }
  }
  
  /// Mostrar diálogo de llegada al destino
  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: AppColors.success, size: 32),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                '¡Llegaste a tu destino!',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: AppColors.success, size: 64),
            SizedBox(height: 16),
            Text(
              '¡Viaje completado con éxito!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              // Ir directamente al home (mapa inicial) y limpiar toda la pila
              // Usar pushReplacement con query param único para forzar recreación
              final resetKey = DateTime.now().millisecondsSinceEpoch.toString();
              context.pushReplacement('/home?resetKey=$resetKey');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Nuevo Viaje'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }
  
  /// Mostrar dialog para subir al bus
  void _showBoardBusDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.directions_bus, color: AppColors.primary),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '¡El bus ha llegado!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text('¿Deseas subir al bus ${widget.busNumber}?'),
        actions: [
          TextButton(
            onPressed: () {              _userBusId = null; // No sube a ningún bus              Navigator.pop(context);
              _showNotification('Esperando el siguiente bus...', Icons.access_time);
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _boardBus();
            },
            child: const Text('Sí, subir'),
          ),
        ],
      ),
    );
  }
  
  /// Usuario sube al bus
  void _boardBus() {
    _controller.setUserOnBus(true);
    _controller.setJourneyStage(JourneyStage.onBus);
    _hasShownDropoffAlert = false; // Resetear para la alerta de bajada
    _showNotification('En viaje hacia tu destino', Icons.directions_bus);
  }
  
  /// Mostrar dialog para bajar del bus
  void _showGetOffBusDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: AppColors.warning),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '¡Llegaste a tu parada!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text('¿Deseas bajar del bus aquí?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _hasShownDropoffAlert = false; // Permitir que pregunte de nuevo
              _showNotification('Continuando en el bus...', Icons.directions_bus);
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _getOffBus();
            },
            child: const Text('Sí, bajar'),
          ),
        ],
      ),
    );
  }
  
  /// Usuario baja del bus
  void _getOffBus() {
    _controller.setUserOnBus(false);
    _userBusId = null;
    _controller.setJourneyStage(JourneyStage.gettingOff);
    
    // Posicionar al usuario en el dropoff point
    if (widget.dropoffPoint != null) {
      _controller.updateDraggedUserPosition(widget.dropoffPoint!);
      _controller.setUserPosition(widget.dropoffPoint!);
    }
    
    _showNotification('¡Bajaste del bus! Camina hacia tu destino', Icons.directions_walk);
  }
  
  /// Mostrar notificación
  void _showNotification(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Inicializar simulación de múltiples buses
  void _initializeBusSimulation() {
    final routePoints = _controller.routePoints;
    if (routePoints == null || routePoints.isEmpty) return;
    
    // Crear 10 buses con separación en la ruta
    final separationPercent = 1.0 / _totalBuses;
    for (int i = 0; i < _totalBuses; i++) {
      _buses.add(_BusSimulation(
        id: 'bus_$i',
        routeProgress: (i * separationPercent) % 1.0,
        speed: 0.0003, // Velocidad constante y lenta (simula combi real)
      ));
    }
    
    // Timer para actualizar posiciones cada 200ms para movimiento suave
    _busSimulationTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      _updateBusPositions();
    });
  }
  
  /// Actualizar posiciones de todos los buses
  void _updateBusPositions() {
    final routePoints = _controller.routePoints;
    if (routePoints == null || routePoints.isEmpty) return;
    
    final markers = <Marker>{};
    
    // Usuario arrastrable (círculo morado con ícono de caminar) - solo si no está en el bus
    final userDisplayPos = _controller.draggedUserPosition ?? _controller.userPosition;
    if (userDisplayPos != null) {
      if (!_controller.isUserOnBus) {
        // Usuario ARRASTRABLE - ícono grande de 100x100px
        markers.add(Marker(
          markerId: const MarkerId('user'),
          position: userDisplayPos,
          draggable: true,
          onDragStart: (position) {
            setState(() {
              _isDragging = true;
              _hasUserDraggedOnce = true;
            });
          },
          onDrag: (newPosition) {
            _controller.updateDraggedUserPosition(newPosition);
          },
          onDragEnd: (position) {
            _onUserDragEnd(position);
            setState(() {
              _isDragging = false;
            });
          },
          icon: _userWalkingIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 1000,
          alpha: _isDragging ? 0.7 : 1.0,
        ));
      } else{
        // Usuario en el bus (no arrastrable, círculo morado)
        markers.add(Marker(
          markerId: const MarkerId('user'),
          position: userDisplayPos,
          draggable: false,
          icon: _userWalkingIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 999,
        ));
      }
    }
    
    // Marcadores fijos
    if (_controller.origin != null) {
      markers.add(Marker(
        markerId: const MarkerId('origin'),
        position: _controller.origin!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    if (_controller.destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _controller.destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    if (widget.pickupPoint != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ));
    }
    if (widget.dropoffPoint != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.dropoffPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ));
    }
    
    // Actualizar y agregar cada bus
    LatLng? closestBusPosition;
    double? closestDistance;
    
    for (var bus in _buses) {
      // Avanzar el bus
      bus.routeProgress = (bus.routeProgress + bus.speed) % 1.0;
      
      // Calcular posición en la ruta
      final position = _getPositionOnRoute(routePoints, bus.routeProgress);
      
      // Agregar marcador del bus
      markers.add(Marker(
        markerId: MarkerId(bus.id),
        position: position,
        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        rotation: _calculateBearing(routePoints, bus.routeProgress),
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
      
      // Si el usuario está en este bus específico, moverlo junto a él
      if (_controller.isUserOnBus && _userBusId == bus.id) {
        // Posición ligeramente offset para que se vean ambos
        final offsetLat = position.latitude + 0.00005;
        _controller.updateDraggedUserPosition(LatLng(offsetLat, position.longitude));
        _controller.setUserPosition(LatLng(offsetLat, position.longitude));
        closestBusPosition = position;
      }
      
      // Encontrar el bus más cercano al usuario (solo para tracking info)
      if (_controller.userPosition != null && !_controller.isUserOnBus) {
        final distanceStr = calculateDistanceInKm(_controller.userPosition!, position);
        final distance = double.tryParse(distanceStr) ?? 0.0;
        if (closestDistance == null || distance < closestDistance) {
          closestDistance = distance;
          closestBusPosition = position;
        }
      }
    }
    
    // Actualizar el bus principal (el más cercano)
    if (closestBusPosition != null) {
      _controller.setBusPosition(closestBusPosition);
      _updateTrackingInfo();
    }
    
    _controller.setMarkers(markers);
  }
  
  /// Manejar fin de arrastre del usuario
  void _onUserDragEnd(LatLng position) {
    setState(() {
      _isDragging = false;
      _hasUserDraggedOnce = true; // El usuario ya arrastró, ocultar hint
    });
    
    List<LatLng> currentPath = [];
    
    // Determinar en qué camino está el usuario
    switch (_controller.currentJourneyStage) {
      case JourneyStage.walking:
        currentPath = _walkToPickupPath;
        break;
      case JourneyStage.gettingOff:
        currentPath = _walkToDestinationPath;
        break;
      default:
        return;
    }
    
    if (currentPath.isEmpty) return;
    
    // Snap al camino
    final snappedPosition = snapToPolyline(position, currentPath);
    _controller.updateDraggedUserPosition(snappedPosition);
    _controller.setUserPosition(snappedPosition);
  }

  /// Obtener posición en la ruta basado en el progreso (0.0 a 1.0)
  LatLng _getPositionOnRoute(List<LatLng> route, double progress) {
    final totalDistance = _calculateTotalDistance(route);
    final targetDistance = totalDistance * progress;
    
    double accumulatedDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      final distanceStr = calculateDistanceInKm(route[i], route[i + 1]);
      final segmentDistance = (double.tryParse(distanceStr) ?? 0.0) * 1000;
      if (accumulatedDistance + segmentDistance >= targetDistance) {
        final ratio = (targetDistance - accumulatedDistance) / segmentDistance;
        return LatLng(
          route[i].latitude + (route[i + 1].latitude - route[i].latitude) * ratio,
          route[i].longitude + (route[i + 1].longitude - route[i].longitude) * ratio,
        );
      }
      accumulatedDistance += segmentDistance;
    }
    return route.last;
  }
  
  /// Calcular distancia total de la ruta
  double _calculateTotalDistance(List<LatLng> route) {
    double total = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      final distanceStr = calculateDistanceInKm(route[i], route[i + 1]);
      total += (double.tryParse(distanceStr) ?? 0.0) * 1000;
    }
    return total;
  }
  
  /// Calcular rotación del bus basado en la dirección
  double _calculateBearing(List<LatLng> route, double progress) {
    final position = _getPositionOnRoute(route, progress);
    final nextProgress = (progress + 0.01) % 1.0;
    final nextPosition = _getPositionOnRoute(route, nextProgress);
    
    final dLat = nextPosition.latitude - position.latitude;
    final dLng = nextPosition.longitude - position.longitude;
    return atan2(dLng, dLat) * 180 / pi;
  }

  /// Actualizar información de tracking (distancia, tiempo)
  void _updateTrackingInfo() {
    if (_controller.userPosition == null || _controller.busPosition == null) {
      return;
    }

    final distanceKm = calculateDistanceInKm(
      _controller.userPosition!,
      _controller.busPosition!,
    );
    final minutes = calculateEstimatedMinutes(distanceKm);
    final arrivalTime = formatEstimatedArrivalTime(minutes);

    _controller.setDistanceToBus('$distanceKm Km');
    _controller.setEstimatedArrivalTime(arrivalTime);
  }

  void _onMapCreated(GoogleMapController controller) {
    if (_mapStyle != null) {
      controller.setMapStyle(_mapStyle);
    }
    _mapController = controller;
    _controller.setMapController(controller);
  }
  
  /// Convertir coordenadas de pantalla a coordenadas del mapa (aproximado)
  Future<LatLng?> _screenToLatLng(Offset screenPosition) async {
    if (_mapController == null) return null;
    
    try {
      final visibleRegion = await _mapController!.getVisibleRegion();
      final screenSize = MediaQuery.of(context).size;
      
      // Calcular el rango de lat/lng visible
      final latRange = visibleRegion.northeast.latitude - visibleRegion.southwest.latitude;
      final lngRange = visibleRegion.northeast.longitude - visibleRegion.southwest.longitude;
      
      // Convertir posición de pantalla a coordenadas del mapa
      final lat = visibleRegion.northeast.latitude - (screenPosition.dy / screenSize.height) * latRange;
      final lng = visibleRegion.southwest.longitude + (screenPosition.dx / screenSize.width) * lngRange;
      
      return LatLng(lat, lng);
    } catch (e) {
      return null;
    }
  }
  
  /// Verificar si un toque está cerca del marcador del usuario
  Future<bool> _isTouchNearUserMarker(Offset screenPosition) async {
    final touchLatLng = await _screenToLatLng(screenPosition);
    if (touchLatLng == null) return false;
    
    final userPos = _controller.draggedUserPosition ?? _controller.userPosition;
    if (userPos == null) return false;
    
    // Calcular distancia entre el toque y el marcador
    const earthRadius = 6371000; // metros
    final dLat = (touchLatLng.latitude - userPos.latitude) * pi / 180;
    final dLng = (touchLatLng.longitude - userPos.longitude) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userPos.latitude * pi / 180) * cos(touchLatLng.latitude * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;
    
    // Considerar "cerca" si está a menos de 50 metros (ajustable)
    return distance < 50;
  }

  void _onChatPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatBottomSheet(),
    );
  }

  void _onSOSPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SOSBottomSheet(
        onNotificationShow: _showTopNotification,
      ),
    );
  }

  void _onSiestaToggled() {
    _controller.toggleSiestaMode();

    final message = _controller.isSiestaMode
        ? 'Alarma activada'
        : 'Alarma desactivada';
    final icon = _controller.isSiestaMode ? Icons.alarm_on : Icons.alarm_off;
    final color = _controller.isSiestaMode
        ? AppColors.success
        : AppColors.textSecondary;

    _showTopNotification(message, icon, color: color);
  }

  void _onInfoPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InfoBottomSheet(
        busNumber: widget.busNumber,
        routeName: widget.routeName,
      ),
    );
  }

  void _showTopNotification(String message, IconData icon, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: color ?? AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  /// Widget con animación de hint para arrastre
  Widget _buildDragHint() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // Animación de desplazamiento horizontal más amplio y lento
        final offset = (_pulseAnimation.value - 1.0) * 80; // Se mueve más suave
        
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Texto instructivo grande y claro
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF9C27B0),
                      Color(0xFFE91E63),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.touch_app, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Mantén presionado para arrastrar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Demostración visual del gesto
              Container(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Línea de trayectoria
                    Container(
                      width: 160,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Puntos de inicio y fin
                    Positioned(
                      left: -10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Flecha de dirección
                    Positioned(
                      right: -30,
                      child: Icon(
                        Icons.arrow_forward,
                        size: 32,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    // Mano que se mueve de izquierda a derecha
                    Transform.translate(
                      offset: Offset(offset, 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withOpacity(0.6),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.back_hand,
                          size: 36,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bus ${widget.busNumber}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: Consumer<TrackingController>(
          builder: (context, controller, child) {
            return Stack(
              children: [
                // Mapa
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: controller.userPosition ?? _defaultPosition,
                    zoom: 14.0,
                  ),
                  markers: controller.markers,
                  polylines: controller.polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // Barra de progreso del viaje
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: JourneyProgressBar(
                    currentStage: controller.currentJourneyStage,
                  ),
                ),
                
                // Hint visual de arrastre (solo cuando puede arrastrar y no lo ha hecho aún)
                if (!_hasUserDraggedOnce && 
                    !controller.isUserOnBus && 
                    (controller.currentJourneyStage == JourneyStage.walking || 
                     controller.currentJourneyStage == JourneyStage.gettingOff))
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: _buildDragHint(),
                  ),

                // Tarjeta de información superior
                Positioned(
                  bottom: 160,
                  left: 16,
                  right: 16,
                  child: TrackingInfoCard(
                    arrivalTime: controller.estimatedArrivalTime,
                    distance: controller.distanceToBus,
                    busNumber: widget.busNumber,
                  ),
                ),

                // Barra inferior con botones
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: TrackingBottomBar(
                    isSiestaMode: controller.isSiestaMode,
                    onChatPressed: _onChatPressed,
                    onSOSPressed: _onSOSPressed,
                    onSiestaToggled: _onSiestaToggled,
                    onInfoPressed: _onInfoPressed,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _busSimulationTimer?.cancel();
    _journeyCheckTimer?.cancel();
    _controller.dispose();
    // Al salir del LiveTracking, limpiar el estado de ruta en el MapController
    try {
      final mapCtrl = MapController();
      mapCtrl.resetSearch();
    } catch (_) {}
    super.dispose();
  }
}

/// Clase auxiliar para simulación de buses
class _BusSimulation {
  final String id;
  double routeProgress; // 0.0 a 1.0
  final double speed;
  
  _BusSimulation({
    required this.id,
    required this.routeProgress,
    required this.speed,
  });
}
