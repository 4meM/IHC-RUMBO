import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget modular para el sheet de información del vehículo
class InfoBottomSheet extends StatelessWidget {
  final String busNumber;
  final String routeName;

  const InfoBottomSheet({
    super.key,
    required this.busNumber,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            _buildHandleBar(),
            
            // Título
            _buildHeader(),
            
            const Divider(height: 1),
            
            // Información
            Expanded(child: _buildInfoList()),
          ],
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
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: 8),
          Text(
            'Información del Vehículo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoItem(
          Icons.directions_bus,
          'Número de Bus',
          busNumber,
        ),
        _buildInfoItem(
          Icons.route,
          'Ruta',
          routeName,
        ),
        _buildInfoItem(
          Icons.person,
          'Conductor',
          'Juan Pérez',
        ),
        _buildInfoItem(
          Icons.verified_user,
          'Placa',
          'ABC-123',
        ),
        _buildInfoItem(
          Icons.people,
          'Capacidad',
          '40 pasajeros',
        ),
        _buildInfoItem(
          Icons.accessible,
          'Accesibilidad',
          'Disponible',
        ),
        _buildInfoItem(
          Icons.wifi,
          'WiFi',
          'No disponible',
        ),
        _buildInfoItem(
          Icons.attach_money,
          'Tarifa',
          'S/ 1.50',
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
