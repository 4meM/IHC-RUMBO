# RUMBO - Nueva Arquitectura Modular

## 📋 RESUMEN DE LA REESTRUCTURACIÓN

Se ha refactorizado completamente el proyecto aplicando principios SOLID y Clean Code, dividiendo toda la lógica en **funciones puras independientes** estilo programación competitiva.

### ✅ ANTES vs DESPUÉS

| Archivo | Antes | Después | Reducción |
|---------|-------|---------|-----------|
| `map_preview.dart` | 736 líneas | 193 líneas | **74% menos** |
| `login_page.dart` | 250 líneas | 88 líneas | **65% menos** |
| `verify_code_page.dart` | 300 líneas | 95 líneas | **68% menos** |
| `notification_service.dart` | 117 líneas | 105 líneas | **10% menos** |
| `geojson_parser_service.dart` | 437 líneas monolíticas | 8 archivos modulares | **100% modular** |

### 📊 MÓDULOS REFACTORIZADOS

- ✅ **Core Services** (Notificaciones)
- ✅ **Trip Planner** (Completo)
- ✅ **Auth** (Completo)
- ⏳ Live Tracking (Vacío - sin implementar)
- ⏳ Travel Assistant (Vacío - sin implementar)
- ⏳ Community (Vacío - sin implementar)

---

## 🏗️ NUEVA ESTRUCTURA DE ARCHIVOS

### **1. CORE UTILITIES (Funciones Puras)**

#### `lib/core/utils/geometry_utils.dart`
**Propósito**: Cálculos geométricos y matemáticos puros

```dart
// ✅ Calcular distancia en metros entre dos puntos geográficos
double calculateDistance(LatLng point1, LatLng point2)

// ✅ Encontrar el punto más cercano de una lista a un punto objetivo
({LatLng point, double distance}) findClosestPoint(LatLng target, List<LatLng> candidates)

// ✅ Calcular el bounding box de una lista de puntos
LatLngBounds calculateBounds(List<LatLng> points)

// ✅ Calcular el punto central de una lista de coordenadas
LatLng calculateCentroid(List<LatLng> points)

// ✅ Formatear distancia en metros a texto legible
String formatDistance(double meters)

// ✅ Calcular distancia acumulada a lo largo de una ruta
double calculateRouteDistance(List<LatLng> routePoints)

// ✅ Verificar si un punto está dentro de un bounding box
bool isPointInsideBounds(LatLng point, LatLngBounds bounds)

// ✅ Encontrar el índice del punto más cercano en una ruta
int findClosestPointIndex(LatLng target, List<LatLng> routePoints)

// ✅ Calcular distancia entre dos puntos a lo largo de una ruta
double calculateDistanceBetweenIndices(int startIndex, int endIndex, List<LatLng> routePoints)

// ✅ Expandir un bounding box con un margen en metros
LatLngBounds expandBounds(LatLngBounds bounds, double marginMeters)
```

**Uso**: Le das coordenadas, te retorna cálculos. Sin estado, sin efectos secundarios.

---

#### `lib/core/utils/map_marker_factory.dart`
**Propósito**: Factory pattern para crear marcadores del mapa

```dart
// ✅ Crear un marcador de origen (verde)
Marker createOriginMarker(LatLng position)

// ✅ Crear un marcador de destino (rojo)
Marker createDestinationMarker(LatLng position)

// ✅ Crear un marcador de pickup (azul)
Marker createPickupMarker(LatLng position)

// ✅ Crear un marcador de dropoff (amarillo)
Marker createDropoffMarker(LatLng position)

// ✅ Crear set con origen y destino
Set<Marker> createOriginDestinationMarkers(LatLng origin, LatLng destination)

// ✅ Crear set completo de marcadores para una ruta
Set<Marker> createCompleteRouteMarkers({...})

// ✅ Crear marcador genérico personalizado
Marker createCustomMarker({required String id, required LatLng position, ...})

// ✅ Crear múltiples marcadores de bus
Set<Marker> createBusMarkers(Map<String, LatLng> busPositions)
```

