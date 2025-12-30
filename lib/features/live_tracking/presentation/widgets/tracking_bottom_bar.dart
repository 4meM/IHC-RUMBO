import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TrackingBottomBar extends StatelessWidget {
  final bool isSiestaMode;
  final VoidCallback onChatPressed;
  final VoidCallback onSOSPressed;
  final VoidCallback onSiestaToggled;
  final VoidCallback onInfoPressed;

  const TrackingBottomBar({
    super.key,
    required this.isSiestaMode,
    required this.onChatPressed,
    required this.onSOSPressed,
    required this.onSiestaToggled,
    required this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Chat Button
              _BottomBarButton(
                icon: Icons.chat_bubble_outline,
                onPressed: onChatPressed,
                tooltip: 'Chat con pasajeros',
              ),
              
              // SOS Button
              _BottomBarButton(
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
                onPressed: onSOSPressed,
                tooltip: 'Emergencia',
              ),
              
              // Siesta Button (con estado ON/OFF)
              _SiestaButton(
                isActive: isSiestaMode,
                onPressed: onSiestaToggled,
              ),
              
              // Info Button
              _BottomBarButton(
                icon: Icons.info_outline,
                onPressed: onInfoPressed,
                tooltip: 'Información del vehículo',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String tooltip;

  const _BottomBarButton({
    required this.icon,
    required this.onPressed,
    this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: buttonColor,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _SiestaButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _SiestaButton({
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isActive ? 'Alarma activada' : 'Activar alarma',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.success
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isActive ? Icons.alarm_on : Icons.alarm_off,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
