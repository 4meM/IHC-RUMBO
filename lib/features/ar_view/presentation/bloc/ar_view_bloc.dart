import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/ar_bus_marker.dart';
import '../../domain/entities/ar_user_location.dart';
import '../../domain/usecases/check_and_request_location_permissions.dart';
import '../../domain/usecases/get_nearby_buses_usecase.dart';
import '../../domain/usecases/get_user_location_stream.dart';

part 'ar_view_event.dart';
part 'ar_view_state.dart';

class ARViewBloc extends Bloc<ARViewEvent, ARViewState> {
  final GetUserLocationStream getUserLocationStream;
  final GetNearbyBusesUseCase getNearbyBuses;
  final CheckAndRequestLocationPermissions checkPermissions;

  ARViewBloc({
    required this.getUserLocationStream,
    required this.getNearbyBuses,
    required this.checkPermissions,
  }) : super(const ARViewInitial()) {
    on<InitializeARViewEvent>(_onInitializeARView);
    on<UpdateUserLocationEvent>(_onUpdateUserLocation);
    on<UpdateNearbyBusesEvent>(_onUpdateNearbyBuses);
    on<StopARViewEvent>(_onStopARView);
  }

  Future<void> _onInitializeARView(
    InitializeARViewEvent event,
    Emitter<ARViewState> emit,
  ) async {
    emit(const ARViewLoading());

    // Solicitar permisos
    final permissionResult = await checkPermissions(const NoParams());

    permissionResult.fold(
      (failure) {
        emit(ARViewError(failure.toString()));
      },
      (hasPermission) {
        if (hasPermission) {
          // Iniciar a cargar ubicación del usuario
          emit(const ARViewReady(
            userLocation: null,
            nearbyBuses: [],
          ));

          // Escuchar cambios de ubicación
          getUserLocationStream(const NoParams()).listen(
            (locationResult) {
              add(UpdateUserLocationEvent(locationResult));
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
    event.locationResult.fold(
      (failure) {
        emit(ARViewError(failure.toString()));
      },
      (userLocation) {
        final currentState = state;
        if (currentState is ARViewReady) {
          emit(ARViewReady(
            userLocation: userLocation,
            nearbyBuses: currentState.nearbyBuses,
          ));

          // Solicitar buses cercanos cuando la ubicación cambia
          add(UpdateNearbyBusesEvent(
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
              ));
            }
          },
        );
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