**Uso**: `createOriginMarker(miPosicion)` → listo, marcador creado.

---

#### `lib/core/utils/map_polyline_factory.dart`
**Propósito**: Factory pattern para crear polylines del mapa

```dart
// ✅ Crear una polyline básica
Polyline createPolyline({required String id, required List<LatLng> points, ...})

// ✅ Crear polyline para ruta de bus (azul)
Polyline createBusRoutePolyline(String routeId, List<LatLng> routePoints)

// ✅ Crear polyline para caminar (gris punteado)
Polyline createWalkingPolyline(String id, List<LatLng> walkingPoints)

// ✅ Crear set de polylines para ruta completa
Set<Polyline> createCompleteRoutePolylines({...})

// ✅ Crear polyline destacada
Polyline createHighlightedPolyline({...})

// ✅ Crear múltiples polylines con colores
Set<Polyline> createMultipleBusRoutePolylines(Map<String, List<LatLng>> routes, List<Color> colors)

// ✅ Crear polyline semitransparente para rutas inactivas
Polyline createInactiveRoutePolyline(String id, List<LatLng> points)
```

**Uso**: Le das puntos, te devuelve la polyline lista para mostrar.

---

### **2. CORE SERVICES (Funciones con Side Effects)**

#### `lib/core/services/geolocation_helper.dart`
**Propósito**: Operaciones de GPS en funciones individuales

```dart
// ✅ Verificar si GPS está habilitado
Future<bool> isGPSEnabled()

// ✅ Verificar estado de permisos
Future<LocationPermission> checkLocationPermission()

// ✅ Solicitar permisos
Future<LocationPermission> requestLocationPermission()

// ✅ Obtener posición actual
Future<Position> getCurrentPosition()

// ✅ Convertir Position a LatLng
LatLng positionToLatLng(Position position)

// ✅ Obtener posición como LatLng directamente
Future<LatLng> getCurrentLatLng()

// ✅ Asegurar permisos antes de continuar
Future<bool> ensureLocationPermissions()

// ✅ Validar GPS y permisos con mensaje de error
Future<String?> validateLocationServices()

// ✅ Obtener ubicación con manejo completo de errores
Future<({LatLng? location, String? error})> getLocationSafely()

// ✅ Crear stream de actualizaciones de posición
Stream<Position> getPositionStream()

// ✅ Stream de LatLng para seguimiento en tiempo real
Stream<LatLng> getLatLngStream()
```

**Uso**: Cada función hace UNA cosa relacionada con GPS.

---

#### `lib/core/services/places_api_helper.dart`
**Propósito**: Interacción con Google Places API en funciones atómicas

```dart
// ✅ Buscar lugares usando Autocomplete
Future<List<Map<String, dynamic>>> searchPlaces(String query)

// ✅ Obtener detalles de un lugar
Future<Map<String, dynamic>?> getPlaceDetails(String placeId)

// ✅ Convertir place_id a coordenadas
Future<LatLng?> placeIdToLatLng(String placeId)

// ✅ Buscar lugares cerca de una coordenada
Future<List<Map<String, dynamic>>> searchNearbyPlaces({...})

// ✅ Geocoding inverso: coordenadas → dirección
Future<String?> getAddressFromCoordinates(LatLng coordinates)

// ✅ Buscar sugerencias priorizando Arequipa
Future<List<Map<String, dynamic>>> searchPlacesInArequipa(String query)
```

**Uso**: Una función = una llamada a la API.

---

#### `lib/core/utils/clipboard_helper.dart`
**Propósito**: Operaciones con portapapeles

