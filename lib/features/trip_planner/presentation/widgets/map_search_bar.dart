import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget: Barra de búsqueda flotante sobre el mapa
/// Propósito único: Contener los campos de búsqueda de origen y destino
class MapSearchBar extends StatelessWidget {
  final Widget originField;
  final Widget destinationField;
  final Widget? originSuggestions;
  final Widget? destinationSuggestions;
  
  const MapSearchBar({
    super.key,
    required this.originField,
    required this.destinationField,
    this.originSuggestions,
    this.destinationSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Campo de origen
          originField,
          
          // Sugerencias de origen
          if (originSuggestions != null) ...[
            const SizedBox(height: 8),
            originSuggestions!,
          ],
          
          const SizedBox(height: 12),
          
          // Campo de destino
          destinationField,
          
          // Sugerencias de destino
          if (destinationSuggestions != null) ...[
            const SizedBox(height: 8),
            destinationSuggestions!,
          ],
        ],
      ),
    );
  }
}
