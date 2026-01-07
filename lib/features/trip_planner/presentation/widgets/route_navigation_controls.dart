import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget: Controles de navegación entre rutas
/// Propósito único: Mostrar botones anterior/siguiente y cerrar búsqueda
class RouteNavigationControls extends StatelessWidget {
  final int currentIndex;
  final int totalRoutes;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const RouteNavigationControls({
    super.key,
    required this.currentIndex,
    required this.totalRoutes,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 280,
      right: 16,
      child: Column(
        children: [
          // Botón anterior
          FloatingActionButton.small(
            heroTag: 'previous',
            onPressed: onPrevious,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.arrow_upward),
          ),
          
          const SizedBox(height: 8),
          
          // Indicador de ruta actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              '${currentIndex + 1}/$totalRoutes',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Botón siguiente
          FloatingActionButton.small(
            heroTag: 'next',
            onPressed: onNext,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.arrow_downward),
          ),
          
          const SizedBox(height: 16),
          
          // Botón cerrar
          FloatingActionButton.small(
            heroTag: 'close',
            onPressed: onClose,
            backgroundColor: Colors.red,
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
