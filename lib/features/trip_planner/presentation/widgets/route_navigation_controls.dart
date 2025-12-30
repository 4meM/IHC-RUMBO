import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/services/geojson_parser_service.dart';

class RouteNavigationControls extends StatelessWidget {
  final RouteGroup? currentGroup;
  final int currentIndex;
  final int totalRoutes;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const RouteNavigationControls({
    super.key,
    this.currentGroup,
    required this.currentIndex,
    required this.totalRoutes,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (currentGroup == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onNext,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/ico_bus.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            Positioned(
              top: 25,
              child: Text(
                '${currentIndex + 1}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 4,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