```dart
// ✅ Copiar texto al portapapeles
Future<void> copyToClipboard(String text)

// ✅ Obtener texto del portapapeles
Future<String?> getClipboardText()

// ✅ Pegar código de verificación (6 dígitos)
Future<String?> pasteVerificationCode()

// ✅ Pegar número de teléfono (9 dígitos)
Future<String?> pastePhoneNumber()

// + 6 funciones más para manejo de portapapeles
```

**Uso**: Auto-pegado inteligente para códigos y teléfonos.

---

#### `lib/core/services/helpers/notification_helpers.dart`
**Propósito**: Configuración de notificaciones como funciones puras

```dart
// ✅ Crear canal Android para SMS
AndroidNotificationChannel createSMSChannel()

// ✅ Crear canal para alertas de viaje
AndroidNotificationChannel createTravelAlertChannel()

// ✅ Crear canal para servicio en background
AndroidNotificationChannel createBackgroundChannel()

// ✅ Obtener todos los canales
List<AndroidNotificationChannel> getAllChannels()

// ✅ Crear detalles de notificación para SMS
AndroidNotificationDetails createSMSNotificationDetails(String code)

// ✅ Crear detalles para alerta de proximidad
AndroidNotificationDetails createProximityAlertDetails(String stopName, int meters)

// ✅ Crear detalles para servicio en background
AndroidNotificationDetails createBackgroundServiceDetails(String text)

// ✅ Formatear código con guión
String formatVerificationCode(String code) // "123456" → "123-456"

// ✅ Generar ID único para notificación
int generateNotificationId()

// ✅ IDs fijos: getSMSNotificationId(), getProximityNotificationId(), etc.
// + 7 funciones más de configuración
```

**Uso**: NotificationService usa estas funciones puras para configuración.

---

### **3. TRIP PLANNER HELPERS (Lógica de Negocio)**

#### `lib/features/trip_planner/data/helpers/route_calculation_helper.dart`
**Propósito**: Cálculos de rutas y scoring

```dart
// ✅ Calcular el scoring de una ruta
double calculateRouteScore({...})

// ✅ Encontrar punto de recogida óptimo
({LatLng point, int index, double distance}) findOptimalPickupPoint(LatLng origin, List<LatLng> routePoints)

// ✅ Encontrar punto de bajada óptimo
({LatLng point, int index, double distance}) findOptimalDropoffPoint(...)

// ✅ Verificar si una ruta es viable
bool isRouteViable({...})

// ✅ Extraer segmento de ruta
List<LatLng> extractRouteSegment(List<LatLng> routePoints, int startIndex, int endIndex)

// ✅ Calcular métricas completas de una ruta
({...})? calculateRouteMetrics({...})

// ✅ Filtrar rutas no viables
List<BusRouteModel> filterViableRoutes({...})

// ✅ Ordenar rutas por score
List<T> sortRoutesByScore<T>(List<T> routes, double Function(T) getScore)

// ✅ Verificar si dos rutas se solapan
bool doRoutesOverlap(...)

// ✅ Calcular tiempo estimado de viaje
double estimateTravelTime({...})
```

**Uso**: Algoritmos de búsqueda de rutas separados en funciones puras.

---

#### `lib/features/trip_planner/data/helpers/geojson_parser_helper.dart`
**Propósito**: Parseo de GeoJSON en funciones atómicas

