import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/models/bus_route_model.dart';
import '../pages/route_detail_page.dart';

/// Widget modular para botón de iniciar tracking
/// Propósito único: Botón para navegar al tracking o a detalle de ruta con datos de ruta
class StartTrackingButton extends StatelessWidget {
  final String busNumber;
  final String routeName;
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> routePoints;
  final LatLng? pickupPoint;
  final LatLng? dropoffPoint;

  const StartTrackingButton({
    super.key,
    required this.busNumber,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.routePoints,
    this.pickupPoint,
    this.dropoffPoint,
  });

  void _goToRouteDetail(BuildContext context) {
    final route = BusRouteModel(
      id: busNumber,
      name: routeName,
      ref: busNumber,
      from: 'Origen',
      to: 'Destino',
      coordinates: routePoints,
      color: Colors.blue,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteDetailPage(
          route: route,
          userLocation: origin,
          routeRef: busNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón Paraderos
        FloatingActionButton.extended(
          onPressed: () => _goToRouteDetail(context),
          icon: const Icon(Icons.location_on),
          label: const Text('Paraderos'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        const SizedBox(width: 12),
        // Botón Iniciar viaje
        FloatingActionButton.extended(
          onPressed: () => _startTracking(context),
          icon: const Icon(Icons.navigation),
          label: const Text('Iniciar viaje'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ],
    );
  }

  void _startTracking(BuildContext context) {
    goToLiveTracking(
      context,
      busNumber: busNumber,
      routeName: routeName,
      origin: origin,
      destination: destination,
      routePoints: routePoints,
      initialBusPosition: pickupPoint,
      pickupPoint: pickupPoint,
      dropoffPoint: dropoffPoint,
    );
  }
}
