import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// ============================================
/// JOURNEY PROGRESS BAR
/// Barra de progreso de viaje con 5 etapas
/// Clean Code: Responsabilidad única
/// ============================================

enum JourneyStage {
  walking,    // Caminando
  waiting,    // Paradero
  onBus,      // En Bus
  gettingOff, // Bajar
  arrived,    // Llegar
}

class JourneyProgressBar extends StatelessWidget {
  final JourneyStage currentStage;
  
  const JourneyProgressBar({
    super.key,
    required this.currentStage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStageItem(
            icon: Icons.directions_walk,
            label: 'Caminar',
            stage: JourneyStage.walking,
          ),
          _buildConnector(isActive: _isStageActive(JourneyStage.walking)),
          _buildStageItem(
            icon: Icons.hourglass_empty,
            label: 'Espera',
            stage: JourneyStage.waiting,
          ),
          _buildConnector(isActive: _isStageActive(JourneyStage.waiting)),
          _buildStageItem(
            icon: Icons.directions_bus,
            label: 'En bus',
            stage: JourneyStage.onBus,
          ),
          _buildConnector(isActive: _isStageActive(JourneyStage.onBus)),
          _buildStageItem(
            icon: Icons.exit_to_app,
            label: 'Bajar',
            stage: JourneyStage.gettingOff,
          ),
          _buildConnector(isActive: _isStageActive(JourneyStage.gettingOff)),
          _buildStageItem(
            icon: Icons.flag,
            label: 'Llegar',
            stage: JourneyStage.arrived,
          ),
        ],
      ),
    );
  }

  /// Construir item de etapa
  Widget _buildStageItem({
    required IconData icon,
    required String label,
    required JourneyStage stage,
  }) {
    final isActive = _isStageActive(stage);
    final isCurrent = currentStage == stage;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStageColor(isActive, isCurrent),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[400],
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.textPrimary : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  /// Construir conector entre etapas
  Widget _buildConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primary : Colors.grey[300],
      ),
    );
  }

  /// Verificar si la etapa está activa (completada o actual)
  bool _isStageActive(JourneyStage stage) {
    return stage.index <= currentStage.index;
  }

  /// Obtener color de la etapa
  Color _getStageColor(bool isActive, bool isCurrent) {
    if (isCurrent) return AppColors.primary;
    if (isActive) return AppColors.success;
    return Colors.grey[300]!;
  }
}
