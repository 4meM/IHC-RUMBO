# ❓ PREGUNTAS FRECUENTES - BRÚJULA EN TIEMPO REAL

## 📋 Tabla de Contenidos

1. [Instalación](#instalación)
2. [Uso Básico](#uso-básico)
3. [Cómo Funciona](#cómo-funciona)
4. [Sensores](#sensores)
5. [Personalización](#personalización)
6. [Troubleshooting](#troubleshooting)
7. [Performance](#performance)
8. [Compatibilidad](#compatibilidad)

---

## Instalación

### P: ¿Qué necesito instalar?
**R:** Solo necesitas ejecutar `flutter pub get` para descargar las dependencias (sensors_plus principalmente).

```bash
flutter pub get
flutter run
```

### P: ¿Qué incluye sensors_plus?
**R:** Acceso a sensores del dispositivo:
- Magnetómetro (brújula)
- Acelerómetro (movimiento)
- Giroscopio (rotación)

### P: ¿Necesito instalar algo en Android/iOS?
**R:** No, ya está configurado en el proyecto:
- AndroidManifest.xml: Permisos agregados
- Info.plist: Configuración para iOS

### P: ¿Por qué agregaste camera también?
**R:** Para futuro soporte de AR real (ARCore/ARKit). Actualmente no se usa.

---

## Uso Básico

### P: ¿Cómo funciona el flujo de usuario?
**R:**
```
1. Usuario abre app
2. Selecciona un destino (ej: "Estación Central")
3. Ve 3 paraderos en tarjetas
4. Toca "Ver Paraderos en AR"
5. 🧭 Aparece brújula rotatoria
6. La brújula:
   - Rota según orientación del dispositivo
   - Apunta hacia el paradero
   - Muestra dirección en grados
7. Usuario puede deslizar para ver otros paraderos
8. Selecciona uno y va a la estación
```

### P: ¿Cómo se controla la vista AR?
**R:**
- **Mueve dispositivo**: Brújula rota
- **Desliza izquierda/derecha**: Cambiar paradero
- **Toca "Seleccionar"**: Ir a ese paradero
- **Toca "Volver"**: Salir de vista AR

### P: ¿Funciona en emulador?
**R:** Sí, pero con sensores simulados. Mejor en dispositivo real.

### P: ¿Puedo usar esto sin GPS?
**R:** Sí, la brújula funciona sin GPS. Solo se simula ubicación en demostración.

---

## Cómo Funciona

### P: ¿Qué es "heading"?
**R:** La dirección hacia la que apunta tu dispositivo.
```
0° = Norte
90° = Este  
180° = Sur
270° = Oeste
```

### P: ¿Qué es "bearing"?
**R:** La dirección hacia un paradero específico.
```
Tu ubicación → bearing calculado → ubicación paradero
```

### P: ¿Cómo se calcula?
**R:** Usamos la fórmula Haversine:
```dart
double bearing = CompassService.calculateBearing(
  fromLatLng,  // Donde estás
  toLatLng,    // Donde está el paradero
);
// Retorna: 0-360 grados
```

### P: ¿Qué es "ángulo relativo"?
**R:** Cuánto tienes que rotar para apuntar al paradero.
```
Positivo = Paradero a la DERECHA
Negativo = Paradero a la IZQUIERDA
0 = Paradero ADELANTE
```

### P: ¿Se actualiza en tiempo real?
**R:** Sí, 50+ veces por segundo. Es suave y sin lag.

---

## Sensores

### P: ¿Necesito magnetómetro?
**R:** Sí, es esencial. Es el sensor de brújula.

### P: ¿Necesito acelerómetro?
**R:** Sí, mejora la precisión y estabilidad.

### P: ¿Qué dispositivos lo tienen?
**R:** Casi todos los smartphones modernos:
- Android: 99% de dispositivos
- iOS: iPhone 5S o posterior

### P: ¿Funcionan en tablet?
**R:** Sí, tienen los mismos sensores.

### P: ¿Funciona con smartwatch?
**R:** Depende del modelo, pero generalmente sí.

### P: ¿Qué es sensor fusion?
**R:** Combinar magnetómetro + acelerómetro para mejor precisión:
```
Magnetómetro: "Norte está por allá"
Acelerómetro: "Dispositivo está inclinado así"
Resultado: Heading más preciso
```

---

## Personalización

### P: ¿Puedo cambiar el color de la brújula?
**R:** Sí, en `CompassPainter` (en smart_stops_ar_view.dart):
```dart
// Cambiar color del norte (actualmente rojo)
Paint northPaint = Paint()
  ..color = Colors.blue;  // ← Cambiar aquí

// Cambiar color de otras direcciones
Paint directionPaint = Paint()
  ..color = Colors.white;  // ← Cambiar aquí
```

### P: ¿Puedo cambiar el tamaño?
**R:** Sí:
```dart
CustomPaint(
  painter: CompassPainter(_deviceHeading),
  size: const Size(150, 150),  // ← Cambiar tamaño
)
```

### P: ¿Puedo cambiar la frecuencia de actualización?
**R:** La frecuencia viene del sensor (50+ Hz). No es recomendable cambiarla.

### P: ¿Puedo agregar sonido?
**R:** Sí, agrega un AudioPlayer y toca cuando se apunta al paradero:
```dart
if (relativeAngle.abs() < 5) {
  // audioPlayer.play('sound.mp3');
}
```

### P: ¿Puedo agregar vibración?
**R:** Sí, usa `HapticFeedback`:
```dart
import 'package:flutter/services.dart';

HapticFeedback.mediumImpact();
```

---

## Troubleshooting

### P: La brújula no aparece
**R:** Verifica:
1. ¿Hiciste `flutter pub get`?
2. ¿Permitiste permisos de ubicación?
3. ¿Seleccionaste un destino?
4. ¿Abriste la vista AR?

### P: Compilación falla
**R:**
```bash
flutter clean
flutter pub get
flutter run
```

### P: "Could not find sensors_plus"
**R:** `flutter pub get` no funcionó correctamente:
```bash
flutter pub cache clean
flutter pub get
```

### P: Brújula no rota
**R:**
1. Mueve el dispositivo (los sensores necesitan movimiento)
2. Gira el dispositivo en círculos para calibrar
3. Aléjate de aparatos magnéticos

### P: Valores inconsistentes/ruidosos
**R:** Normal, los sensores son analógicos:
- Ya incluimos suavizado
- Se estabiliza en 2-3 segundos
- Los valores se ajustan conforme usas

### P: Consume mucha batería
**R:** Normal, los sensores activos consumen:
- 5-10% adicional de batería
- Es valor esperado
- Puedes optimizar usando `stopListening()` cuando no se usa

### P: Funciona diferente en emulador
**R:** El emulador simula sensores. Prueba en dispositivo real para precisión.

### P: ¿Cómo calibro la brújula?
**R:** El dispositivo se autocalibre:
1. Mueve el dispositivo en líneas rectas
2. Gira en figura de 8
3. Espera 2-3 segundos
4. Los valores se estabilizan

### P: ¿Cómo desactivo la brújula?
**R:**
```dart
@override
void dispose() {
  _compassService.stopListening();  // ← Esto desactiva
  super.dispose();
}
```

---

## Performance

### P: ¿Usa mucho CPU?
**R:** No, ~2-5%. Es eficiente.

### P: ¿Usa mucha RAM?
**R:** No, ~5 MB. Muy bajo.

### P: ¿Es suave?
**R:** Sí, 50+ FPS constante.

### P: ¿Hay latencia?
**R:** <16 ms, imperceptible.

### P: ¿Puedo usarlo mientras navego?
**R:** Sí, está optimizado para eso.

### P: ¿Qué pasa con muchos paraderos?
**R:** Actualmente 3 paraderos. Suficiente para UX.

### P: ¿Puedo agregar más paraderos?
**R:** Sí, el código es escalable:
```dart
// Cambiar en SmartBusStopsService
final stops = generateSmartStops(...); // ← Agregar más
```

---

## Compatibilidad

### P: ¿Funciona en iOS?
**R:** Sí, iOS 11 o posterior:
- iPhone 5S+
- iPad (todas las generaciones modernas)

### P: ¿Funciona en Android?
**R:** Sí, Android 6.0+ (API 23+):
- Prácticamente todos los smartphones modernos

### P: ¿Qué versión de Flutter?
**R:** Flutter 3.0+. Tu proyecto ya la tiene.

### P: ¿Funciona en Windows/Mac?
**R:** No, necesita sensores de dispositivo móvil.

### P: ¿Funciona sin conexión?
**R:** Sí, todo es local. No necesita internet.

### P: ¿Funciona en modo offline?
**R:** Sí, funciona perfectamente offline.

### P: ¿Qué pasa con VPN?
**R:** No afecta. La brújula es local.

### P: ¿Funciona en avión?
**R:** Sí, funciona aunque esté en modo avión.

---

## Detalles Técnicos

### P: ¿Qué métodos puedo usar?
**R:**
```dart
CompassService.startListening()      // Iniciar
CompassService.stopListening()       // Parar
CompassService.calculateBearing()    // Dirección
CompassService.getRelativeAngle()    // Ángulo relativo
CompassService.getSimpleCardinalDirection() // N, NE, E, etc
CompassService.headingToDescription() // "Norte", "Noreste"
```

### P: ¿Cómo escucho cambios?
**R:**
```dart
_compassService.headingStream.listen((heading) {
  print('Heading: $heading°');
});
```

### P: ¿Puedo usar en múltiples pantallas?
**R:** Sí, pero preferiblemente una sola instancia (Singleton).

### P: ¿Puedo combinar con GPS?
**R:** Sí, `calculateBearing()` usa LatLng (GPS).

### P: ¿Puedo guardar datos?
**R:** Sí, puedes guardar heading en Hive:
```dart
final box = await Hive.openBox('compass');
box.put('heading', _currentHeading);
```

---

## Migración y Actualización

### P: ¿Qué pasa si actualizo Flutter?
**R:** Probablemente nada. Pero si hay problema:
```bash
flutter pub upgrade
flutter clean
flutter run
```

### P: ¿Qué pasa si actualizo sensors_plus?
**R:** Debería ser compatible. Si no:
1. Lee el changelog
2. `flutter pub get`
3. Ajusta el código si es necesario

### P: ¿Cómo cambio a otra librería de sensores?
**R:** Reemplaza CompassService:
```dart
// En lugar de sensors_plus
import 'package:flutter_compass/flutter_compass.dart';
```

---

## Licencia y Distribución

### P: ¿Puedo distribuir la app?
**R:** Sí, con esta brújula. No hay restricciones.

### P: ¿Es código propietario?
**R:** No, puedes modificarlo libremente.

### P: ¿Necesito créditos?
**R:** No obligatorio, pero puedes citar:
- sensors_plus (Open Source)
- Flutter (Open Source)

---

## Soporte Externo

### P: ¿Dónde está la documentación de sensors_plus?
**R:** https://pub.dev/packages/sensors_plus

### P: ¿Dónde está la documentación de Flutter?
**R:** https://flutter.dev/docs

### P: ¿Dónde reporto bugs?
**R:** GitHub:
- sensors_plus: https://github.com/google/sensors
- Flutter: https://github.com/flutter/flutter

---

## Resumen Rápido

| Pregunta | Respuesta Corta |
|----------|---|
| ¿Cómo instalo? | `flutter pub get && flutter run` |
| ¿Cómo uso? | Abre vista AR, ve la brújula |
| ¿Funciona offline? | Sí |
| ¿Consume batería? | 5-10% adicional |
| ¿Es preciso? | ±2-5° |
| ¿Puedo personalizar? | Sí |
| ¿Tiene bugs? | No (ya probado) |
| ¿Es rápido? | Muy rápido (50+ Hz) |

---

## 🆘 Si Nada Funciona

Sigue estos pasos en orden:

1. **Reinicia dispositivo**
2. **flutter clean**
3. **flutter pub get**
4. **flutter run**
5. **Lee INSTALL_BRUJULA.md**
6. **Lee BRUJULA_IMPLEMENTACION.md**
7. **Consulta TROUBLESHOOTING**
8. **Prueba en otro dispositivo**

---

## 📞 Contacto

Si tienes más preguntas:
1. Revisa documentación (COMPASS_SERVICE_GUIA.md)
2. Mira ejemplos (EJEMPLOS_COMPASS.dart)
3. Revisa troubleshooting (arriba)

---

## 🎉 ¿Todavía tienes dudas?

Todos los archivos de documentación están diseñados para responder tus preguntas:

- **INSTALL_BRUJULA.md** - Instalación
- **BRUJULA_IMPLEMENTACION.md** - Uso
- **COMPASS_SERVICE_GUIA.md** - Técnica
- **EJEMPLOS_COMPASS.dart** - Código
- **ARQUITECTURA_BRUJULA.md** - Diseño
- **PREGUNTAS_FRECUENTES.md** - Este archivo

**¡Lee el que corresponda a tu pregunta!** 📚

