# ✅ SOLUCIÓN: Reset Completo al Navegar a Home

## 🎯 PROBLEMA

Cuando el usuario completaba un viaje y presionaba "Nuevo Viaje", GoRouter reutilizaba la instancia existente de `SearchPage` y `MapPreview`, manteniendo el estado anterior (origen, destino, rutas seleccionadas).

**Causa raíz:** GoRouter optimiza reutilizando widgets existentes cuando navegas a la misma ruta.

---

## ✨ SOLUCIÓN IMPLEMENTADA

### **1. Uso de `ValueKey` con timestamp único**

Se agregó una `ValueKey` dinámica que cambia en cada navegación, forzando a Flutter a recrear completamente el widget tree.

#### **Antes:**
```dart
GoRoute createHomeRoute() {
  return GoRoute(
    path: homeRoute,
    builder: (context, state) => const SearchPage(), // ❌ Siempre el mismo widget
  );
}
```

#### **Después:**
```dart
GoRoute createHomeRoute() {
  return GoRoute(
    path: homeRoute,
    builder: (context, state) {
      // Usar el timestamp o un parámetro extra para forzar recreación
      final resetKey = state.uri.queryParameters['resetKey'] ?? 
                       DateTime.now().millisecondsSinceEpoch.toString();
      return SearchPage(key: ValueKey('search_$resetKey')); // ✅ Key única
    },
  );
}
```

---

### **2. Propagación de Key a MapPreview**

Se modificó `SearchPage` para pasar su propia key a `MapPreview`:

#### **Antes:**
```dart
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: MapPreview(), // ❌ Sin key
      ),
    );
  }
}
```

#### **Después:**
```dart
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MapPreview(key: key), // ✅ Propaga la key del padre
      ),
    );
  }
}
```

---

### **3. Navegación con Query Parameter único**

Se cambió `context.go()` por `context.pushReplacement()` con un query parameter único:

#### **Antes:**
```dart
ElevatedButton.icon(
  onPressed: () {
    context.go('/home'); // ❌ Reutiliza el widget
  },
  label: const Text('Nuevo Viaje'),
)
```

#### **Después:**
```dart
ElevatedButton.icon(
  onPressed: () {
    // Generar timestamp único para forzar recreación
    final resetKey = DateTime.now().millisecondsSinceEpoch.toString();
    context.pushReplacement('/home?resetKey=$resetKey'); // ✅ Key única
  },
  label: const Text('Nuevo Viaje'),
)
```

---

## 🔧 CÓMO FUNCIONA

### **Flujo de Recreación:**

1. **Usuario presiona "Nuevo Viaje"**
   - Se genera un timestamp único: `1704672000123`
   - Se navega a: `/home?resetKey=1704672000123`

2. **GoRouter recibe la ruta**
   - Extrae `resetKey` de los query parameters
   - Crea `ValueKey('search_1704672000123')`

3. **Flutter detecta key diferente**
   - Compara con la key anterior
   - Como son diferentes, **destruye completamente** el widget anterior
   - Crea nuevas instancias de `SearchPage` → `MapPreview` → `MapController`

4. **Resultado:**
   - Todo se inicializa desde cero
   - `initState()` se ejecuta nuevamente
   - Campos vacíos, sin rutas, sin marcadores

---

## 📊 VENTAJAS DE ESTA SOLUCIÓN

✅ **Limpio y predecible:** Usa mecanismos nativos de Flutter  
✅ **Sin estado global:** No requiere resetear manualmente variables  
✅ **Escalable:** Funciona para cualquier navegación futura  
✅ **Performante:** Solo recrea cuando es necesario  
✅ **Flexible:** Puedes reutilizar el patrón en otras rutas  

---

## 🎯 USO EN OTRAS PARTES

### **Opción 1: Desde cualquier pantalla**
```dart
// Navegar a home con reset
final resetKey = DateTime.now().millisecondsSinceEpoch.toString();
context.pushReplacement('/home?resetKey=$resetKey');
```

### **Opción 2: Navegación normal (reutiliza widget)**
```dart
// Navegar a home sin reset (más eficiente si no necesitas limpiar)
context.go('/home');
```

---

## 🔍 ALTERNATIVAS CONSIDERADAS (NO IMPLEMENTADAS)

### **❌ Opción 1: Reset manual del controller**
```dart
// NO recomendado - propenso a bugs si olvidas algo
_controller.resetAll();
context.go('/home');
```
**Problema:** Tienes que acordarte de resetear cada variable manualmente.

### **❌ Opción 2: Usar Provider/BLoC global**
```dart
// NO recomendado - añade complejidad innecesaria
Provider.of<MapState>(context).reset();
context.go('/home');
```
**Problema:** Requiere estado global adicional.

### **✅ Opción 3: ValueKey + Query Parameters (IMPLEMENTADA)**
```dart
// ✅ MEJOR - aprovecha los mecanismos nativos de Flutter
final resetKey = DateTime.now().millisecondsSinceEpoch.toString();
context.pushReplacement('/home?resetKey=$resetKey');
```
**Ventaja:** Flutter se encarga de todo automáticamente.

---

## 📝 ARCHIVOS MODIFICADOS

| Archivo | Cambio |
|---------|--------|
| [app_router.dart](lib/core/routing/app_router.dart) | Agregado `ValueKey` con `resetKey` |
| [search_page.dart](lib/features/trip_planner/presentation/pages/search_page.dart) | Propaga key a `MapPreview` |
| [live_tracking_page.dart](lib/features/live_tracking/presentation/pages/live_tracking_page.dart) | Cambiado a `pushReplacement` con query param |

---

## 🧪 PRUEBA MANUAL

1. Ejecuta la app: `flutter run -d R5CY42DN2VR`
2. Busca una ruta (origen → destino)
3. Presiona "Iniciar Tracking"
4. En Live Tracking, presiona "Nuevo Viaje"
5. **Verifica:** SearchPage está completamente limpia ✅

---

## 💡 CONCEPTOS CLAVE

### **¿Qué es una `ValueKey`?**
Una `ValueKey` es un identificador que Flutter usa para determinar si un widget es "el mismo" o "diferente". Si la key cambia, Flutter recrea el widget desde cero.

### **¿Por qué `pushReplacement`?**
`pushReplacement` reemplaza la ruta actual en el stack en lugar de agregar una nueva. Esto evita que el usuario presione "atrás" y vuelva a la pantalla de tracking.

### **¿Por qué timestamp?**
El timestamp garantiza que cada navegación tenga una key única, forzando la recreación. Es simple, eficiente y no requiere estado adicional.

---

## 🎉 RESULTADO FINAL

✅ **Antes:** Reutilizaba widget → Estado persistía  
✅ **Después:** Recrea widget → Estado limpio desde cero  

**Problema resuelto!** 🚀
