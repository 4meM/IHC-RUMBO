import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/ar_user_location_model.dart';

abstract class ARLocationDataSource {
  Stream<ARUserLocationModel> getUserLocationStream();
  Future<bool> checkAndRequestPermissions();
  Future<void> startLocationUpdates();
  Future<void> stopLocationUpdates();
}

class ARLocationDataSourceImpl implements ARLocationDataSource {
  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationController = StreamController<ARUserLocationModel>.broadcast();

  @override
  Stream<ARUserLocationModel> getUserLocationStream() => _locationController.stream;

  @override
  Future<bool> checkAndRequestPermissions() async {
    try {
      final status = await Geolocator.checkPermission();
      
      if (status == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse || 
               result == LocationPermission.always;
      } else if (status == LocationPermission.deniedForever) {
        // El usuario ha rechazado los permisos permanentemente
        await Geolocator.openLocationSettings();
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> startLocationUpdates() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      throw Exception('Permisos de ubicación no otorgados');
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    ).listen((Position position) {
      _locationController.add(
        ARUserLocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          accuracy: position.accuracy,
          heading: position.heading,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Future<void> stopLocationUpdates() async {
    await _positionStreamSubscription?.cancel();
  }

  void dispose() {
    _locationController.close();
    _positionStreamSubscription?.cancel();
  }
}
