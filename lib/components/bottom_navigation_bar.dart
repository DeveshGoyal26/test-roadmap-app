import 'package:flutter/material.dart';

/// A custom bottom navigation bar widget that displays navigation items
/// and handles navigation between different screens of the app.
class BottomNavigationBarWidget extends StatelessWidget {
  // Current selected index to highlight the active tab
  final int currentIndex;

  // Callback function that gets triggered when a navigation item is tapped
  // This is the main navigation handler that will be provided by the parent widget
  final Function(int) onTap;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Container for the entire bottom navigation bar
    // Includes styling for elevation shadow effect
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      // Increased vertical padding to make the bottom bar larger
      padding: const EdgeInsets.symmetric(vertical: 18),
      // Row layout to arrange navigation items horizontally
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Each _navItem represents a tab in the navigation bar
          _navItem(0, Icons.home_outlined, 'Home'),
          _navItem(1, Icons.ondemand_video_outlined, 'Roadmaps'),
          _navItem(2, Icons.people_outline, 'Community'),
          _navItem(3, Icons.person_outline, 'Profile'),
        ],
      ),
    );
  }

  /// Creates a single navigation item with icon and label
  ///
  /// [index]: The position of this item in the navigation bar
  /// [icon]: The icon to display for this navigation item
  /// [label]: The text label shown below the icon
  Widget _navItem(int index, IconData icon, String label) {
    // Determine if this navigation item is currently selected
    final bool isSelected = index == currentIndex;

    // InkWell provides the tap functionality for navigation
    // This is the key component that triggers navigation
    return InkWell(
      // When tapped, call the onTap callback with this item's index
      // This is what actually performs the navigation by informing the parent
      onTap: () => onTap(index),
      // Column layout to arrange icon and text vertically
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The icon for this navigation item
          // Color changes based on selection state
          // Increased icon size
          Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey.shade600,
            size: 28, // Increased from 24
          ),
          const SizedBox(height: 4),
          // The text label for this navigation item
          // Font weight and color change based on selection state
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: const Color(0xFF222222), // #222 color
              height: 1.3, // 130% line height
              letterSpacing: 0.12,
              fontFeatures: const [
                FontFeature.enable('dlig'), // Enable discretionary ligatures
              ],
              fontVariations: const [
                FontVariation(
                  'wght',
                  400,
                ), // For lining nums and proportional nums
              ],
            ),
          ),
        ],
      ),
    );
  }
}
