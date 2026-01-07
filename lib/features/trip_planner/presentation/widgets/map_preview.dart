import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/geometry_utils.dart';
import '../controllers/map_controller.dart' as controller;
import 'search_input_field.dart';
import 'place_suggestions_list.dart';
import 'map_search_bar.dart';
import 'map_action_button.dart';
import 'route_info_card.dart';
import 'map_loading_overlay.dart';
import 'route_navigation_controls.dart';
import 'start_tracking_button.dart';

/// Widget principal: Mapa con búsqueda de rutas
/// Propósito único: Renderizar el mapa y coordinar la UI con el MapController
class MapPreview extends StatefulWidget {
  const MapPreview({super.key});

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  late final controller.MapController _controller;
  String? _mapStyle;
  
  @override
  void initState() {
    super.initState();
    _controller = controller.MapController();
    _loadMapStyle();
    _controller.initialize().then((_) {
      if (_controller.errorMessage != null && mounted) {
        _showSnackBar(_controller.errorMessage!, isError: true);
      }
    });
    
    _controller.addListener(_onControllerUpdate);
    _controller.originController.addListener(_onOriginTextChanged);
    _controller.destinationController.addListener(_onDestinationTextChanged);
  }

  @override
  void dispose() {
    _controller.originController.removeListener(_onOriginTextChanged);
    _controller.destinationController.removeListener(_onDestinationTextChanged);
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style_minimal.json');
  }
  
  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }
  
  void _onOriginTextChanged() {
    if(_controller.isSelectSuggestionOrigin) return;
    
    final text = _controller.originController.text;
    
    if (text.isNotEmpty && 
        text != 'Tu Ubicación' && 
        text != 'Ubicación seleccionada' &&
        text != 'Obteniendo dirección...') {
      _controller.searchOriginPlaces(text);
    }
  }
  
  void _onDestinationTextChanged() {
    if(_controller.isSelectSuggestionDestination) return;
    
    final text = _controller.destinationController.text;
    
    if (text.isNotEmpty && 
        text != 'Ubicación seleccionada' &&
        text != 'Obteniendo dirección...') {
      _controller.searchDestinationPlaces(text);
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : AppColors.success,
          duration: Duration(seconds: isError ? 5 : 2),
        ),
      );
    }
  }
  
  void _onSearchRoutes() {
    _controller.searchRoutes();
    
    if (!_controller.hasRouteResults && mounted) {
      _showSnackBar('No se encontraron rutas viables', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Stack(
        children: [
          // Mapa de Google
          GoogleMap(
            onMapCreated: (mapController) {
              mapController.setMapStyle(_mapStyle);
              _controller.setMapController(mapController);
            },
            initialCameraPosition: CameraPosition(
              target: _controller.currentPosition ?? const LatLng(-16.409, -71.537),
              zoom: 15,
            ),
            markers: _controller.markers,
            polylines: _controller.polylines,
            onTap: _controller.onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Botón de retroceso con franja
          if (_controller.showRouteInfo)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.primary,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        _controller.showRouteInfo = false;
                        _controller.searchResults = [];
                        _controller.polylines.clear();
                        _controller.notifyListeners();
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Ruta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Barra de búsqueda
          MapSearchBar(
            originField: SearchInputField(
              controller: _controller.originController,
              hintText: 'Tu Ubicación Actual',
              icon: Icons.location_on,
              iconColor: Colors.green,
              readOnly: _controller.showRouteInfo,
              onTap: () {
                if (_controller.phase == controller.MapSelectionPhase.origin) {
                  _controller.phase = controller.MapSelectionPhase.completed;
                  _controller.notifyListeners();
                }
              },
              onIconTap: _controller.showRouteInfo ? null : () {
                FocusScope.of(context).unfocus();
                _controller.enableOriginSelection();
              },
              isSelecting: _controller.phase == controller.MapSelectionPhase.origin,
            ),
            destinationField: SearchInputField(
              controller: _controller.destinationController,
              hintText: 'Destino',
              icon: Icons.location_on,
              iconColor: Colors.red,
              readOnly: _controller.showRouteInfo,
              onTap: () {
                if (_controller.phase == controller.MapSelectionPhase.destination) {
                  _controller.phase = controller.MapSelectionPhase.completed;
                  _controller.notifyListeners();
                }
              },
              onIconTap: _controller.showRouteInfo ? null : () {
                FocusScope.of(context).unfocus();
                _controller.enableDestinationSelection();
              },
              isSelecting: _controller.phase == controller.MapSelectionPhase.destination,
            ),
            originSuggestions: (_controller.showOriginSuggestions && !_controller.showRouteInfo)
                ? PlaceSuggestionsList(
                    suggestions: _controller.originSuggestions,
                    onSuggestionTap: _controller.selectOriginSuggestion,
                  )
                : null,
            destinationSuggestions: (_controller.showDestinationSuggestions && !_controller.showRouteInfo)
                ? PlaceSuggestionsList(
                    suggestions: _controller.destinationSuggestions,
                    onSuggestionTap: _controller.selectDestinationSuggestion,
                  )
                : null,
          ),
          
          // Botón de buscar rutas
          if (!_controller.showRouteInfo && !keyboardVisible)
            MapActionButton(
              text: 'Buscar Rutas',
              icon: Icons.search,
              onPressed: _onSearchRoutes,
              isEnabled: _controller.canSearchRoutes,
            ),
          
          // Información de la ruta actual
          if (_controller.showRouteInfo && _controller.currentRoute != null)
            RouteInfoCard(
              routeRef: _controller.currentRoute!.ref,
              walkingDistance: formatDistance(
                _controller.currentRoute!.walkToPickup +
                    _controller.currentRoute!.walkToDestination,
              ),
              busDistance: formatDistance(_controller.currentRoute!.busDistance),
              estimatedTime: '${_controller.currentRoute!.getEstimatedTime().toStringAsFixed(0)} min',
            ),
          
          // Controles de navegación entre rutas
          if (_controller.showRouteInfo && _controller.searchResults.length > 1)
            RouteNavigationControls(
              currentIndex: _controller.currentRouteIndex,
              totalRoutes: _controller.searchResults.length,
              onNext: _controller.nextRoute,
              onPrevious: _controller.previousRoute,
              onClose: _controller.resetSearch,
            ),
          
          // Botón de iniciar tracking con datos reales
          if (_controller.showRouteInfo && _controller.currentRoute != null)
            Positioned(
              bottom: 80,
              right: 16,
              child: StartTrackingButton(
                busNumber: _controller.currentRoute!.ref,
                routeName: 'Ruta ${_controller.currentRoute!.ref}',
                origin: _controller.originPosition!,
                destination: _controller.destinationPosition!,
                routePoints: _controller.currentRoute!.routePoints,
                pickupPoint: _controller.currentRoute!.pickupPoint,
                dropoffPoint: _controller.currentRoute!.dropoffPoint,
              ),
            ),
          
          // Overlay de carga
          MapLoadingOverlay(
            isLoading: _controller.isLoading,
            message: 'Cargando...',
          ),
        ],
    );
  }
}
