# Función de Paraderos Inteligentes con AR

## Descripción

La nueva funcionalidad permite generar y visualizar **3 tipos de paraderos inteligentes** para cada ruta de autobús seleccionada:

1. **📍 El Más Cercano** - El paradero más próximo a tu ubicación actual
2. **🚗 Evita Tráfico** - Una alternativa que reduce congestión vial
3. **🪑 Asientos Garantizados** - Maximiza probabilidad de conseguir asiento

## Características

### Generación Inteligente de Paraderos
- Se generan 3 paraderos por cada ruta seleccionada
- Posicionados estratégicamente a lo largo de la ruta
- Cada uno tiene datos simulados pero realistas:
  - Distancia de caminata
  - Tiempo de espera estimado
  - Tiempo de viaje en bus
  - Nivel de ocupación
  - Asientos disponibles

### Visualización en AR (Simulada)
- Vista inmersiva tipo cámara con fondo degradado azul
- Cada paradero se muestra como un card flotante
- Indicadores de dirección (brújula) y distancia
- Sistema de páginas para navegar entre paraderos

### Información Detallada
- Razón específica por la que se recomienda cada paradero
- Métricas visuales: tiempo, distancia, asientos, ocupación
- Score de conveniencia calculado automáticamente

## Archivos Creados

### Modelos
```
lib/features/trip_planner/data/models/smart_bus_stop_model.dart
```
Define la estructura de un paradero inteligente con sus propiedades.

### Servicios
```
lib/features/trip_planner/data/services/smart_bus_stops_service.dart
```
Servicio que genera los 3 paraderos para una ruta dada.

### Presentación
```
lib/features/trip_planner/presentation/pages/route_detail_page.dart
lib/features/trip_planner/presentation/widgets/smart_stops_ar_view.dart
```
Interfaz de usuario para mostrar los paraderos (normal y AR).

## Uso

### Integrar en tu pantalla actual

```dart
// Ejemplo de cómo usar desde otra pantalla
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'features/trip_planner/presentation/pages/route_detail_page.dart';

// Navegar a la página de detalle
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => RouteDetailPage(
      route: selectedRoute, // Tu modelo BusRouteModel
      userLocation: LatLng(-16.3994, -71.5350), // Ubicación del usuario
      routeRef: '4A', // Referencia de la ruta (ej: "4A", "3B", etc)
    ),
  ),
);
```

### Generar paraderos manualmente

```dart
import 'features/trip_planner/data/services/smart_bus_stops_service.dart';

final smartStops = SmartBusStopsService.generateSmartStops(
  userLocation: LatLng(-16.3994, -71.5350),
  route: myRoute,
  routeRef: '4A',
);

// smartStops es una lista con 3 elementos
for (var stop in smartStops) {
  print('${stop.type.displayName}: ${stop.name}');
  print('  - Razón: ${stop.reason}');
  print('  - Caminar: ${stop.walkingDistance}m');
  print('  - Esperar: ${stop.estimatedWaitTime}min');
}
```

## Tipos de Paradas

### 1. El Más Cercano (nearest)
- **Emoji**: 📍
- **Color**: Azul
- **Características**:
  - Ubicado en el punto más cercano de la ruta al usuario
  - Distancia de caminata minimizada
  - Baja congestión esperada
  - Ideal para usuarios que quieren caminar poco

### 2. Evita Tráfico (avoidTraffic)
- **Emoji**: 🚗
- **Color**: Naranja
- **Características**:
  - Ubicado en punto medio de la ruta
  - Evita avenidas principales congestionadas
  - Congestión media pero con viaje rápido
  - Ideal para horas pico

### 3. Asientos Garantizados (guaranteedSeats)
- **Emoji**: 🪑
- **Color**: Verde
- **Características**:
  - Ubicado al final de la ruta (terminal)
  - Muy baja probabilidad de ir de pie
  - Más asientos disponibles
  - Ideal para viajes largos donde se espera estar cómodo

## Propiedades de cada Paradero

```dart
class SmartBusStopModel {
  final String id;                    // ID único
  final String name;                  // Nombre del paradero
  final LatLng location;               // Coordenadas geográficas
  final SmartStopType type;            // Tipo (nearest, avoidTraffic, guaranteedSeats)
  final double walkingDistance;        // Metros a caminar
  final double estimatedBusDistance;   // Metros en bus
  final int estimatedWaitTime;         // Minutos esperando bus
  final int estimatedTravelTime;       // Minutos en bus
  final double crowdLevel;             // 0.0 (vacío) a 1.0 (lleno)
  final int estimatedAvailableSeats;   // Número de asientos
  final String reason;                 // Por qué es recomendado
  final List<String> routes;           // Rutas que pasan por aquí
}
```

## Cálculos

### Score de Conveniencia
```
score = (distancia/1000 × 0.4) + 
        (tiempo/30 × 0.3) + 
        (congestión × 0.2) + 
        ((10-asientos)/10 × 0.1)
```
Valor más bajo = mejor opción

## Datos Simulados

Todos los datos son simulados de forma realista:
- Distancias: Basadas en Haversine entre puntos reales
- Tiempos: Números aleatorios dentro de rangos realistas
- Congestión: Diferente para cada tipo de paradero
- Asientos: Correlacionados con nivel de ocupación

## Mejoras Futuras

- [ ] Integrar datos reales de ocupación de buses
- [ ] Predicción de tráfico en tiempo real
- [ ] Historial de selección de paraderos
- [ ] Calificación de paraderos por usuarios
- [ ] Integración con Google Maps real
- [ ] Notificaciones cuando el bus se acerca
- [ ] Pago directo desde la app

## Notas Técnicas

- Los paraderos se generan dinámicamente, no son datos estáticos
- Cada vez que se abre la ruta se generan nuevos paraderos
- Compatible con rutas de una sola dirección o circuitos cerrados
- Los cálculos de distancia usan la fórmula Haversine
- El AR es una simulación visual, no requiere librerías especiales
