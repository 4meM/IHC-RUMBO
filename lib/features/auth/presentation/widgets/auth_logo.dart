import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget para logo de la aplicación en pantallas de autenticación
/// Input: size (opcional)
/// Output: Container con icono de bus y estilo Rumbo
class AuthLogo extends StatelessWidget {
  final double size;
  
  const AuthLogo({
    super.key,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.directions_bus_rounded,
          size: size * 0.4,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
