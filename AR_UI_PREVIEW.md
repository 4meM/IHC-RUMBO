# 📱 VISTA PREVIA - Pantalla AR en RUMBO

## Representación de la Interfaz

### Pantalla Principal de AR View

```
╔════════════════════════════════════════════════════════╗
║  ◀  AR VIEW                                      ⓘ     ║  ← Barra Superior
╠════════════════════════════════════════════════════════╣
║                                                        ║
║             ╱─────────────────────╲                    ║
║            │                       │                   ║
║            │     CUADRÍCULA AR     │                   ║
║            │     (fondo oscuro)    │                   ║
║            │                       │                   ║
║            │   ◉ (Bus cercano)     │                   ║
║            │                       │                   ║
║            │      ◎ (Bus más       │                   ║
║            │         lejano)       │                   ║
║            │                       │                   ║
║            │                       │                   ║
║             ╲─────────────────────╱                    ║
║                                                        ║
║  AR VIEW ACTIVO                             ⊙ Brújula  ║
║  Ubicación: -16.3890, -71.5350            │N│          ║
║  Precisión: 12.5m                         ├─┤          ║
║  🚌 3 autobuses cercanos                  └─┘          ║
║                                                        ║
║  ┌────────────────────────────────────────┐           ║
║  │ Autobuses Cercanos                     │           ║  ← Panel Lateral
║  ├────────────────────────────────────────┤           ║
║  │ Bus 12                                  │           ║
║  │ Centro - Cercado                        │           ║
║  │ 0.25 km                     35 km/h     │           ║
║  │                                         │           ║
║  │ Bus 5                                   │           ║
║  │ Yanahuara - Cercado                     │           ║
║  │ 0.35 km                     28 km/h     │           ║
║  │                                         │           ║
║  │ Bus 8                                   │           ║
║  │ Jacobo - Cercado                        │           ║
║  │ 0.50 km                     40 km/h     │           ║
║  └────────────────────────────────────────┘           ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
```

## Marcador de Bus - Detalle

```
                    ╔═════════════════╗
                    ║  ┌───────────┐  ║
                    ║  │    🚌    │  ║  Ícono animado
                    ║  │  35km/h  │  ║  con gradiente
                    ║  └───────────┘  ║
                    ║                 ║
                    ║  Bus 12         ║  Información
                    ║  Centro-Cercado ║  del autobús
                    ║  0.25 km        ║
                    ╚═════════════════╝
```

## Brújula - Detalle

```
            ╔═════════════════╗
            ║      N (rojo)   ║
            ║    ┌─────────┐  ║
            ║    │  ◀ │ ▶  │  ║
            ║  O │    ●    │E  ║  (Centro con aguja)
            ║    │  ◀ │ ▶  │  ║
            ║    └─────────┘  ║
            ║      S (gris)   ║
            ╚═════════════════╝
```

## Panel HUD - Detalle

```
    ╔────────────────────────────────────┐
    │ AR VIEW          [ACTIVO]          │
    ├────────────────────────────────────┤
    │ Ubicación: -16.3890, -71.5350      │
    │ Precisión: 12.5 m                  │
    │ 🚌 3 autobuses cercanos            │
    └────────────────────────────────────┘
```

## Animación de Entrada - Secuencia

```
Frame 1 (inicio):         Frame 2 (mitad):        Frame 3 (fin):
Escala 0.0                Escala 0.5              Escala 1.0

      ◉                          ◉                       ◉◉◉
      
    (muy pequeño)          (mediano)              (tamaño final)

Duración: 500ms
```

## Interacción del Usuario

```
Usuario abre app
       ↓
Presiona botón "Vista AR"
       ↓
Pantalla de carga (CircularProgressIndicator)
       ↓
Solicita permisos de ubicación
       ↓
Usuario acepta
       ↓
Vista AR aparece con animación
       ↓
Cuadrícula aparece
       ↓
Autobuses se animan (ScaleTransition)
       ↓
Información se actualiza en tiempo real
       ↓
Usuario puede girar dispositivo para explorar
```

## Flujo de Posicionamiento

