import 'dart:math';

import 'package:flutter/material.dart';

class ProgressSliderComponent extends StatelessWidget {
  final int currentValue; // Current value of the slider
  final int totalValue; // Total value for the slider
  final bool isEnabled; // Flag to enable or disable the slider
  final Color trackColor; // Color for the track
  final Color progressColor; // Color for the progress
  final Color counterTextColor; // Color for the counter text

  const ProgressSliderComponent({
    super.key,
    required this.currentValue,
    required this.totalValue,
    this.isEnabled = true,
    this.trackColor = const Color(0xFFE8E8E9),
    this.progressColor = const Color(0xFF00CC99),
    this.counterTextColor = const Color(0xFF666666),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = min(
      MediaQuery.of(context).size.width,
      450,
    ); // Get screen width
    final sliderWidth = min(
      screenWidth * 0.75,
      308.0,
    ); // Reduced to 75% of screen width, but not more than 218

    // Calculate the actual position for the circle
    // Ensure it stays within bounds
    double circlePosition = (sliderWidth - 24) * (currentValue / totalValue);
    circlePosition = circlePosition.clamp(0.0, sliderWidth - 24);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress Slider
          SizedBox(
            width: sliderWidth,
            height: 32, // Increased height to accommodate larger circle
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Track
                Positioned(
                  top: 13, // Centered within the 32px height
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 6, // Slightly thinner track
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isDark ? theme.colorScheme.surface : trackColor,
                    ),
                  ),
                ),

                // Progress
                Positioned(
                  top: 12,
                  left: 0,
                  child: Container(
                    height: 8,
                    width:
                        circlePosition +
                        12, // Add half circle width for smooth connection
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: progressColor,
                    ),
                  ),
                ),

                // Circle Indicator
                Positioned(
                  left: circlePosition,
                  top: 3, // Centered vertically
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: progressColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.black : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$currentValue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark
                        ? theme.colorScheme.outline
                        : const Color(0xFFE5E5E5),
                width: 1,
              ),
            ),
            child: Text(
              '$currentValue/$totalValue',
              style: TextStyle(
                color:
                    isDark
                        ? theme.textTheme.bodyMedium?.color
                        : counterTextColor,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
