import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/ar_bus_marker.dart';
import '../../domain/entities/ar_bus_stop.dart';
import '../../domain/entities/ar_user_location.dart';
import '../../domain/usecases/check_and_request_location_permissions.dart';
import '../../domain/usecases/get_nearby_buses_usecase.dart';
import '../../domain/usecases/get_nearest_bus_stop_usecase.dart';
import '../../domain/usecases/get_user_location_stream.dart';
import '../../domain/usecases/start_location_updates_usecase.dart';

part 'ar_view_event.dart';
part 'ar_view_state.dart';

class ARViewBloc extends Bloc<ARViewEvent, ARViewState> {
  final GetUserLocationStream getUserLocationStream;
  final GetNearbyBusesUseCase getNearbyBuses;
  final CheckAndRequestLocationPermissions checkPermissions;
  final GetNearestBusStopUseCase getNearestBusStop;
  final StartLocationUpdatesUseCase startLocationUpdates;

  ARViewBloc({
    required this.getUserLocationStream,
    required this.getNearbyBuses,
    required this.checkPermissions,
    required this.getNearestBusStop,
    required this.startLocationUpdates,
  }) : super(const ARViewInitial()) {
    on<InitializeARViewEvent>(_onInitializeARView);
    on<UpdateUserLocationEvent>(_onUpdateUserLocation);
    on<UpdateNearbyBusesEvent>(_onUpdateNearbyBuses);
    on<UpdateNearestBusStopEvent>(_onUpdateNearestBusStop);
    on<StopARViewEvent>(_onStopARView);
  }

  Future<void> _onInitializeARView(
    InitializeARViewEvent event,
    Emitter<ARViewState> emit,
  ) async {
    print('[AR BLOC] Inicializando AR View');
    emit(const ARViewLoading());

    // Solicitar permisos
    final permissionResult = await checkPermissions(const NoParams());
    print('[AR BLOC] Resultado de permisos: $permissionResult');

    permissionResult.fold(
      (failure) {
        print('[AR BLOC] Error de permisos: $failure');
        emit(ARViewError(failure.toString()));
      },
      (hasPermission) {
        print('[AR BLOC] Permisos otorgados: $hasPermission');
        if (hasPermission) {
          // Iniciar a cargar ubicación del usuario
          emit(const ARViewReady(
            userLocation: null,
            nearbyBuses: [],
          ));
          print('[AR BLOC] Emitida ARViewReady inicial');

          // IMPORTANTE: Iniciar las actualizaciones de ubicación PRIMERO
          print('[AR BLOC] Iniciando actualizaciones de ubicación...');
          startLocationUpdates(const NoParams()).then((result) {
            result.fold(
              (failure) {
                print('[AR BLOC] Error al iniciar ubicación: $failure');
              },
              (success) {
                print('[AR BLOC] Actualizaciones de ubicación iniciadas correctamente');
              },
            );
          });

          // Escuchar cambios de ubicación
          print('[AR BLOC] Iniciando stream de ubicación...');
          getUserLocationStream(const NoParams()).listen(
            (locationResult) {
              print('[AR BLOC] Recibido resultado de ubicación: $locationResult');
              add(UpdateUserLocationEvent(locationResult));
            },
            onError: (error) {
              print('[AR BLOC] Error en stream de ubicación: $error');
            },
          );
        } else {
          emit(const ARViewError('Permisos de ubicación denegados'));
        }
      },
    );
  }

  Future<void> _onUpdateUserLocation(
    UpdateUserLocationEvent event,
    Emitter<ARViewState> emit,
  ) async {
    print('[AR BLOC] _onUpdateUserLocation invocado');
    event.locationResult.fold(
      (failure) {
        print('[AR BLOC] Error en ubicación: $failure');
        emit(ARViewError(failure.toString()));
      },
      (userLocation) {
        print('[AR BLOC] Ubicación recibida: lat=${userLocation.latitude}, lng=${userLocation.longitude}');
        final currentState = state;
        if (currentState is ARViewReady) {
          emit(ARViewReady(
            userLocation: userLocation,
            nearbyBuses: currentState.nearbyBuses,
            nearestBusStop: currentState.nearestBusStop,
          ));
          print('[AR BLOC] ARViewReady emitida con ubicación');

          // Solicitar buses cercanos cuando la ubicación cambia
          add(UpdateNearbyBusesEvent(
            userLat: userLocation.latitude,
            userLng: userLocation.longitude,
          ));

          // Solicitar paradero más cercano
          add(UpdateNearestBusStopEvent(
            userLat: userLocation.latitude,
            userLng: userLocation.longitude,
          ));
        }
      },
    );
  }

  Future<void> _onUpdateNearbyBuses(
    UpdateNearbyBusesEvent event,
    Emitter<ARViewState> emit,
  ) async {
    const radiusMeters = 1000.0; // 1 km de radio

    getNearbyBuses(GetNearbyBusesParams(
      userLat: event.userLat,
      userLng: event.userLng,
      radiusMeters: radiusMeters,
    )).listen(
      (busResult) {
        busResult.fold(
          (failure) {
            emit(ARViewError(failure.toString()));
          },
          (buses) {
            final currentState = state;
            if (currentState is ARViewReady) {
              emit(ARViewReady(
                userLocation: currentState.userLocation,
                nearbyBuses: buses,
                nearestBusStop: currentState.nearestBusStop,
              ));
            }
          },
        );
      },
    );
  }

  Future<void> _onUpdateNearestBusStop(
    UpdateNearestBusStopEvent event,
    Emitter<ARViewState> emit,
  ) async {
    final result = await getNearestBusStop(GetNearestBusStopParams(
      userLat: event.userLat,
      userLng: event.userLng,
    ));

    result.fold(
      (failure) {
        emit(ARViewError(failure.toString()));
      },
      (busStop) {
        final currentState = state;
        if (currentState is ARViewReady) {
          emit(ARViewReady(
            userLocation: currentState.userLocation,
            nearbyBuses: currentState.nearbyBuses,
            nearestBusStop: busStop,
          ));
        }
      },
    );
  }

  Future<void> _onStopARView(
    StopARViewEvent event,
    Emitter<ARViewState> emit,
  ) async {
    emit(const ARViewInitial());
  }
}
