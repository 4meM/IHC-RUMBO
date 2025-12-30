import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class BusRouteModel {
  final String id;
  final String name;
  final String ref;
  final String from;
  final String to;
  final List<LatLng> coordinates;
  final Color color;
  final String? charge;
  final String? duration;
  final String? interval;
  final String? openingHours;
  final String? operator;

  BusRouteModel({
    required this.id,
    required this.name,
    required this.ref,
    required this.from,
    required this.to,
    required this.coordinates,
    required this.color,
    this.charge,
    this.duration,
    this.interval,
    this.openingHours,
    this.operator,
  });

  factory BusRouteModel.fromGeoJson(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List;

    // Convertir coordenadas [lng, lat] a LatLng
    final points = coords.map((coord) {
      return LatLng(coord[1] as double, coord[0] as double);
    }).toList();

    // Parsear color
    Color routeColor = Colors.blue;
    if (properties['colour'] != null) {
      final colorString = properties['colour'] as String;
      if (colorString.startsWith('#')) {
        routeColor = Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
    }

    return BusRouteModel(
      id: properties['@id'] ?? '',
      name: properties['name'] ?? 'Sin nombre',
      ref: properties['ref'] ?? '',
      from: properties['from'] ?? '',
      to: properties['to'] ?? '',
      coordinates: points,
      color: routeColor,
      charge: properties['charge'],
      duration: properties['duration'],
      interval: properties['interval'],
      openingHours: properties['opening_hours'],
      operator: properties['operator'],
    );
  }

  Polyline toPolyline() {
    return Polyline(
      polylineId: PolylineId(id),
      points: coordinates,
      color: color,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }
}
