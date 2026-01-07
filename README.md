# 🚀 RUMBO - Transporte Público Arequipa

## ✨ ARQUITECTURA COMPLETAMENTE REESTRUCTURADA (Enero 2026)

Este proyecto ha sido **completamente refactorizado** aplicando principios SOLID y Clean Code, convirtiendo **736 líneas monolíticas** en **65+ funciones modulares** estilo programación competitiva.

---

## 📚 DOCUMENTACIÓN PRINCIPAL

### **🎯 COMIENZA AQUÍ**
1. **[RESUMEN_REESTRUCTURACION.md](RESUMEN_REESTRUCTURACION.md)** - Qué se cambió y por qué
2. **[ARQUITECTURA_MODULAR.md](ARQUITECTURA_MODULAR.md)** - Guía completa de la nueva arquitectura
3. **[EJEMPLOS_DE_USO.dart](EJEMPLOS_DE_USO.dart)** - 12 ejemplos prácticos de código
4. **[INDICE_FUNCIONES.md](INDICE_FUNCIONES.md)** - Índice de las 89 funciones creadas

---

## 🏗️ ESTRUCTURA DEL PROYECTO

```
lib/
├── core/
│   ├── utils/                    ← 🔧 FUNCIONES PURAS
│   │   ├── geometry_utils.dart           (10 funciones geométricas)
│   │   ├── map_marker_factory.dart       (8 funciones de marcadores)
│   │   └── map_polyline_factory.dart     (7 funciones de polylines)
│   │
│   └── services/                 ← 🌐 SERVICIOS EXTERNOS
│       ├── geolocation_helper.dart       (11 funciones GPS)
│       └── places_api_helper.dart        (6 funciones Google Places)
│
├── features/
│   └── trip_planner/
│       ├── data/
│       │   ├── helpers/          ← 📐 LÓGICA DE NEGOCIO
│       │   │   ├── route_calculation_helper.dart    (10 funciones)
│       │   │   └── geojson_parser_helper.dart       (12 funciones)
│       │   │
│       │   └── managers/         ← 🎯 COORDINADORES
│       │       └── route_search_manager.dart        (1 manager)
│       │
│       └── presentation/
│           ├── controllers/      ← 🎮 ESTADO
│           │   └── map_controller.dart              (1 controller)
│           │
│           └── widgets/          ← 🎨 UI COMPONENTES
│               ├── map_preview.dart                 (193 líneas, era 736)
│               ├── search_input_field.dart
│               ├── place_suggestions_list.dart
│               ├── map_search_bar.dart
│               ├── map_action_button.dart
│               ├── route_info_card.dart
│               ├── map_loading_overlay.dart
│               └── route_navigation_controls.dart
│
└── shared/                       ← 🔗 COMPARTIDO ENTRE FEATURES
```

---

## 🎯 PRINCIPIOS APLICADOS

### **1. Funciones Puras Estilo Programación Competitiva**
```dart
/// Calcular distancia en metros entre dos puntos geográficos
/// Input: dos coordenadas LatLng
/// Output: distancia en metros (double)
double calculateDistance(LatLng point1, LatLng point2) {
  // Una función = un problema
  // Input definido → Procesamiento → Output predecible
}
```

### **2. Single Responsibility Principle**
- Cada función hace **UNA cosa**
- Cada archivo tiene **UNA responsabilidad**
- Cada widget renderiza **UN componente**

### **3. Separation of Concerns**
```
UI (Widgets)
  ↓
Controller (Estado)
  ↓
Manager (Coordinación)
  ↓
Helpers (Lógica pura)
  ↓
Services (APIs externas)
```

### **4. Factory Pattern**
```dart
final marker = createOriginMarker(position); // ✅ Fácil
final polyline = createBusRoutePolyline(id, points); // ✅ Consistente
```

---

## 🚀 CÓMO EMPEZAR

### **1. Instalar dependencias**
```bash
flutter pub get
```

### **2. Revisar documentación**
```bash
# Lee primero:
RESUMEN_REESTRUCTURACION.md    # Qué cambió
ARQUITECTURA_MODULAR.md        # Cómo está organizado
EJEMPLOS_DE_USO.dart          # Cómo usar las funciones
```

### **3. Explorar el código**
```dart
// Ejemplo: Calcular distancia
import 'lib/core/utils/geometry_utils.dart';

final distancia = calculateDistance(puntoA, puntoB);
print(formatDistance(distancia)); // "1.2km"
```

