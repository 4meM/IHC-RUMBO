// EJEMPLO DE INTEGRACIÓN - Paraderos Inteligentes con AR

// ============================================
// 1. EN TU MAP_CONTROLLER.DART
// ============================================

// Agregar estas propiedades:
class MapController extends ChangeNotifier {
  // ... código existente ...
  
  // Nueva propiedad para almacenar la ruta seleccionada
  BusRouteModel? _selectedRoute;
  BusRouteModel? get selectedRoute => _selectedRoute;
  
  String? _selectedRouteRef;
  String? get selectedRouteRef => _selectedRouteRef;
  
  // ... resto del código ...
  
  /// Seleccionar una ruta y navegar a pantalla de detalle
  void selectRoute(RouteWithScore routeWithScore, String routeRef) {
    _selectedRoute = routeWithScore.route.outbound ?? routeWithScore.route.return_;
    _selectedRouteRef = routeRef;
    notifyListeners();
  }
}

// ============================================
// 2. EN TU MAP_PREVIEW.DART
// ============================================

// Agregar en el Positioned donde muestras las rutas encontradas:

Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: Container(
    color: Colors.white,
    child: ListView(
      shrinkWrap: true,
      children: [
        // ... tus rutas actuales ...
        
        // Agregar esto en la lista de rutas
        if (_controller.routesFound.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _controller.routesFound.length,
            itemBuilder: (context, index) {
              final routeWithScore = _controller.routesFound[index];
              
              return GestureDetector(
                onTap: () {
                  // Navegar a la pantalla de detalle con paraderos inteligentes
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RouteDetailPage(
                        route: routeWithScore.route.outbound ?? 
                               routeWithScore.route.return_ ?? 
                               routeWithScore.route.outbound!,
                        userLocation: _controller.currentLocation,
                        routeRef: routeWithScore.route.ref,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          routeWithScore.route.ref,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(routeWithScore.route.displayName),
                    subtitle: Text(
                      'Caminar: ${(routeWithScore.distanceToOrigin).toStringAsFixed(0)}m • '
                      'Bus: ${(routeWithScore.routeDistance).toStringAsFixed(0)}m',
                    ),
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  ),
)

// ============================================
// 3. IMPORTAR EN TU MAIN.DART O APP.DART
// ============================================

import 'features/trip_planner/presentation/pages/route_detail_page.dart';

// ============================================
// 4. EJEMPLO COMPLETO DE USO EN UN BLOC/CONTROLLER
// ============================================

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final GeoJsonParserService _geoJsonService;
  
  RouteBloc(this._geoJsonService) : super(RouteInitial()) {
    on<SearchRoutesEvent>(_onSearchRoutes);
    on<SelectRouteEvent>(_onSelectRoute);
  }
  
  Future<void> _onSearchRoutes(
    SearchRoutesEvent event,
    Emitter<RouteState> emit,
  ) async {
    emit(RouteLoading());
    
    try {
      final routes = await _geoJsonService.findBestRoutes(
        origin: event.origin,
        destination: event.destination,
      );
      
      emit(RouteSearchSuccess(routes));
    } catch (e) {
      emit(RouteError(e.toString()));
    }
  }
  
  Future<void> _onSelectRoute(
    SelectRouteEvent event,
    Emitter<RouteState> emit,
  ) async {
    // La navegación se maneja en la UI, aquí solo emitimos el evento
    emit(RouteSelected(event.route, event.routeRef));
  }
}

// ============================================
// 5. ESTADOS DEL BLOC
// ============================================

abstract class RouteState {}

class RouteInitial extends RouteState {}

class RouteLoading extends RouteState {}

class RouteSearchSuccess extends RouteState {
  final List<RouteWithScore> routes;
  RouteSearchSuccess(this.routes);
}

class RouteSelected extends RouteState {
  final BusRouteModel route;
  final String routeRef;
  RouteSelected(this.route, this.routeRef);
}

class RouteError extends RouteState {
  final String message;
  RouteError(this.message);
}

// ============================================
// 6. EVENTOS DEL BLOC
// ============================================

abstract class RouteEvent {}

class SearchRoutesEvent extends RouteEvent {
  final LatLng origin;
  final LatLng destination;
  
  SearchRoutesEvent({
    required this.origin,
    required this.destination,
  });
}

class SelectRouteEvent extends RouteEvent {
  final BusRouteModel route;
  final String routeRef;
  
  SelectRouteEvent({
    required this.route,
    required this.routeRef,
  });
}

// ============================================
// 7. FLUJO COMPLETO
// ============================================

/*
USUARIO:
1. Abre la app
2. Ingresa origen y destino
3. Presiona "Buscar Rutas"

SISTEMA:
1. MapController busca rutas cercanas
2. Muestra lista de rutas recomendadas
3. Usuario toca una ruta

USUARIO TOCA RUTA:
1. Se navega a RouteDetailPage
2. Se generan 3 paraderos inteligentes automáticamente
3. Se muestran en cards informativos
4. Usuario puede navegar por los 3 con swipe

USUARIO TOCA "VER EN AR":
1. Se cambia a vista AR simulada
2. Muestra paradero actual con fondo azul
3. Muestra dirección y distancia
4. Usuario puede cambiar de paradero con swipe
5. Se pueden ver métricas detalladas

USUARIO SELECCIONA PARADERO:
1. Se muestra confirmación
2. Se puede guardar la selección
3. Se puede proceder a checkout/pago
*/

// ============================================
// 8. CÓMO PERSONALIZAR
// ============================================

// Cambiar los colores
// En smart_stops_ar_view.dart, busca _getStopTypeColor()

Color _getStopTypeColor(SmartStopType type) {
  switch (type) {
    case SmartStopType.nearest:
      return Colors.blue; // Cambiar aquí
    case SmartStopType.avoidTraffic:
      return Colors.orange; // Cambiar aquí
    case SmartStopType.guaranteedSeats:
      return Colors.green; // Cambiar aquí
  }
}

// Cambiar los emojis
// En smart_bus_stop_model.dart, busca get emoji

String get emoji {
  switch (this) {
    case SmartStopType.nearest:
      return '📍'; // Cambiar aquí
    case SmartStopType.avoidTraffic:
      return '🚗'; // Cambiar aquí
    case SmartStopType.guaranteedSeats:
      return '🪑'; // Cambiar aquí
  }
}

// Cambiar los datos simulados
// En smart_bus_stops_service.dart, busca generateSmartStops()
// Modifica los Math.Random() ranges según necesites

// ============================================
// 9. TESTING
// ============================================

void testSmartStops() {
  final userLocation = LatLng(-16.3994, -71.5350);
  
  // Crear una ruta de prueba
  final testRoute = BusRouteModel(
    id: 'test_route_1',
    name: 'Test Route',
    ref: '4A',
    coordinates: [
      LatLng(-16.3900, -71.5300),
      LatLng(-16.3950, -71.5350),
      LatLng(-16.4000, -71.5400),
      LatLng(-16.4050, -71.5450),
    ],
    color: Colors.blue,
  );
  
  // Generar paraderos
  final stops = SmartBusStopsService.generateSmartStops(
    userLocation: userLocation,
    route: testRoute,
    routeRef: '4A',
  );
  
  // Verificar
  assert(stops.length == 3);
  assert(stops[0].type == SmartStopType.nearest);
  assert(stops[1].type == SmartStopType.avoidTraffic);
  assert(stops[2].type == SmartStopType.guaranteedSeats);
  
  print('✅ Test de paraderos inteligentes pasado!');
}
