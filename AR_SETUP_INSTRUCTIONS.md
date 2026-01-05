# 🎯 Guía de Instalación - Funcionalidad AR

## ✅ Pasos Completados

Se ha implementado exitosamente una funcionalidad de **Realidad Aumentada (AR)** similar a Pokémon GO para visualizar paraderos/autobuses en tiempo real.

## 📦 Dependencias Utilizadas

El proyecto utiliza las siguientes dependencias existentes y nuevas:

- **geolocator**: ^11.0.0 - Para obtener ubicación GPS en tiempo real
- **google_maps_flutter**: ^2.9.0 - Para visualización de mapas
- **flutter_bloc**: ^8.1.6 - Para gestión de estado

**No se agregaron dependencias externas de AR complejas** ya que la implementación utiliza:
- CustomPaint para renderizado de elementos AR
- Cálculos matemáticos para posicionamiento 3D
- Canvas para gráficos 2D

En el futuro, para **AR real** con cámara se pueden agregar:
- `arcore_flutter_plugin` - Para ARCore en Android
- `model_viewer_plus` - Para visualizar modelos 3D

### Para instalar las dependencias:

```bash
flutter pub get
```

## 📁 Estructura Creada

### Feature: `ar_view`

**Ubicación**: `lib/features/ar_view/`

```
ar_view/
├── presentation/
│   ├── pages/
│   │   └── ar_view_page.dart
│   ├── widgets/
│   │   ├── ar_camera_view.dart
│   │   └── ar_view_fab.dart
│   └── bloc/
│       ├── ar_view_bloc.dart
│       ├── ar_view_event.dart
│       └── ar_view_state.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── data/
    ├── datasources/
    ├── repositories/
    └── models/
```

## 🚀 Cómo Usar

### 1. Agregar el botón AR en tu página

En cualquier página donde quieras agregar acceso a la vista AR:

```dart
import 'features/ar_view/presentation/widgets/ar_view_fab.dart';

Scaffold(
  floatingActionButton: ARViewFAB(),
  // ... resto del widget
)
```

O navega directamente:
```dart
context.push('/ar-view');
```

### 2. Permisos Necesarios

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
```

Estos permisos se solicitan en tiempo de ejecución usando `permission_handler`.

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrar los autobuses cercanos en la vista AR</string>
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para la vista AR</string>
```

### 3. Configuración en `injection_container.dart`

✅ **Ya está configurada** - Se han registrado todas las dependencias:

- DataSources (ARLocationDataSource, ARBusDataSource)
- Repositories (ARLocationRepository, ARBusRepository)
- UseCases (GetUserLocationStream, GetNearbyBusesUseCase, etc.)
- BLoCs (ARViewBloc)

### 4. Ruta en `app.dart`

✅ **Ya está agregada** - La ruta `/ar-view` está disponible:

```dart
GoRoute(
  path: '/ar-view',
  builder: (context, state) => const ARViewPage(),
),
```

## 🎮 Características Implementadas

### Vista AR
- ✅ Cuadrícula de referencia AR
- ✅ Marcadores de autobuses posicionados en 3D
- ✅ Información en tiempo real (número, ruta, distancia, velocidad)
- ✅ Brújula de orientación
- ✅ Panel HUD con información del usuario
- ✅ Lista de autobuses cercanos
- ✅ Animaciones suave de entrada

### Sistema de Ubicación
- ✅ Monitoreo continuo de ubicación del usuario
- ✅ Solicitud automática de permisos
- ✅ Cálculo de distancia y bearing
- ✅ Precisión de GPS

### Gestión de Estado
- ✅ BLoC para manejo de estado
- ✅ Streams para actualizaciones en tiempo real
- ✅ Manejo de errores

## 📊 Datos Mock

Actualmente, la aplicación utiliza **datos simulados** para mostrar autobuses cercanos. Para integrar datos reales:

### Opción 1: API REST

En `ar_bus_datasource.dart`, modifica `getNearbyBuses()`:

```dart
@override
Future<List<ARBusMarkerModel>> getNearbyBuses(
  double userLat,
  double userLng,
  double radiusMeters,
) async {
  final response = await http.get(
    Uri.parse('https://api.tuserver.com/buses?lat=$userLat&lng=$userLng&radius=$radiusMeters')
  );
  
  final List<dynamic> jsonData = jsonDecode(response.body);
  return jsonData.map((bus) => ARBusMarkerModel.fromJson(bus)).toList();
}
```

### Opción 2: WebSocket (Tiempo Real)

Para actualizaciones más rápidas:

```dart
@override
Stream<List<ARBusMarkerModel>> monitorNearbyBuses(
  double userLat,
  double userLng,
  double radiusMeters,
) {
  // Conectar a WebSocket y emitir datos
}
```

## 🔧 Configuración Personalizable

### En `ar_location_datasource.dart`:
```dart
// Ajustar precisión y frecuencia de actualización
LocationSettings(
  accuracy: LocationAccuracy.high,    // high, medium, low
  distanceFilter: 10,                 // metros entre actualizaciones
)
```

### En `ar_view_page.dart`:
```dart
// Radio de búsqueda de autobuses (en metros)
const radiusMeters = 1000.0; // 1 km
```

### En `ar_camera_view.dart`:
```dart
// Colores y estilos
gradient: LinearGradient(
  colors: [Colors.blue.shade400, Colors.cyan],
),
```

## ✨ Próximos Pasos Recomendados

1. **Integrar datos reales**: Conectar con tu API de autobuses
2. **Mejorar visualización**: Implementar cámara real con ARCore/ARKit
3. **Agregar modelos 3D**: Usar paquetes como `model_viewer_plus`
4. **WebSocket en tiempo real**: Para actualizaciones más rápidas
5. **Notificaciones**: Alertar cuando un autobús se acerca
6. **Estadísticas**: Tiempo de llegada estimado

## 🧪 Testing Local

Para probar sin datos reales:

1. El emulador muestra datos mock
2. Los datos se actualizan cada 2 segundos
3. Prueba navegando alrededor de una ubicación simulada
4. Verifica que los autobuses cambien de posición

## 📚 Archivos de Referencia

- **Documentación completa**: `AR_VIEW_README.md`
- **Ejemplo de integración**: `AR_INTEGRATION_EXAMPLE.dart`
- **Este archivo**: `AR_SETUP_INSTRUCTIONS.md`

## 🆘 Troubleshooting

### "Permisos de ubicación denegados"
- Verifica que los permisos estén solicitados en AndroidManifest.xml
- En iOS, revisa Info.plist
- Acepta los permisos cuando se solicite

### "No aparecen autobuses"
- Verifica que estés usando coordenadas dentro del rango mock
- Comprueba que los permisos se hayan otorgado
- Revisa la consola de Flutter para errores

### "Rendimiento lento"
- Reduce la cantidad de autobuses mostrados
- Aumenta el `distanceFilter` (10m → 50m)
- Usa `LocationAccuracy.medium` en lugar de `high`

## 📞 Soporte

Para problemas o preguntas sobre la implementación AR, revisa:
- `AR_VIEW_README.md` - Documentación técnica detallada
- `AR_INTEGRATION_EXAMPLE.dart` - Ejemplos de uso

---

**Estado**: ✅ Implementación completa y funcional
**Última actualización**: 2024
**Versión de Flutter**: 3.2.0+
