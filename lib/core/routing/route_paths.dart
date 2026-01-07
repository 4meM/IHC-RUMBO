/// Constantes de rutas de la aplicación
/// Estilo: Programación competitiva - una constante = un path

// ============================================================================
// RUTAS DE AUTENTICACIÓN
// ============================================================================

/// Ruta de login (pantalla inicial)
const String loginRoute = '/login';

/// Ruta de verificación de código
const String verifyCodeRoute = '/verify-code';

// ============================================================================
// RUTAS PRINCIPALES
// ============================================================================

/// Ruta del home (mapa de búsqueda)
const String homeRoute = '/home';

/// Ruta de búsqueda de rutas
const String searchRoute = '/search';

/// Ruta de detalle de ruta
const String routeDetailRoute = '/route-detail';

// ============================================================================
// RUTAS DE TRIP PLANNER
// ============================================================================

/// Ruta de planificación de viaje
const String tripPlannerRoute = '/trip-planner';

/// Ruta de rutas favoritas
const String favoritesRoute = '/favorites';

// ============================================================================
// RUTAS DE TRACKING
// ============================================================================

/// Ruta de seguimiento en vivo
const String liveTrackingRoute = '/live-tracking';

/// Ruta de tracking (alias corto)
const String trackingRoute = '/tracking';

/// Ruta de mapa en tiempo real
const String mapRoute = '/map';

// ============================================================================
// RUTAS DE ASISTENTE DE VIAJE
// ============================================================================

/// Ruta de monitoreo de viaje
const String travelMonitoringRoute = '/travel-monitoring';

// ============================================================================
// RUTAS DE COMUNIDAD
// ============================================================================

/// Ruta de reportes de la comunidad
const String communityRoute = '/community';

/// Ruta de crear reporte
const String createReportRoute = '/create-report';

// ============================================================================
// RUTAS DE CONFIGURACIÓN
// ============================================================================

/// Ruta de configuración
const String settingsRoute = '/settings';

/// Ruta de perfil
const String profileRoute = '/profile';

// ============================================================================
// FUNCIONES HELPER
// ============================================================================

/// Verifica si una ruta requiere autenticación
/// Input: String con path de ruta
/// Output: bool indicando si requiere auth
bool requiresAuth(String path) {
  return path != loginRoute && path != verifyCodeRoute;
}

/// Obtiene ruta con parámetros
/// Input: String base path, Map<String, String> params
/// Output: String con ruta completa
String routeWithParams(String basePath, Map<String, String> params) {
  var path = basePath;
  params.forEach((key, value) {
    path = path.replaceAll(':$key', value);
  });
  return path;
}

/// Lista de todas las rutas públicas (sin auth)
List<String> get publicRoutes => [loginRoute, verifyCodeRoute];

/// Lista de todas las rutas privadas (con auth)
List<String> get privateRoutes => [
  homeRoute,
  searchRoute,
  routeDetailRoute,
  tripPlannerRoute,
  favoritesRoute,
  liveTrackingRoute,
  mapRoute,
  travelMonitoringRoute,
  communityRoute,
  createReportRoute,
  settingsRoute,
  profileRoute,
];