```
Centro de pantalla (usuario)
         ⊙
        /|\  bearing = 45°
       / | \
      /  |  \
     /   |   \  distancia = 250m
    /    |    \
   /     |     \
  ◉ ← Bus posicionado en AR
     (en relación a usuario)

Cálculo:
  angle = bearing * π / 180
  offsetX = distancia * sin(angle)
  offsetY = -distancia * cos(angle)
  screenX = centerX + offsetX
  screenY = centerY + offsetY
```

## Estados de la Aplicación

```
ARViewInitial
  ↓ (usuario abre)
ARViewLoading (solicitando permisos)
  ↓
  ├─ ERROR → ARViewError (permisos denegados)
  │
  └─ OK → ARViewReady
            ├─ userLocation: ARUserLocation?
            └─ nearbyBuses: List<ARBusMarker>
               ↓ (se actualiza continuamente)
            ARViewReady (nuevos valores)
            ARViewReady (nuevos valores)
            ...
  ↓ (usuario cierra)
ARViewInitial
```

## Colores Utilizados

```
╔─────────────────────────────────────═
│ CYAN          #00BCD4 (Primario)    │
│ BLUE          #2196F3 (Secundario)  │
│ LIGHT_BLUE    #81D4FA (Acentos)     │
│ GREEN         #4CAF50 (Éxito)       │
│ RED           #F44336 (Error)       │
│ ORANGE        #FF9800 (Advertencia) │
│ BLACK         #000000 (Fondo)       │
│ WHITE         #FFFFFF (Texto)       │
└─────────────────────────────────────┘
```

## Mapeo de Pantalla - Ejemplo Real

```
Datos del Bus:
  - Latitude: -16.3892 (usuario está en -16.3890)
  - Longitude: -71.5348 (usuario está en -71.5350)
  - Bearing: 45° (NE)
  - Distancia: 250 metros

Pantalla (500x800 px):
  - Centro X: 250
  - Centro Y: 400

Cálculos:
  angle = 45 * π/180 = 0.785 rad
  screenDistance = (250/1000) * 250 = 62.5 px
  offsetX = 62.5 * sin(0.785) = 44.2 px
  offsetY = -62.5 * cos(0.785) = -44.2 px

Posición Final:
  screenX = 250 + 44.2 = 294.2
  screenY = 400 - 44.2 = 355.8

↳ Bus aparece a 294.2, 355.8 en pantalla
```

## Timeline de Actualización

```
T=0s    Usuario abre Vista AR
        └─ Solicita permisos ✓

T=0.5s  ┌─ ARViewReady (estado inicial)
        ├─ Inicializa streams
        └─ Renderiza interfaz

T=1s    ┌─ Ubicación: (-16.3890, -71.5350)
        └─ Renderiza cuadrícula

T=1.5s  ┌─ Primer bus: Bus 12 a 250m
        ├─ Segundo bus: Bus 5 a 350m
        └─ Tercer bus: Bus 8 a 500m

T=2s    └─ Actualiza posiciones (stream de ubicación)

T=4s    └─ Actualiza autobuses (stream de datos)

T=6s    └─ Actualiza nuevamente

...     └─ Continúa en tiempo real hasta cerrar
```

## Ejemplo de Renderización

```
Canvas Layer 1: Cuadrícula
  └─ CustomPaint(ARGridPainter)
     └─ Dibuja líneas, círculos de distancia

Canvas Layer 2: Centro
  └─ Círculo verde pequeño
     └─ Indica posición del usuario

Canvas Layer 3: Marcadores
  └─ Stack de múltiples Positioned
     └─ Cada uno contiene un marcador animado

Canvas Layer 4: HUD
  └─ Container en esquina superior
     └─ Texto con información

Canvas Layer 5: Brújula
  └─ Container en esquina inferior derecha
     └─ Círculo con orientación
```

## Respuesta a Interacciones

```
Usuario toca:
  ↓
❌ No hay toques manejados (solo lectura de sensor)

Usuario gira dispositivo:
  ↓
Heading se actualiza desde GPS
  ↓
Brújula rota
  ↓
Posiciones de buses se recalculan
  ↓
Pantalla se actualiza en tiempo real

Usuario abre panel de información:
  ↓
Dialog aparece con:
  - Instrucciones de uso
  - Número de autobuses
  - Precisión del GPS
  ↓
Usuario presiona "Cerrar"
  ↓
Dialog se cierra
```

---

Esta es la representación visual de la interfaz AR que se ha implementado en la aplicación RUMBO.