---

## 💡 CASOS DE USO COMUNES

### **📍 Obtener ubicación actual**
```dart
import 'lib/core/services/geolocation_helper.dart';

final result = await getLocationSafely();
if (result.error == null) {
  print('Ubicación: ${result.location}');
}
```

### **🔍 Buscar lugares**
```dart
import 'lib/core/services/places_api_helper.dart';

final lugares = await searchPlacesInArequipa('Plaza de Armas');
```

### **📏 Calcular distancias**
```dart
import 'lib/core/utils/geometry_utils.dart';

final distancia = calculateDistance(origen, destino);
final texto = formatDistance(distancia); // "1.5km"
```

### **📌 Crear marcadores**
```dart
import 'lib/core/utils/map_marker_factory.dart';

final markers = createOriginDestinationMarkers(origen, destino);
```

### **🚍 Buscar rutas de buses**
```dart
import 'lib/features/trip_planner/data/managers/route_search_manager.dart';

final manager = RouteSearchManager();
await manager.loadRoutesFromGeoJson('assets/buses.geojson');
final rutas = manager.searchBestRoutes(
  origin: origen,
  destination: destino,
);
```

---

## 📊 ESTADÍSTICAS DE MEJORA

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| **map_preview.dart** | 736 líneas | 193 líneas | **74% ↓** |
| **Funciones modulares** | 0 | 89 | ∞ |
| **Archivos helpers** | 3 | 20+ | **Mejor organización** |
| **Testabilidad** | 🔴 Difícil | 🟢 Fácil | **Funciones puras** |
| **Trabajo en equipo** | 🔴 Conflictos | 🟢 Paralelo | **Sin merge issues** |
| **Mantenibilidad** | 🔴 Complicado | 🟢 Simple | **Un archivo = una responsabilidad** |

---

## 🎓 CÓMO TRABAJAR CON ESTA ARQUITECTURA

### **Para agregar nueva funcionalidad**
1. Identifica la capa apropiada (Utils, Services, Helpers)
2. Crea función pura con comentario descriptivo
3. Prueba la función de forma aislada
4. Intégrala en el Manager/Controller
5. Expón en el Widget

### **Para asignar tareas a compañeros**
```dart
// TAREA: Implementar cálculo de área de polígono
// Input: Lista de puntos que forman el polígono
// Output: Área en metros cuadrados
// Archivo: lib/core/utils/geometry_utils.dart

double calculatePolygonArea(List<LatLng> points) {
  // TODO: Tu compañero implementa esto
}
```

### **Para encontrar bugs**
```
Bug en cálculo de distancia?
  → lib/core/utils/geometry_utils.dart línea 8
  → Función: calculateDistance()
```

---

## 🧪 TESTING (Próximo paso)

Gracias a la arquitectura modular, es fácil escribir tests:

```dart
test('calculateDistance debe retornar distancia correcta', () {
  final resultado = calculateDistance(
    LatLng(-16.409, -71.537),
    LatLng(-16.400, -71.530),
  );
  expect(resultado, closeTo(1200, 50));
});
```

---

## 👥 EQUIPO DE DESARROLLO

- **Karla**: Auth + Community
- **Fernando**: Trip Planner ✅ (Completamente refactorizado)
- **Erik**: Live Tracking
- **Lizardo**: Travel Assistant

---

## 📱 FEATURES

### ✅ Implementados
1. **Auth**: Login con teléfono + Verificación SMS
2. **Trip Planner**: Búsqueda de rutas con algoritmo optimizado

### 🚧 En desarrollo
3. **Live Tracking**: Rastreo de buses en tiempo real
4. **Travel Assistant**: Notificaciones de proximidad
5. **Community**: Reportes comunitarios

---

## 🔧 TECNOLOGÍAS

- **Flutter** 3.2.0+
- **BLoC** para gestión de estado
- **GetIt** para inyección de dependencias
- **Google Maps** + **Places API**
- **Firebase Auth**
- **Hive** para caché local
- **Geolocator** para GPS

---

## 📞 CONTACTO

Para preguntas sobre la arquitectura, revisar:
- `ARQUITECTURA_MODULAR.md` - Explicación detallada
- `EJEMPLOS_DE_USO.dart` - Ejemplos prácticos
- `INDICE_FUNCIONES.md` - Referencia rápida

---

**✨ Proyecto reestructurado con ❤️ aplicando Clean Code y SOLID**  
**📅 Última actualización**: Enero 7, 2026
