import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

// Core Services
import 'core/services/local_storage_service.dart';
import 'core/services/network_service.dart';
import 'core/services/location_service.dart';

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
