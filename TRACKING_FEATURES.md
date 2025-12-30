# 🚌 RUMBO - Funcionalidades de Tracking en Vivo

## 🎯 Nuevas Funcionalidades Implementadas

Se ha implementado una **barra de navegación inferior intuitiva** en la página de tracking en vivo con 4 botones principales:

### 1. 💬 **Chat**
- **Ícono**: Globo de conversación (`chat_bubble_outline`)
- **Función**: Permite conversar con otros pasajeros que están en el mismo vehículo
- **Características**:
  - Muestra número de pasajeros conectados
  - Chat en tiempo real
  - Interfaz limpia y minimalista

### 2. 🚨 **SOS (Emergencia)**
- **Ícono**: Triángulo de advertencia (`warning_amber_rounded`)
- **Color**: Rojo (indica peligro/emergencia)
- **Función**: Proporciona 4 opciones de emergencia:
  1. 📍 **Compartir ubicación** - Envía tu ubicación actual
  2. 📞 **Llamar emergencia (105)** - Llama directamente a emergencias
  3. 💬 **Mensaje de emergencia** - Envía mensaje a contactos de confianza
  4. 📢 **Avisar al conductor** - Notifica al chofer del bus

### 3. 😴 **Siesta ON/OFF**
- **Íconos**: 
  - `alarm_off` cuando está desactivado (gris)
  - `alarm_on` cuando está activado (verde con sombra)
- **Función**: Alarma inteligente para despertar al llegar al destino
- **Características**:
  - Estado visual claro (color y sombra cuando está activo)
  - Animación suave al cambiar de estado
  - Notificación al activar/desactivar
  - Perfecto para viajes largos

### 4. ℹ️ **Info (Información)**
- **Ícono**: Círculo de información (`info_outline`)
- **Función**: Muestra información detallada del vehículo
- **Datos mostrados**:
  - 🚌 Número de bus
  - 🛣️ Ruta
  - 👤 Nombre del conductor
  - 🚗 Placa del vehículo
  - 👥 Capacidad de pasajeros
  - ♿ Accesibilidad
  - 📶 WiFi disponible
  - 💵 Tarifa

## 🎨 Diseño Intuitivo

### Principios de Diseño Implementados:

1. **Solo íconos**: Se evitó el uso de texto en los botones para mayor claridad visual
2. **Colores significativos**:
   - 🔵 Azul: Acciones normales (Chat, Info)
   - 🔴 Rojo: Emergencia (SOS)
   - 🟢 Verde: Estado activo (Siesta ON)
   - ⚪ Gris: Estado inactivo (Siesta OFF)
3. **Feedback visual**: 
   - Animaciones suaves
   - Cambios de color al activar
   - Sombras para indicar estado activo
4. **Tooltips**: Al mantener presionado cada botón, aparece una descripción

## 📱 Cómo Usar

### Acceder al Tracking en Vivo:

1. Inicia sesión en la app
2. Verifica tu código
3. En el mapa principal, presiona el botón **"Ver Tracking"**
4. Se abrirá la vista de tracking con:
   - Mapa en tiempo real
   - Información de llegada estimada
   - Distancia al destino
   - Barra de botones en la parte inferior

### Usar los Botones:

#### Chat:
1. Toca el ícono 💬
2. Se abre el panel de chat
3. Escribe tu mensaje
4. Presiona enviar

#### SOS:
1. Toca el ícono 🚨
2. Selecciona una de las 4 opciones
3. Confirma la acción

#### Siesta:
1. Toca el ícono 😴 (apagado en gris)
2. El ícono cambia a 🔔 (verde brillante)
3. La alarma queda activada
4. Toca nuevamente para desactivar

#### Info:
1. Toca el ícono ℹ️
2. Se muestra el panel con toda la información del vehículo
3. Desliza hacia abajo para cerrar

## 🗺️ Navegación

Para navegar a la página de tracking desde código:

```dart
context.push('/tracking', extra: {
  'busNumber': '12',
  'routeName': 'Centro - Cercado',
});
```

## 📂 Archivos Creados

```
lib/features/live_tracking/presentation/
├── pages/
│   └── live_tracking_page.dart          # Página principal de tracking
└── widgets/
    ├── tracking_bottom_bar.dart         # Barra inferior con 4 botones
    └── tracking_info_card.dart          # Tarjeta de información superior
```

## 🎯 Próximas Mejoras

- [ ] Integrar WebSocket para chat en tiempo real
- [ ] Conectar con API de emergencias real
- [ ] Implementar lógica de alarma con geofencing
- [ ] Añadir notificación push al llegar cerca del destino
- [ ] Agregar sistema de reportes comunitarios
- [ ] Historial de viajes

## 🚀 Características Técnicas

- **Framework**: Flutter
- **Estado**: StatefulWidget para manejo de estado local
- **Navegación**: GoRouter
- **Mapas**: Google Maps Flutter
- **Animaciones**: AnimatedContainer para transiciones suaves
- **Arquitectura**: Clean Architecture

## 💡 Tips de UX

1. Los botones tienen un área de toque amplia (padding generoso)
2. Los colores son consistentes con el sistema de diseño
3. Las animaciones son rápidas (300ms) para mejor respuesta
4. Los modales se pueden cerrar deslizando hacia abajo
5. El feedback visual es inmediato

---

**Desarrollado para RUMBO** 🚌
*Sistema de Transporte Público Arequipa*
