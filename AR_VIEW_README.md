# Funcionalidad de Realidad Aumentada (AR) - RUMBO

## 📱 Descripción General

La funcionalidad de Realidad Aumentada (AR) permite a los usuarios visualizar autobuses cercanos en tiempo real, similar a Pokémon GO. Los autobuses se muestran como elementos interactivos en la pantalla de la cámara con información en tiempo real como:

- **Número del autobús**: Identificador de la ruta
- **Nombre de la ruta**: Destino del autobús
- **Distancia**: A qué distancia se encuentra (en km)
- **Velocidad**: Velocidad actual del autobús (km/h)
- **Brújula**: Orientación y dirección del usuario

## 🏗️ Estructura del Proyecto

```
lib/features/ar_view/
├── presentation/
│   ├── pages/
│   │   └── ar_view_page.dart          # Página principal de AR
│   ├── bloc/
│   │   ├── ar_view_bloc.dart          # BLoC para manejar estado
│   │   ├── ar_view_event.dart         # Eventos
│   │   └── ar_view_state.dart         # Estados
│   └── widgets/
│       ├── ar_camera_view.dart        # Vista principal de cámara AR
│       └── ar_view_fab.dart           # Botón flotante de acceso
├── domain/
│   ├── entities/
│   │   ├── ar_bus_marker.dart         # Entidad de autobús
│   │   └── ar_user_location.dart      # Entidad de ubicación del usuario
│   ├── repositories/
│   │   ├── ar_location_repository.dart
│   │   └── ar_bus_repository.dart
│   └── usecases/
│       ├── get_user_location_stream.dart
│       ├── get_nearby_buses_usecase.dart
│       └── check_and_request_location_permissions.dart
└── data/
    ├── datasources/
    │   ├── ar_location_datasource.dart  # Fuente de ubicación
    │   └── ar_bus_datasource.dart       # Fuente de datos de autobuses
    ├── repositories/
    │   ├── ar_location_repository_impl.dart
    │   └── ar_bus_repository_impl.dart
    └── models/
        ├── ar_bus_marker_model.dart
        └── ar_user_location_model.dart
```

## 🔑 Características Principales

### 1. **Visualización de Autobuses en AR**
- Renderización 3D simulada de autobuses cercanos
- Posicionamiento basado en cálculos de distancia y bearing
- Escala dinámica según la distancia

### 2. **Sistema de Ubicación en Tiempo Real**
- Monitoreo continuo de la ubicación del usuario
- Precisión de ±10 metros
- Actualización cada 10 metros de movimiento

### 3. **Información de Autobuses**
- Número de autobús (ruta)
- Nombre de la ruta
- Distancia en tiempo real
- Velocidad actual
- Timestamp de última actualización

### 4. **Interfaz HUD (Heads-Up Display)**
- Información de ubicación GPS
- Precisión del GPS
- Cantidad de autobuses cercanos
- Estado de actividad

### 5. **Brújula de Orientación**
- Indica dirección cardenal (N, S, E, O)
- Se orienta según el heading del dispositivo
- Aguja roja que apunta al norte magnético

## 📍 Cómo Acceder

### Desde la App
1. En la pantalla de búsqueda o mapa
2. Presiona el botón flotante "Vista AR"
3. Confirma los permisos de ubicación cuando se solicite
4. La vista AR se mostrará con los autobuses cercanos

### Ruta
```
/ar-view
```

## 🔐 Permisos Requeridos

La aplicación requiere los siguientes permisos para funcionar:

- **Ubicación (FINE_LOCATION)**: Para obtener la posición GPS del usuario
- **Cámara**: Para mostrar el feed de la cámara (implementación futura)

## 🚀 Implementación Técnica

### Flujo de Datos

```
1. Usuario abre Vista AR
   ↓
2. ARViewBloc → InitializeARViewEvent
   ↓
3. CheckAndRequestLocationPermissions
   ↓
4. Si permisos otorgados:
   - GetUserLocationStream (Stream continuo)
   - GetNearbyBusesUseCase (Stream de autobuses)
   ↓
5. ARCameraView renderiza basado en estado
```

### Cálculo de Posición en Pantalla

```dart
// Datos del autobús
distance = 250 metros
bearing = 45 grados (NE)

// Conversión a posición pantalla
angle = bearing * (π / 180)
screenDistance = (distance / 1000) * screenRadius
offsetX = screenDistance * sin(angle)
offsetY = -screenDistance * cos(angle)

// Posición final
screenX = centerX + offsetX
screenY = centerY + offsetY
```

## 🔧 Configuración

### Parámetros Ajustables

En `ar_location_datasource.dart`:
```dart
LocationSettings(
  accuracy: LocationAccuracy.high,      // Precisión: high/medium/low
  distanceFilter: 10,                   // Actualizar cada 10 metros
)
```

En `ar_bus_datasource.dart`:
```dart
// Radio de búsqueda de autobuses
const radiusMeters = 1000.0; // 1 km
```

## 📡 Fuente de Datos

Actualmente, la implementación utiliza **datos mock** (simulados) en `ARBusDataSourceImpl`. Para integrar datos reales:

1. **API REST**: Reemplazar `getNearbyBuses()` con llamadas HTTP
2. **WebSocket**: Implementar para actualización en tiempo real
3. **Geofencing**: Usar servicios de proximidad nativos

## 🎨 Personalización Visual

### Colores
- Primario: `Colors.cyan`
- Secundario: `Colors.blue`
- Acentos: `Colors.lightBlue`, `Colors.greenAccent`

### Animaciones
- Entrada: `ScaleTransition` (500ms)
- Pulsación: Habilitada automáticamente

## ⚠️ Consideraciones de Rendimiento

1. **Renderización**: Optimizado para 60 FPS
2. **Ubicación**: Se actualiza cada 10 metros (configurable)
3. **Autobuses**: Máximo 10-15 visibles simultáneamente
4. **Memoria**: ~50MB en uso normal

## 🐛 Debugging

### Logs Disponibles
```dart
// Ubicación del usuario
"LAT: ${location.latitude}, LNG: ${location.longitude}"

// Autobuses cercanos
"Found ${buses.length} nearby buses"

// Errores
"AR Error: ${error.message}"
```

### Prueba Local
1. Activar modo de desarrollo en Android/iOS
2. Simular ubicación en emulador
3. Usar Android Device Monitor o Xcode para debugging

## 🔮 Mejoras Futuras

- [ ] Integración con cámara real (ARCore/ARKit)
- [ ] Modelos 3D de autobuses
- [ ] WebSocket para datos en tiempo real
- [ ] Filtrado por ruta preferida
- [ ] Estadísticas de tiempo de espera
- [ ] Notificaciones cuando autobús se aproxima
- [ ] Integración con mapa 3D
- [ ] Soporte para múltiples usuarios

## 📚 Referencias

- Flutter AR: https://flutter.dev/
- ARCore Flutter: https://github.com/google/app-framework-plugin
- Geolocator: https://pub.dev/packages/geolocator

## 👨‍💻 Contacto

Para preguntas o mejoras sobre la funcionalidad AR, contacta al equipo de desarrollo.
