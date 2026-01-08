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

  void _showTrackingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona una opción',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Opción 1: Ver Paraderos Inteligentes en AR
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Ver Paraderos en AR'),
                subtitle: const Text('Muestra paraderos con brújula'),
                onTap: () {
                  Navigator.pop(context);
                  _goToRouteDetail(context);
                },
              ),
              const SizedBox(height: 8),
              // Opción 2: Iniciar Tracking en Vivo
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.directions_bus, color: Colors.green),
                title: const Text('Iniciar Tracking'),
                subtitle: const Text('Sigue el viaje en vivo'),
                onTap: () {
                  Navigator.pop(context);
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
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        ),
      ),
    );
  }

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
    return FloatingActionButton.extended(
      onPressed: () => _showTrackingOptions(context),
      icon: const Icon(Icons.more_vert),
      label: const Text(
        'Opciones',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
    );
  }
}
