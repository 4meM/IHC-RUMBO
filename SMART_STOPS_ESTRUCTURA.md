# Estructura de Archivos - Paraderos Inteligentes

## Archivos Nuevos Creados

```
lib/
└── features/
    └── trip_planner/
        ├── data/
        │   ├── models/
        │   │   └── smart_bus_stop_model.dart        ✨ NUEVO
        │   └── services/
        │       └── smart_bus_stops_service.dart     ✨ NUEVO
        └── presentation/
            ├── pages/
            │   └── route_detail_page.dart           ✏️ MODIFICADO (NUEVO CONTENIDO)
            └── widgets/
                └── smart_stops_ar_view.dart         ✨ NUEVO

Raíz del Proyecto:
├── SMART_STOPS_GUIA.md                     ✨ NUEVO
└── SMART_STOPS_INTEGRACION.dart            ✨ NUEVO
```

## Descripción de Archivos

### 1. `smart_bus_stop_model.dart` 📊
**Ubicación**: `lib/features/trip_planner/data/models/`

Define la estructura de datos de una parada inteligente:
- Propiedades de ubicación (latitud, longitud)
- Tipo de parada (nearest, avoidTraffic, guaranteedSeats)
- Métricas (distancia a caminar, tiempo de espera, asientos, etc.)
- Métodos helper (formateo, scores, JSON)

**Dependencias**: google_maps_flutter

### 2. `smart_bus_stops_service.dart` ⚙️
**Ubicación**: `lib/features/trip_planner/data/services/`

Servicio que genera los 3 paraderos inteligentes:
- `generateSmartStops()` - Método principal que crea 3 paradas
- Cálculo de distancias Haversine
- Distribución de paradas a lo largo de la ruta
- Asignación de datos simulados realistas

**Dependencias**: google_maps_flutter, smart_bus_stop_model, bus_route_model

### 3. `route_detail_page.dart` 📱
**Ubicación**: `lib/features/trip_planner/presentation/pages/`

Pantalla principal que muestra:
- Información de la ruta seleccionada
- Cards con los 3 paraderos recomendados
- Botón para entrar a vista AR
- Navegación entre vistas normal/AR

**Dependencias**: flutter, google_maps_flutter, smart_stops_ar_view, smart_bus_stops_service

### 4. `smart_stops_ar_view.dart` 🎥
**Ubicación**: `lib/features/trip_planner/presentation/widgets/`

Widget de vista AR que simula una cámara mostrando:
- Fondo degradado azul (simulación de cielo)
- Cards flotantes con información de paradas
- Sistema de swipe/página para navegar
- Indicadores de dirección (brújula) y distancia
- Panel inferior con detalles completos

**Dependencias**: flutter, google_maps_flutter, smart_bus_stop_model

---

## Diagrama de Flujo

```
🏠 Pantalla Principal
     ↓
🔍 Usuario busca ruta (origen → destino)
     ↓
📍 Sistema muestra lista de rutas
     ↓
👆 Usuario selecciona una ruta
     ↓
📄 RouteDetailPage
     ├─→ Genera 3 paraderos con SmartBusStopsService
     ├─→ Muestra cards con paraderos
     └─→ Botón "Ver en AR"
          ↓
     🎥 SmartStopsARView
          ├─→ Vista tipo cámara (fondo azul)
          ├─→ Swipe entre los 3 paraderos
          ├─→ Dirección y distancia en tiempo real
          └─→ Detalles en panel inferior
               ↓
          ✅ Usuario selecciona paradero
```

## Flujo de Datos

```
RouteDetailPage
    ↓
SmartBusStopsService.generateSmartStops()
    ↓
[SmartBusStopModel, SmartBusStopModel, SmartBusStopModel]
    ↓
SmartStopsARView
    ↓
UI renderizada (cards, métricas, botones)
```

## Relaciones entre Archivos

```
┌─────────────────────────────────────────────────────┐
│          route_detail_page.dart                     │
│  (Orquesta todo, es el punto de entrada)            │
└────────┬──────────────┬──────────────┬──────────────┘
         │              │              │
         ↓              ↓              ↓
    Uses:          Uses:          Uses:
    SmartBus       SmartStops      SmartStops
    StopsService  ARView          Service
         │              │              │
    ┌────┴──────────────┴──────────────┴───────────┐
    ↓                                                ↓
SmartBusStopModel              SmartBusStopsService
(Estructura de datos)          (Generación de datos)
    ↓
Propiedades:                   Métodos:
- id, name, location          - generateSmartStops()
- type, distance              - _findNearestPoint()
- crowdLevel, seats           - _calculateDistance()
- reason, routes
```

## Importaciones Necesarias

```dart
// En route_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/bus_route_model.dart';
import '../../data/models/smart_bus_stop_model.dart';
import '../../data/services/smart_bus_stops_service.dart';
import '../widgets/smart_stops_ar_view.dart';

// En smart_stops_ar_view.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as Math;
import '../../data/models/smart_bus_stop_model.dart';

// En smart_bus_stops_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as Math;
import '../models/smart_bus_stop_model.dart';
import '../models/bus_route_model.dart';

// En smart_bus_stop_model.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
```

## Cómo Conectar con tu Código Actual

### Paso 1: Importa en tu MapPreview
```dart
import 'pages/route_detail_page.dart';
```

### Paso 2: Al hacer tap en una ruta
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => RouteDetailPage(
      route: selectedRoute,
      userLocation: userLocation,
      routeRef: routeRef,
    ),
  ),
);
```

### Paso 3: ¡Listo!
La pantalla RouteDetailPage automáticamente:
- Genera los 3 paraderos
- Los muestra en cards
- Permite vista AR
- Maneja toda la interacción

---

## Estadísticas del Código

| Archivo | Líneas | Responsabilidad |
|---------|--------|-----------------|
| smart_bus_stop_model.dart | ~120 | Modelo de datos |
| smart_bus_stops_service.dart | ~140 | Lógica de generación |
| route_detail_page.dart | ~350 | UI principal |
| smart_stops_ar_view.dart | ~380 | Vista AR simulada |
| **Total** | **~990** | **Completa feature** |

---

## Colores y Estilos

### Colores por Tipo de Parada
- **Nearest (Azul)**: #2196F3
- **AvoidTraffic (Naranja)**: #FF9800
- **GuaranteedSeats (Verde)**: #4CAF50

### Emojis
- 📍 El más cercano
- 🚗 Evita tráfico
- 🪑 Asientos garantizados

### Iconos Utilizados
- directions_walk → Caminata
- directions_bus → Viaje en bus
- schedule → Tiempo de espera
- event_seat → Asientos
- camera_alt → Ver en AR
- lightbulb → Razón de recomendación

---

## Next Steps (Próximos Pasos)

1. **Prueba la integración**: Navega a una ruta y verifica que aparezcan los 3 paraderos
2. **Personaliza datos**: Modifica los ranges en generateSmartStops() si es necesario
3. **Integra con tu lógica**: Conecta con tus servicios de ubicación y rutas
4. **Agrega persistencia**: Guarda paraderos seleccionados en base de datos
5. **Real-time updates**: Conecta con APIs reales de tráfico y ocupación

---

## Troubleshooting

### Los paraderos no aparecen
- Verifica que la ruta tenga coordenadas válidas
- Revisa que userLocation sea un LatLng válido

### AR no se ve bien
- Aumenta/disminuye el tamaño de los containers en smart_stops_ar_view.dart
- Ajusta los colores en _getStopTypeColor()

### Errores de compilación
- Asegúrate de importar google_maps_flutter
- Verifica que BusRouteModel tenga la propiedad `coordinates`

