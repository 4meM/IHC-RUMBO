import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget: Card visual con imágenes de buses para mejor orientación del usuario
/// Propósito único: Mostrar disponibilidad de buses con imágenes visuales
/// Los buses se cambian mediante los botones de navegación de rutas (arriba/abajo)
class RouteInfoCard extends StatelessWidget {
  final String routeRef;
  final String walkingDistance;
  final String busDistance;
  final String estimatedTime;
  final int currentRouteIndex; // Índice de la ruta actual (sincroniza el bus mostrado)
  
  // Imágenes disponibles de buses
  static final List<String> _busImages = [
    'assets/images/bus_image.png',
    'assets/images/bus2_image.png',
    'assets/images/bus3_image.png',
    'assets/images/bus4_image.png',
    'assets/images/bus5_image.png',
  ];
  
  const RouteInfoCard({
    super.key,
    required this.routeRef,
    required this.walkingDistance,
    required this.busDistance,
    required this.estimatedTime,
    required this.currentRouteIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular el índice del bus basado en el índice de ruta
    final busImageIndex = currentRouteIndex % _busImages.length;
    
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue[50]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título con ruta
                Text(
                  'Ruta $routeRef (Bus ${busImageIndex + 1})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Carrusel de buses SIN botones de navegación
                _buildBusCarousel(busImageIndex),
                
                const SizedBox(height: 16),
                
                // Información de distancia y tiempo en fila compacta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.directions_walk, walkingDistance),
                    _buildInfoChip(Icons.directions_bus, busDistance),
                    _buildInfoChip(Icons.access_time, estimatedTime),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Carrusel de buses SIN botones de navegación
  /// La imagen se sincroniza automáticamente con el índice de ruta
  Widget _buildBusCarousel(int busImageIndex) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue[50],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  _busImages[busImageIndex],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.directions_bus,
                      size: 80,
                      color: Colors.blue[600],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bus ${busImageIndex + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${busImageIndex + 1} / ${_busImages.length}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Chip compacto para información
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue[100],
        border: Border.all(color: Colors.blue[300]!, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
