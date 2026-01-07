import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget: Lista de sugerencias de lugares
/// Propósito único: Mostrar lista de resultados de búsqueda con tap handler
class PlaceSuggestionsList extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final Function(Map<String, dynamic>) onSuggestionTap;
  
  const PlaceSuggestionsList({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.place, color: AppColors.primary),
            title: Text(
              suggestion['description'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {
                FocusScope.of(context).unfocus();
                onSuggestionTap(suggestion);
            },
          );
        },
      ),
    );
  }
}
