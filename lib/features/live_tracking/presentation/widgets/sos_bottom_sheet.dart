import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget modular para el sheet de SOS/Emergencia
class SOSBottomSheet extends StatelessWidget {
  final Function(String message, IconData icon) onNotificationShow;

  const SOSBottomSheet({
    super.key,
    required this.onNotificationShow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              _buildHandleBar(),
              
              // Título con ícono
              _buildHeader(),
              
              // Opciones de emergencia - Grid de íconos
              _buildSOSGrid(context),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.error,
        size: 36,
      ),
    );
  }

  Widget _buildSOSGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildSOSIconButton(
            icon: Icons.my_location,
            onTap: () {
              Navigator.pop(context);
              onNotificationShow('Ubicación compartida', Icons.check_circle);
            },
          ),
          _buildSOSIconButton(
            icon: Icons.phone,
            onTap: () {
              Navigator.pop(context);
              onNotificationShow('Llamando a emergencia', Icons.phone);
            },
          ),
          _buildSOSIconButton(
            icon: Icons.message,
            onTap: () {
              Navigator.pop(context);
              onNotificationShow('Mensaje enviado', Icons.check_circle);
            },
          ),
          _buildSOSIconButton(
            icon: Icons.campaign,
            onTap: () {
              Navigator.pop(context);
              onNotificationShow('Conductor notificado', Icons.check_circle);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSOSIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppColors.error.withOpacity(0.2),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.error.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.error,
              size: 52,
            ),
          ),
        ),
      ),
    );
  }
}