```dart
// ✅ Cargar y parsear GeoJSON
Future<Map<String, dynamic>> loadGeoJsonFromAssets(String assetPath)

// ✅ Extraer features
List<dynamic> extractFeatures(Map<String, dynamic> geoJsonData)

// ✅ Convertir coordenada a LatLng
LatLng coordinateArrayToLatLng(List<dynamic> coord)

// ✅ Parsear lista de coordenadas
List<LatLng> parseCoordinates(List<dynamic> coordinates)

// ✅ Extraer ID de ruta
String? extractRouteRef(Map<String, dynamic> properties)

// ✅ Determinar dirección (ida/vuelta)
String determineRouteDirection(Map<String, dynamic> properties)

// ✅ Agrupar features por referencia
Map<String, List<Map<String, dynamic>>> groupFeaturesByRef(...)

// ✅ Separar rutas de ida y vuelta
({List<LatLng>? outbound, List<LatLng>? return_}) separateOutboundReturn(...)

// ✅ Validar ruta
bool isValidRoute(List<LatLng>? coordinates)

// ✅ Filtrar rutas inválidas
Map<String, dynamic> filterInvalidRoutes(...)

// ✅ Calcular estadísticas
({int totalRoutes, int withOutbound, ...}) calculateGeoJsonStats(...)

// ✅ Extraer todos los puntos únicos
Set<LatLng> extractAllUniquePoints(...)
```

**Uso**: Cada paso del parseo es una función independiente.

---

### **4. MANAGERS (Coordinadores)**

#### `lib/features/trip_planner/data/managers/route_search_manager.dart`
**Propósito**: Coordinar la búsqueda de rutas usando los helpers

```dart
class RouteSearchManager {
  // ✅ Cargar rutas desde GeoJSON
  Future<void> loadRoutesFromGeoJson(String assetPath)
  
  // ✅ Buscar mejores rutas entre origen y destino
  List<RouteSearchResult> searchBestRoutes({...})
  
  // ✅ Obtener estadísticas
  ({int totalRoutes, int totalPoints}) getStats()
  
  // ✅ Verificar si hay rutas cargadas
  bool get hasRoutes
  
  // ✅ Obtener ruta específica
  BusRouteModel? getRoute(String routeKey)
  
  // ✅ Limpiar rutas
  void clear()
}
```

**Uso**: Orquesta los helpers para resolver el problema completo.

---

### **4. AUTH HELPERS (Lógica de Autenticación)**

#### `lib/features/auth/presentation/helpers/text_formatters.dart`
**Propósito**: Formateo de texto para autenticación

```dart
// ✅ Formatear número de teléfono
String formatPhoneNumber(String phone) // "987654321" → "987-654-321"

// ✅ Formatear código de verificación
String formatVerificationCode(String code) // "123456" → "123-456"

// ✅ Remover guiones
String removeHyphens(String text)

// ✅ Extraer solo dígitos
String extractDigits(String text)

// ✅ Formatear con código de país
String formatPhoneWithCountryCode(String phone, {String countryCode = '+51'})

// ✅ TextInputFormatter para teléfono
class PhoneNumberFormatter extends TextInputFormatter

// ✅ TextInputFormatter para código
class CodeFormatter extends TextInputFormatter

// + 4 funciones factory más
```

**Uso**: Formateo automático mientras el usuario escribe.

---

#### `lib/features/auth/presentation/helpers/auth_validators.dart`
**Propósito**: Validación de formularios

```dart
// ✅ Validar teléfono (9 dígitos)
bool isValidPhone(String? phone)

// ✅ Validar código (6 dígitos)
bool isValidVerificationCode(String? code)

// ✅ Validar email
bool isValidEmail(String? email)

// ✅ Validar contraseña (8+ chars)
bool isValidPassword(String? password)

// ✅ Validar nombre
bool isValidName(String? name)

// ✅ Validadores con mensajes de error
String? validatePhoneWithMessage(String? value)
String? validateCodeWithMessage(String? value)
String? validateEmailWithMessage(String? value)
// + 7 funciones más

// ✅ Validadores de formularios completos
({bool isValid, Map<String, String> errors}) validateLoginForm(String phone)
({bool isValid, Map<String, String> errors}) validateVerificationForm(String code)
({bool isValid, Map<String, String> errors}) validateRegisterForm({...})
```

**Uso**: Funciones puras para validación, fáciles de testear.

---

### **5. CONTROLLERS (Estado y Lógica de UI)**

