import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget: Card con información de la ruta seleccionada
/// Propósito único: Mostrar detalles de distancia y tiempo de una ruta
class RouteInfoCard extends StatelessWidget {
  final String routeRef;
  final String walkingDistance;
  final String busDistance;
  final String estimatedTime;
  
  const RouteInfoCard({
    super.key,
    required this.routeRef,
    required this.walkingDistance,
    required this.busDistance,
    required this.estimatedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ruta $routeRef',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.directions_walk, walkingDistance),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.directions_bus, busDistance),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, estimatedTime),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
