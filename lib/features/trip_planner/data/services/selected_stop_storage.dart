import 'package:flutter/foundation.dart';

class SelectedStopStorage {
  // Guarda en memoria la selección por routeRef durante la sesión
  // Ahora almacenamos el `SmartStopType` como String (p.ej. 'nearest'),
  // para que la selección se pueda restaurar aunque los IDs cambien.
  static final Map<String, String> _savedStopTypes = {};

  static String? getSavedStopType(String routeRef) {
    final v = _savedStopTypes[routeRef];
    // Debug: ver qué se restaura
    try {
      // ignore: avoid_print
      print('[SelectedStopStorage] getSavedStopType routeRef=$routeRef -> $v');
    } catch (_) {}
    return v;
  }

  static void setSavedStopType(String routeRef, String stopTypeName) {
    _savedStopTypes[routeRef] = stopTypeName;
    // Debug: confirmar guardado
    try {
      // ignore: avoid_print
      print('[SelectedStopStorage] setSavedStopType routeRef=$routeRef <- $stopTypeName');
    } catch (_) {}
    // Notificar cambios para que listeners (ej. MapController) puedan actualizarse
    try {
      _notifier.value++;
    } catch (_) {}
  }

  static void clearForRoute(String routeRef) {
    _savedStopTypes.remove(routeRef);
    try {
      // ignore: avoid_print
      print('[SelectedStopStorage] clearForRoute routeRef=$routeRef');
    } catch (_) {}
    try {
      _notifier.value++;
    } catch (_) {}
  }

  // Notifier incremental para cambios en el almacenamiento
  static final ValueNotifier<int> _notifier = ValueNotifier<int>(0);

  static ValueNotifier<int> get notifier => _notifier;
}