#### Trip Planner Controller
`lib/features/trip_planner/presentation/controllers/map_controller.dart`
**Propósito**: Manejar todo el estado del mapa

```dart
class MapController extends ChangeNotifier {
  // ✅ Inicializar (obtener ubicación, cargar rutas)
  Future<void> initialize()
  
  // ✅ Configurar controller de Google Maps
  void setMapController(GoogleMapController controller)
  
  // ✅ Tap en el mapa
  void onMapTap(LatLng position)
  
  // ✅ Buscar lugares para origen
  Future<void> searchOriginPlaces(String query)
  
  // ✅ Buscar lugares para destino
  Future<void> searchDestinationPlaces(String query)
  
  // ✅ Seleccionar sugerencia de origen
  Future<void> selectOriginSuggestion(Map<String, dynamic> suggestion)
  
  // ✅ Seleccionar sugerencia de destino
  Future<void> selectDestinationSuggestion(Map<String, dynamic> suggestion)
  
  // ✅ Buscar rutas de buses
  void searchRoutes()
  
  // ✅ Navegar a siguiente ruta
  void nextRoute()
  
  // ✅ Navegar a ruta anterior
  void previousRoute()
  
  // ✅ Reset para nueva búsqueda
  void resetSearch()
}
```

**Uso**: Widget solo llama métodos del controller, no tiene lógica.

---

#### Auth Controller
`lib/features/auth/presentation/controllers/auth_controller.dart`
**Propósito**: Manejar autenticación y verificación

```dart
class AuthController extends ChangeNotifier {
  // ✅ Enviar código de verificación por SMS
  Future<bool> sendVerificationCode(String phone)
  
  // ✅ Reenviar código
  Future<bool> resendVerificationCode()
  
  // ✅ Verificar código ingresado
  Future<bool> verifyCode(String code)
  
  // ✅ Auto-pegar código del portapapeles
  Future<String?> tryPasteCode()
  
  // ✅ Manejo de estado
  void setLoading(bool value)
  void setError(String? message)
  void clearError()
  void reset()
  
  // ✅ Getters de formato
  String getFormattedPhone()
  String getPhoneWithCountryCode()
}
```

**Uso**: Lógica de autenticación centralizada.

---

### **6. WIDGETS (UI Pura)**

#### Trip Planner Widgets
- `search_input_field.dart` - Campo de búsqueda
- `place_suggestions_list.dart` - Lista de sugerencias
- `map_search_bar.dart` - Barra de búsqueda completa
- `map_action_button.dart` - Botón de acción flotante
- `route_info_card.dart` - Card con info de ruta
- `map_loading_overlay.dart` - Overlay de carga
- `route_navigation_controls.dart` - Controles de navegación
- `map_preview.dart` - **193 líneas** (antes 736)

#### Auth Widgets
- `phone_input_field.dart` - Input de teléfono con +51
- `code_input_field.dart` - Input de código centrado
- `auth_logo.dart` - Logo de la aplicación
- `auth_error_message.dart` - Mensaje de error estilizado
- `login_page.dart` - **88 líneas** (antes 250)
- `verify_code_page.dart` - **95 líneas** (antes 300)

**Cada widget hace UNA cosa y la hace bien.**

---

## 💡 CÓMO TRABAJAR CON ESTA ARQUITECTURA

### **Estilo Programación Competitiva**

Cada función tiene:
1. **Un comentario arriba** explicando su propósito único
2. **Input y Output** claramente definidos
3. **Cero dependencias** de estado global (funciones puras donde sea posible)
4. **Nombre descriptivo** que dice exactamente qué hace

### **Ejemplo: Asignar Tarea a un Compañero**

**Tarea**: "Necesito una función que calcule la distancia entre dos coordenadas"

**Compañero implementa**:
```dart
/// Calcular distancia en metros entre dos puntos geográficos
/// Input: dos coordenadas LatLng
/// Output: distancia en metros (double)
double calculateDistance(LatLng point1, LatLng point2) {
  // Implementación
}
```

