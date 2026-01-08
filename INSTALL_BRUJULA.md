# ⚡ INSTALACIÓN RÁPIDA - 2 PASOS

## Paso 1️⃣: Descargar Dependencias

Abre una terminal en la raíz del proyecto y ejecuta:

```bash
flutter pub get
```

**Esto:**
- Descarga `sensors_plus` (necesario para la brújula)
- Descarga `camera` (para futuro AR real)
- Actualiza `pubspec.lock`

**Tiempo**: ~30-60 segundos (depende de tu conexión)

**Esperado**:
```
Resolving dependencies...
  sensors_plus 5.4.0 (from pub.dev)
  camera 0.10.5+2 (from pub.dev)
...
Got dependencies! ✓
```

---

## Paso 2️⃣: Ejecutar la App

En la misma terminal:

```bash
flutter run
```

**O si usas VS Code**:
- Abre el archivo `lib/main.dart`
- Presiona `F5` (o Ctrl+Shift+D → Run)

**Esperado**:
```
Launching lib/main.dart on [your device] in debug mode...
...
🎉 App installed successfully!
```

---

## 🧪 Probar la Brújula

Una vez que la app esté abierta:

1. **Selecciona un destino**
   - Abre la pantalla de búsqueda
   - Ingresa un lugar
   - Toca "Buscar"

2. **Ves 3 paraderos en tarjetas**
   ```
   El Más Cercano
   Evita Tráfico  
   Asientos Garantizados
   ```

3. **Toca "Ver Paraderos en AR"**
   - Aparece la vista AR (simulada/cámara)
   - Verás una brújula rotatoria en el centro

4. **¡Brújula en Acción!**
   - Mueve tu dispositivo
   - La brújula rota según tu heading real
   - Desliza ← → para cambiar paraderos
   - La brújula apunta al paradero seleccionado

---

## ✅ Verificación

Si ves esto → **¡Está funcionando correctamente!** ✅

```
╔═════════════════════════╗
║  Brújula Rotatoria      ║
║                         ║
║      N (Rojo)           ║
║     /   \               ║
║    W  ⊗  E  ← Centro    ║
║     \   /               ║
║      S                  ║
║                         ║
║      Flecha apunta      ║
║      al paradero        ║
╚═════════════════════════╝

N | 250m | 45°
```

---

## ❌ Si No Funciona

### Error: "Could not find sensors_plus"
```bash
flutter pub get
flutter clean
flutter pub get
flutter run
```

### Brújula no aparece
1. Verifica permisos de ubicación en el dispositivo
2. Mueve el dispositivo - los sensores necesitan movimiento
3. Abre otra app con brújula para verificar que funcione

### Compila pero está buggui
```bash
flutter clean
flutter pub get
flutter run
```

### Emulador dice "No sensors available"
- Normal en emulador Android (pero funciona de todas formas)
- Prueba en dispositivo real para mejor experiencia

---

## 📚 Documentación

Después de verificar que funciona, lee:

1. **BRUJULA_IMPLEMENTACION.md** (5 min)
   - Guía rápida
   - Controles
   - Troubleshooting

2. **COMPASS_SERVICE_GUIA.md** (15 min)
   - Cómo funciona internamente
   - Métodos disponibles
   - Personalización

3. **EJEMPLOS_COMPASS.dart** (20 min)
   - 10 ejemplos prácticos
   - Código listo para copiar

---

## 🎮 Controles en AR

| Acción | Resultado |
|--------|-----------|
| **Mueve dispositivo** | Brújula rota |
| **Desliza izquierda/derecha** | Cambia paradero |
| **Toca "Seleccionar"** | Confirma paradero |
| **Toca "Volver"** | Cierra vista AR |

---

## 🔍 Archivos Creados

### Código
```
✅ lib/features/trip_planner/data/services/compass_service.dart
   ↳ Servicio de brújula (200+ líneas)
   
✅ lib/features/trip_planner/presentation/widgets/smart_stops_ar_view.dart
   ↳ Vista AR actualizada con brújula
```

### Documentación
```
✅ BRUJULA_IMPLEMENTACION.md      - Guía rápida
✅ COMPASS_SERVICE_GUIA.md        - Documentación técnica
✅ EJEMPLOS_COMPASS.dart          - 10 ejemplos
✅ INDICE_BRUJULA.md              - Índice completo
✅ RESUMEN_BRUJULA.md             - Resumen ejecutivo
✅ INSTALL_BRUJULA.md             - Este archivo
```

---

## 🆘 Soporte Rápido

| Problema | Solución |
|----------|----------|
| **Compilación fallida** | `flutter pub get && flutter clean && flutter run` |
| **Brújula no aparece** | Verifica permisos + mueve dispositivo |
| **Valores inconsistentes** | Normal - los sensores se estabilizan |
| **Consume mucha batería** | Normal - sensores activos (5-10% adicional) |
| **No sé cómo usar** | Leer BRUJULA_IMPLEMENTACION.md |

---

## 🎉 ¡Listo!

**Solo ejecuta estos 2 comandos y la brújula estará funcionando:**

```bash
# 1. Descargar dependencias
flutter pub get

# 2. Ejecutar app
flutter run
```

**Eso es todo. ¡Disfruta la brújula! 🧭**

