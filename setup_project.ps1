# ========================================
# RUMBO - Script de Generacion de Arquitectura Clean
# Para ejecutar: .\setup_project.ps1
# ========================================

Write-Host ">>> Generando estructura de RUMBO - Clean Architecture por Features" -ForegroundColor Cyan
Write-Host ""

# Definir la ruta base del proyecto
$projectRoot = $PSScriptRoot

# Función para crear archivo .dart vacío con comentario
function New-DartFile {
    param (
        [string]$filePath,
        [string]$description = ""
    )
    
    $directory = Split-Path -Path $filePath -Parent
    
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    if ($description -ne "") {
        Set-Content -Path $filePath -Value "// $description"
    } else {
        Set-Content -Path $filePath -Value "// TODO: Implement"
    }
    
    Write-Host "  [OK] Creado: $($filePath.Replace($projectRoot, ''))" -ForegroundColor Green
}

# Función para crear directorio
function New-ProjectDirectory {
    param (
        [string]$path
    )
    
    if (-not (Test-Path -Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "  [DIR] Directorio: $($path.Replace($projectRoot, ''))" -ForegroundColor Yellow
    }
}

# ========================================
# ESTRUCTURA BASE
# ========================================
Write-Host "`n[BASE] Creando estructura base..." -ForegroundColor Cyan

$libPath = Join-Path $projectRoot "lib"

# Core
Write-Host "`n[CORE] Utilidades compartidas" -ForegroundColor Magenta
New-DartFile "$libPath\core\constants\api_constants.dart" "API URLs y Keys"
New-DartFile "$libPath\core\constants\app_colors.dart" "Paleta de colores de RUMBO"
New-DartFile "$libPath\core\constants\app_strings.dart" "Textos de la aplicación"

New-DartFile "$libPath\core\errors\failures.dart" "Clase abstracta Failure"
New-DartFile "$libPath\core\errors\exceptions.dart" "ServerException, CacheException, etc"

New-DartFile "$libPath\core\usecases\usecase.dart" "abstract class UseCase<Type, Params>"

New-DartFile "$libPath\core\utils\converters.dart" "Funciones de conversión"
New-DartFile "$libPath\core\utils\validators.dart" "Validadores de formularios"

New-DartFile "$libPath\core\services\local_storage_service.dart" "Servicio de Hive"
New-DartFile "$libPath\core\services\network_service.dart" "Servicio de HTTP (Dio)"
New-DartFile "$libPath\core\services\location_service.dart" "Servicio de GPS"

# Shared
Write-Host "`n[SHARED] Entidades y Widgets Globales" -ForegroundColor Magenta
New-DartFile "$libPath\shared\domain\bus_entity.dart" "Entity: Bus"
New-DartFile "$libPath\shared\domain\location_entity.dart" "Entity: Location"
New-DartFile "$libPath\shared\domain\route_entity.dart" "Entity: Route"

New-DartFile "$libPath\shared\widgets\rumbo_button.dart" "Widget: Botón personalizado"
New-DartFile "$libPath\shared\widgets\loading_spinner.dart" "Widget: Spinner de carga"
New-DartFile "$libPath\shared\widgets\error_snackbar.dart" "Widget: Snackbar de error"

# ========================================
# FEATURES
# ========================================

# --- AUTH (KARLA) ---
Write-Host "`n[AUTH] FEATURE: AUTH [KARLA]" -ForegroundColor Blue
$authPath = "$libPath\features\auth"

New-DartFile "$authPath\data\datasources\auth_local_data_source.dart" "Fuente de datos local (Hive)"
New-DartFile "$authPath\data\datasources\auth_remote_data_source.dart" "Fuente de datos remota (API)"
New-DartFile "$authPath\data\models\user_model.dart" "Model: User (con freezed)"
New-DartFile "$authPath\data\repositories\auth_repository_impl.dart" "Implementación del repositorio"

New-DartFile "$authPath\domain\entities\user_entity.dart" "Entity: User"
New-DartFile "$authPath\domain\repositories\auth_repository.dart" "Contrato del repositorio"
New-DartFile "$authPath\domain\usecases\login_usecase.dart" "UseCase: Login"
New-DartFile "$authPath\domain\usecases\register_usecase.dart" "UseCase: Register"
New-DartFile "$authPath\domain\usecases\logout_usecase.dart" "UseCase: Logout"

New-DartFile "$authPath\presentation\bloc\auth_bloc.dart" "BLoC: Auth"
New-DartFile "$authPath\presentation\bloc\auth_event.dart" "Eventos de Auth"
New-DartFile "$authPath\presentation\bloc\auth_state.dart" "Estados de Auth"
New-DartFile "$authPath\presentation\pages\login_page.dart" "Página: Login"
New-DartFile "$authPath\presentation\pages\register_page.dart" "Página: Registro"

# --- TRIP PLANNER (FERNANDO) ---
Write-Host "`n[TRIP_PLANNER] FEATURE: TRIP PLANNER [FERNANDO]" -ForegroundColor Blue
$tripPath = "$libPath\features\trip_planner"

New-DartFile "$tripPath\data\datasources\trip_local_data_source.dart" "Cache de rutas"
New-DartFile "$tripPath\data\datasources\trip_remote_data_source.dart" "API de rutas"
New-DartFile "$tripPath\data\models\trip_model.dart" "Model: Trip"
New-DartFile "$tripPath\data\repositories\trip_repository_impl.dart" "Implementación"

New-DartFile "$tripPath\domain\repositories\trip_repository.dart" "Contrato"
New-DartFile "$tripPath\domain\usecases\search_routes_usecase.dart" "UseCase: Buscar rutas"
New-DartFile "$tripPath\domain\usecases\save_favorite_route_usecase.dart" "UseCase: Guardar favorito"

New-DartFile "$tripPath\presentation\bloc\trip_bloc.dart" "BLoC: Trip Planner"
New-DartFile "$tripPath\presentation\bloc\trip_event.dart" "Eventos"
New-DartFile "$tripPath\presentation\bloc\trip_state.dart" "Estados"
New-DartFile "$tripPath\presentation\pages\search_page.dart" "Página: Buscar ruta"
New-DartFile "$tripPath\presentation\pages\route_detail_page.dart" "Página: Detalle de ruta"
New-DartFile "$tripPath\presentation\widgets\route_card.dart" "Widget: Tarjeta de ruta"
New-DartFile "$tripPath\presentation\widgets\map_preview.dart" "Widget: Vista previa del mapa"

# --- LIVE TRACKING (ERIK) ---
Write-Host "`n[LIVE_TRACKING] FEATURE: LIVE TRACKING [ERIK]" -ForegroundColor Blue
$trackingPath = "$libPath\features\live_tracking"

New-DartFile "$trackingPath\data\datasources\tracking_remote_data_source.dart" "WebSocket/API en tiempo real"
New-DartFile "$trackingPath\data\repositories\tracking_repository_impl.dart" "Implementación"

New-DartFile "$trackingPath\domain\repositories\tracking_repository.dart" "Contrato"
New-DartFile "$trackingPath\domain\usecases\get_bus_location_usecase.dart" "UseCase: Ubicación del bus"
New-DartFile "$trackingPath\domain\usecases\subscribe_to_bus_usecase.dart" "UseCase: Suscribirse a bus"

New-DartFile "$trackingPath\presentation\bloc\tracking_bloc.dart" "BLoC: Tracking"
New-DartFile "$trackingPath\presentation\bloc\tracking_event.dart" "Eventos"
New-DartFile "$trackingPath\presentation\bloc\tracking_state.dart" "Estados"
New-DartFile "$trackingPath\presentation\pages\map_page.dart" "Página: Mapa en tiempo real"
New-DartFile "$trackingPath\presentation\widgets\bus_marker.dart" "Widget: Marcador de bus"
New-DartFile "$trackingPath\presentation\widgets\user_location_marker.dart" "Widget: Marcador de usuario"

# --- TRAVEL ASSISTANT (LIZARDO) ---
Write-Host "`n[TRAVEL_ASSISTANT] FEATURE: TRAVEL ASSISTANT [LIZARDO]" -ForegroundColor Blue
$assistantPath = "$libPath\features\travel_assistant"

New-DartFile "$assistantPath\background\travel_background_service.dart" "Servicio en background"
New-DartFile "$assistantPath\background\notification_handler.dart" "Manejo de notificaciones"

New-DartFile "$assistantPath\domain\usecases\start_travel_monitoring_usecase.dart" "UseCase: Iniciar monitoreo"
New-DartFile "$assistantPath\domain\usecases\stop_travel_monitoring_usecase.dart" "UseCase: Detener monitoreo"
New-DartFile "$assistantPath\domain\services\travel_monitor_service.dart" "Servicio de monitoreo"

New-DartFile "$assistantPath\presentation\bloc\assistant_bloc.dart" "BLoC: Assistant"
New-DartFile "$assistantPath\presentation\bloc\assistant_event.dart" "Eventos"
New-DartFile "$assistantPath\presentation\bloc\assistant_state.dart" "Estados"
New-DartFile "$assistantPath\presentation\pages\travel_monitoring_page.dart" "Página: Monitoreo de viaje"

# --- COMMUNITY (KARLA) ---
Write-Host "`n[COMMUNITY] FEATURE: COMMUNITY [KARLA]" -ForegroundColor Blue
$communityPath = "$libPath\features\community"

New-DartFile "$communityPath\data\datasources\community_remote_data_source.dart" "API de reportes"
New-DartFile "$communityPath\data\models\report_model.dart" "Model: Report"
New-DartFile "$communityPath\data\repositories\community_repository_impl.dart" "Implementación"

New-DartFile "$communityPath\domain\entities\report_entity.dart" "Entity: Report"
New-DartFile "$communityPath\domain\repositories\community_repository.dart" "Contrato"
New-DartFile "$communityPath\domain\usecases\create_report_usecase.dart" "UseCase: Crear reporte"
New-DartFile "$communityPath\domain\usecases\get_reports_usecase.dart" "UseCase: Obtener reportes"

New-DartFile "$communityPath\presentation\bloc\community_bloc.dart" "BLoC: Community"
New-DartFile "$communityPath\presentation\bloc\community_event.dart" "Eventos"
New-DartFile "$communityPath\presentation\bloc\community_state.dart" "Estados"
New-DartFile "$communityPath\presentation\widgets\report_card.dart" "Widget: Tarjeta de reporte"
New-DartFile "$communityPath\presentation\widgets\create_report_dialog.dart" "Widget: Diálogo crear reporte"

Write-Host "`n[COMPLETADO] Estructura creada exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "[PROXIMOS PASOS]:" -ForegroundColor Yellow
Write-Host "  1. Ejecuta: flutter pub get" -ForegroundColor White
Write-Host "  2. Ejecuta: dart run build_runner build --delete-conflicting-outputs" -ForegroundColor White
Write-Host "  3. Cada desarrollador puede empezar a trabajar en su feature asignada" -ForegroundColor White
Write-Host ""
Write-Host "[ASIGNACIONES]:" -ForegroundColor Yellow
Write-Host "  - KARLA: features/auth y features/community" -ForegroundColor White
Write-Host "  - FERNANDO: features/trip_planner" -ForegroundColor White
Write-Host "  - ERIK: features/live_tracking" -ForegroundColor White
Write-Host "  - LIZARDO: features/travel_assistant" -ForegroundColor White
Write-Host ""
