// Widget: Vista previa del mapa
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPreview extends StatefulWidget {
  const MapPreview({super.key});
  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(-16.409, -71.537); // Coordenadas de ejemplo

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) => mapController = controller,
      initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
      myLocationEnabled: true,
    );
  }
}