**Listo**. La función es autocontenida y testeable.

---

## 🎯 BENEFICIOS DE LA REESTRUCTURACIÓN

### ✅ **Modularidad**
- Cada archivo tiene menos de 300 líneas
- Funciones independientes y reutilizables

### ✅ **Testabilidad**
- Funciones puras fáciles de testear
- Sin mocks complejos (la mayoría son funciones puras)

### ✅ **Mantenibilidad**
- Bug en cálculo de distancia? → `geometry_utils.dart`
- Bug en búsqueda de lugares? → `places_api_helper.dart`
- Un archivo = una responsabilidad

### ✅ **Trabajo en Equipo**
```
📁 Dividir trabajo:
  - Persona A: Implementar funciones de geometry_utils.dart
  - Persona B: Implementar funciones de geolocation_helper.dart
  - Persona C: Crear widgets de UI
  - Persona D: Integrar todo en el controller
```

### ✅ **Escalabilidad**
- Agregar nueva funcionalidad? → Nueva función en el helper apropiado
- Nuevo tipo de marcador? → Nueva función en `map_marker_factory.dart`
- Nuevos cálculos? → Nueva función en `route_calculation_helper.dart`

---

## 📦 ARCHIVOS ELIMINADOS/REEMPLAZADOS

| Archivo Original | Estado | Reemplazado Por |
|-----------------|--------|-----------------|
| `map_preview.dart` (736 líneas) | ✅ Refactorizado | `map_preview.dart` (193 líneas) + 6 widgets + 1 controller |
| Lógica en `geojson_parser_service.dart` | ✅ Modularizado | `geojson_parser_helper.dart` + `route_calculation_helper.dart` |
| Lógica de GPS mezclada | ✅ Separado | `geolocation_helper.dart` |
| Llamadas API mezcladas | ✅ Separado | `places_api_helper.dart` |

---

## 🚀 PRÓXIMOS PASOS

1. **Aplicar mismo patrón a AUTH module**
2. **Refactorizar LIVE_TRACKING** con helpers separados
3. **Crear tests unitarios** para cada helper (fácil porque son funciones puras)
4. **Documentar cada módulo** con ejemplos de uso

---

## 📚 ESTRUCTURA FINAL

```
lib/
├── core/
│   ├── utils/
│   │   ├── geometry_utils.dart        ✅ 10 funciones puras
│   │   ├── map_marker_factory.dart    ✅ 8 funciones factory
│   │   └── map_polyline_factory.dart  ✅ 7 funciones factory
│   └── services/
│       ├── geolocation_helper.dart    ✅ 11 funciones de GPS
│       └── places_api_helper.dart     ✅ 6 funciones de API
│
├── features/trip_planner/
│   ├── data/
│   │   ├── helpers/
│   │   │   ├── route_calculation_helper.dart  ✅ 10 funciones de cálculo
│   │   │   └── geojson_parser_helper.dart     ✅ 13 funciones de parseo
│   │   └── managers/
│   │       └── route_search_manager.dart       ✅ Coordinador
│   │
│   └── presentation/
│       ├── controllers/
│       │   └── map_controller.dart             ✅ Estado + lógica
│       └── widgets/
│           ├── map_preview.dart                ✅ 193 líneas (era 736)
│           ├── search_input_field.dart         ✅ Widget puro
│           ├── place_suggestions_list.dart     ✅ Widget puro
│           ├── map_search_bar.dart             ✅ Widget puro
│           ├── map_action_button.dart          ✅ Widget puro
│           ├── route_info_card.dart            ✅ Widget puro
│           ├── map_loading_overlay.dart        ✅ Widget puro
│           └── route_navigation_controls.dart  ✅ Widget puro
```

---

**Total**: ~65 funciones modulares, cada una con un propósito único y claramente documentado. 🎉
