/// Configuración de rutas de la aplicación usando GoRouter
/// Estilo: Programación competitiva - funciones puras para configuración

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/verify_code_page.dart';
import '../../features/trip_planner/presentation/pages/search_page.dart';
import '../../features/live_tracking/presentation/pages/live_tracking_page.dart';
import 'route_paths.dart';

// ============================================================================
// FUNCIONES DE CONFIGURACIÓN DE RUTAS
// ============================================================================

/// Crea la configuración de la ruta de login
/// Input: ninguno
/// Output: GoRoute configurado
GoRoute createLoginRoute() {
  return GoRoute(
    path: loginRoute,
    builder: (context, state) => const LoginPage(),
  );
}

/// Crea la configuración de la ruta de verificación de código
/// Input: ninguno
/// Output: GoRoute configurado
GoRoute createVerifyCodeRoute() {
  return GoRoute(
    path: verifyCodeRoute,
    builder: (context, state) {
      final phoneNumber = state.extra as String? ?? '';
      return VerifyCodePage(phoneNumber: phoneNumber);
    },
  );
}

/// Crea la configuración de la ruta del home
/// Input: ninguno
/// Output: GoRoute configurado
GoRoute createHomeRoute() {
  return GoRoute(
    path: homeRoute,
    builder: (context, state) {
      // Usar el timestamp o un parámetro extra para forzar recreación
      final resetKey = state.uri.queryParameters['resetKey'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      return SearchPage(key: ValueKey('search_$resetKey'));
    },
  );
}

/// Crea la configuración de la ruta de tracking en vivo
/// Input: ninguno
/// Output: GoRoute configurado
GoRoute createLiveTrackingRoute() {
  return GoRoute(
    path: trackingRoute,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return LiveTrackingPage(
        busNumber: extra['busNumber'] as String? ?? '12',
        routeName: extra['routeName'] as String? ?? 'Centro - Cercado',
        origin: extra['origin'] as LatLng?,
        destination: extra['destination'] as LatLng?,
        routePoints: extra['routePoints'] as List<LatLng>?,
        initialBusPosition: extra['initialBusPosition'] as LatLng?,
        pickupPoint: extra['pickupPoint'] as LatLng?,
        dropoffPoint: extra['dropoffPoint'] as LatLng?,
      );
    },
  );
}

/// Crea la lista completa de rutas de la aplicación
/// Input: ninguno
/// Output: List<RouteBase> con todas las rutas
List<RouteBase> createAllRoutes() {
  return [
    createLoginRoute(),
    createVerifyCodeRoute(),
    createHomeRoute(),
    createLiveTrackingRoute(),
    // TODO: Agregar más rutas según se implementen
  ];
}

// ============================================================================
// FUNCIÓN PRINCIPAL DE CONFIGURACIÓN DEL ROUTER
// ============================================================================

/// Crea el GoRouter configurado con todas las rutas
/// Input: String con ruta inicial (opcional)
/// Output: GoRouter configurado
GoRouter createAppRouter({String initialLocation = '/login'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: createAllRoutes(),
    // TODO: Agregar guards de autenticación si es necesario
    // redirect: (context, state) {
    //   // Lógica de redirección basada en autenticación
    //   return null;
    // },
  );
}

// ============================================================================
// FUNCIONES HELPER PARA NAVEGACIÓN
// ============================================================================

/// Navega a la ruta de login
/// Input: BuildContext
void goToLogin(BuildContext context) {
  context.go(loginRoute);
}

/// Navega a la ruta de verificación con número de teléfono
/// Input: BuildContext, String phoneNumber
void goToVerifyCode(BuildContext context, String phoneNumber) {
  context.push(verifyCodeRoute, extra: phoneNumber);
}

/// Navega a la ruta del home
/// Input: BuildContext
void goToHome(BuildContext context) {
  context.go(homeRoute);
}

/// Navega a la ruta de tracking en vivo
/// Input: BuildContext, datos de ruta
void goToLiveTracking(
  BuildContext context, {
  required String busNumber,
  required String routeName,
  LatLng? origin,
  LatLng? destination,
  List<LatLng>? routePoints,
  LatLng? initialBusPosition,
  LatLng? pickupPoint,
  LatLng? dropoffPoint,
}) {
  context.push(trackingRoute, extra: {
    'busNumber': busNumber,
    'routeName': routeName,
    'origin': origin,
    'destination': destination,
    'routePoints': routePoints,
    'initialBusPosition': initialBusPosition,
    'pickupPoint': pickupPoint,
    'dropoffPoint': dropoffPoint,
  });
}

/// Reemplaza la ruta actual con el home (sin poder volver)
/// Input: BuildContext
void replaceWithHome(BuildContext context) {
  context.go(homeRoute);
}

/// Verifica si se puede navegar hacia atrás
/// Input: BuildContext
/// Output: bool indicando si hay historial
bool canGoBack(BuildContext context) {
  return context.canPop();
}

/// Navega hacia atrás si es posible
/// Input: BuildContext
/// Output: bool indicando si se navegó hacia atrás
bool tryGoBack(BuildContext context) {
  if (canGoBack(context)) {
    context.pop();
    return true;
  }
  return false;
}
