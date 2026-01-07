import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget para mostrar mensajes de error en formularios de autenticación
/// Input: message (String con texto de error)
/// Output: Container con icono y mensaje de error estilizado
class AuthErrorMessage extends StatelessWidget {
  final String message;
  
  const AuthErrorMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
