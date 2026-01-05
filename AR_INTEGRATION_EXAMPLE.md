# Ejemplo de Integración - Botón AR View

## Cómo integrar la Vista AR en tus páginas

Este archivo muestra ejemplos de cómo agregar la funcionalidad de AR en tus páginas existentes.

## Opción 1: Usar el FAB Personalizado (Recomendado)

En tu página, importa el widget:

```dart
import 'features/ar_view/presentation/widgets/ar_view_fab.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Página')),
      body: Center(child: const Text('Contenido')),
      // Opción 1: Usar el FAB personalizado
      floatingActionButton: ARViewFAB(
        onPressed: () {
          // Lógica adicional opcional
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Abriendo Vista AR...')),
          );
        },
      ),
    );
  }
}
```

## Opción 2: Botón en AppBar

```dart
actions: [
  Tooltip(
    message: 'Ver autobuses en AR',
    child: IconButton(
      icon: const Icon(Icons.camera_enhance),
      onPressed: () => context.push('/ar-view'),
    ),
  ),
],
```

## Opción 3: Botón Flotante Personalizado

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => context.push('/ar-view'),
  tooltip: 'Vista AR',
  child: const Icon(Icons.camera_enhance),
),
```

## Opción 4: Navegación Directa

Desde cualquier lugar en tu código:

```dart
context.push('/ar-view');
```

## Pasos para Implementar

1. **En tu archivo de página**, importa el widget:
   ```dart
   import 'features/ar_view/presentation/widgets/ar_view_fab.dart';
   ```

2. **En tu Scaffold**, agrega el botón flotante:
   ```dart
   floatingActionButton: ARViewFAB(),
   ```

3. **O navega directamente** usando GoRouter:
   ```dart
   context.push('/ar-view');
   ```

## Notas

- El botón `ARViewFAB` es el componente recomendado
- Automáticamente solicita permisos de ubicación
- La vista AR se abre con animación
- Los datos se actualizan en tiempo real

## Personalización

El widget `ARViewFAB` soporta callbacks:

```dart
ARViewFAB(
  onPressed: () {
    // Ejecuta antes de navegar a AR
    print('Abriendo AR...');
  },
),
```

Para más información, consulta:
- [AR_VIEW_README.md](AR_VIEW_README.md) - Documentación técnica
- [QUICK_START.md](QUICK_START.md) - Guía rápida de inicio
