import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_router.dart';

/// Widget modular para botón de iniciar tracking
/// Propósito único: Botón para navegar al tracking con datos de ruta
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

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
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
      },
      icon: const Icon(Icons.directions_bus),
      label: const Text(
        'Iniciar Tracking',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
    );
  }
}
