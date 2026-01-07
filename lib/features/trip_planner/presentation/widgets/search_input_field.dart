import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget: Input de búsqueda con icono y hint personalizado
/// Propósito único: Renderizar un campo de texto estilizado para búsqueda
class SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final VoidCallback? onIconTap;
  final bool readOnly;
  final bool isSelecting;
  
  const SearchInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.onIconTap,
    this.readOnly = false,
    this.isSelecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: onIconTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onIconTap,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor ?? AppColors.primary),
                  ),
                ),
              )
            : Icon(icon, color: iconColor ?? AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isSelecting 
              ? BorderSide(color: iconColor ?? AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isSelecting 
              ? BorderSide(color: iconColor ?? AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isSelecting 
              ? BorderSide(color: iconColor ?? AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
