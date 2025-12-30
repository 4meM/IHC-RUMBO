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
  final VoidCallback onCycleRoute;

  const RouteNavigationControls({
    super.key,
    this.currentGroup,
    required this.currentIndex,
    required this.totalRoutes,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
    required this.onCycleRoute,
  });

  @override
  Widget build(BuildContext context) {
    if (currentGroup == null) return const SizedBox.shrink();

    const buttonSize = 60.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous arrow button - left extreme
          GestureDetector(
            onTap: onPrevious,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          // Bus icon with number - center
          GestureDetector(
            onTap: onCycleRoute,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/ico_bus.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    top: 18,
                    child: Text(
                      '${currentIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
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
          ),
          
          // Next arrow button - right extreme
          GestureDetector(
            onTap: onNext,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
