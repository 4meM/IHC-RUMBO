import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

// AR View Feature
import 'features/ar_view/data/datasources/ar_location_datasource.dart';
import 'features/ar_view/data/datasources/ar_bus_datasource.dart';
import 'features/ar_view/data/datasources/ar_bus_stops_datasource.dart';
import 'features/ar_view/data/repositories/ar_location_repository_impl.dart';
import 'features/ar_view/data/repositories/ar_bus_repository_impl.dart';
import 'features/ar_view/domain/repositories/ar_location_repository.dart';
import 'features/ar_view/domain/repositories/ar_bus_repository.dart';
import 'features/ar_view/domain/usecases/get_user_location_stream.dart';
import 'features/ar_view/domain/usecases/get_nearby_buses_usecase.dart';
import 'features/ar_view/domain/usecases/get_nearest_bus_stop_usecase.dart';
import 'features/ar_view/domain/usecases/check_and_request_location_permissions.dart';
import 'features/ar_view/presentation/bloc/ar_view_bloc.dart';

// TODO: Importar cada feature y registrar sus dependencias

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // ========================================
  // CORE - Servicios externos
  // ========================================
  
  // Dio (HTTP Client)
  sl.registerLazySingleton<Dio>(() => Dio(
    BaseOptions(
      baseUrl: 'https://api.rumbo.pe/v1', // TODO: Cambiar por URL real
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  ));

  // Hive (Local Storage)
  // TODO: Registrar Hive boxes aquí
  
  // Services
  // sl.registerLazySingleton<LocalStorageService>(() => LocalStorageServiceImpl());
  // sl.registerLazySingleton<NetworkService>(() => NetworkServiceImpl(sl()));
  // sl.registerLazySingleton<LocationService>(() => LocationServiceImpl());

  // ========================================
  // AR VIEW - DATASOURCES
  // ========================================
  sl.registerLazySingleton<ARLocationDataSource>(
    () => ARLocationDataSourceImpl(),
  );
  
  sl.registerLazySingleton<ARBusDataSource>(
    () => ARBusDataSourceImpl(),
  );

  sl.registerLazySingleton<ARBusStopsDataSource>(
    () => ARBusStopsDataSourceImpl(),
  );

  // ========================================
  // AR VIEW - REPOSITORIES
  // ========================================
  sl.registerLazySingleton<ARLocationRepository>(
    () => ARLocationRepositoryImpl(dataSource: sl<ARLocationDataSource>()),
  );
  
  sl.registerLazySingleton<ARBusRepository>(
    () => ARBusRepositoryImpl(
      dataSource: sl<ARBusDataSource>(),
      busStopsDataSource: sl<ARBusStopsDataSource>(),
    ),
  );

  // ========================================
  // AR VIEW - USECASES
  // ========================================
  sl.registerLazySingleton<GetUserLocationStream>(
    () => GetUserLocationStream(repository: sl<ARLocationRepository>()),
  );
  
  sl.registerLazySingleton<CheckAndRequestLocationPermissions>(
    () => CheckAndRequestLocationPermissions(repository: sl<ARLocationRepository>()),
  );
  
  sl.registerLazySingleton<GetNearbyBusesUseCase>(
    () => GetNearbyBusesUseCase(repository: sl<ARBusRepository>()),
  );

  sl.registerLazySingleton<GetNearestBusStopUseCase>(
    () => GetNearestBusStopUseCase(repository: sl<ARBusRepository>()),
  );

  // ========================================
  // AR VIEW - BLOC
  // ========================================
  sl.registerLazySingleton<ARViewBloc>(
    () => ARViewBloc(
      getUserLocationStream: sl<GetUserLocationStream>(),
      getNearbyBuses: sl<GetNearbyBusesUseCase>(),
      checkPermissions: sl<CheckAndRequestLocationPermissions>(),
      getNearestBusStop: sl<GetNearestBusStopUseCase>(),
    ),
  );

  // ========================================
  // FEATURES - Cada desarrollador registra sus dependencias
  // ========================================
  
  // --- AUTH (KARLA) ---
  // TODO: Registrar DataSources, Repositories, UseCases, BLoCs

  // --- TRIP PLANNER (FERNANDO) ---
  // TODO: Registrar DataSources, Repositories, UseCases, BLoCs

  // --- LIVE TRACKING (ERIK) ---
  // TODO: Registrar DataSources, Repositories, UseCases, BLoCs

  // --- TRAVEL ASSISTANT (LIZARDO) ---
  // TODO: Registrar Services, UseCases, BLoCs

  // --- COMMUNITY (KARLA) ---
  // TODO: Registrar DataSources, Repositories, UseCases, BLoCs
}
