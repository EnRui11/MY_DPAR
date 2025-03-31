import 'package:flutter/material.dart';
import 'package:mydpar/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/services/bottom_nav_service.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<NavigationService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colors.bg100.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.bg300.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++)
            _buildNavItem(context, i, colors, navigationService,
                navigationService.currentIndex),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    AppColorTheme colors,
    NavigationService navigationService,
    int activeIndex,
  ) {
    final bool isActive = index == navigationService.currentIndex;
    final String label = _getNavLabel(index);

    return Expanded(
      flex: isActive ? 2 : 1, // Reduced flex ratio for active items
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(
            vertical: 8.0, horizontal: 1.0), // Further reduced margin
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 8.0 : 4.0, // Further reduced padding
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? colors.accent200.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isActive
              ? MainAxisAlignment.start
              : (index < activeIndex
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end),
          children: [
            if (!isActive && index > activeIndex)
              SizedBox(
                width: 38, // Fixed width for icon container
                child: Container(
                  padding: const EdgeInsets.all(6.0), // Reduced padding
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    navigationService.getScreenIcon(index),
                    color: colors.text200.withOpacity(0.7),
                    size: 20, // Slightly smaller icon
                  ),
                ),
              ),
            if (isActive) ...[
              SizedBox(
                width: 38, // Fixed width for icon container
                child: Container(
                  padding: const EdgeInsets.all(6.0), // Reduced padding
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent200,
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent200.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Icon(
                    navigationService.getScreenIcon(index),
                    color: colors.bg100,
                    size: 20, // Slightly smaller icon
                  ),
                ),
              ),
              const SizedBox(width: 4.0), // Reduced spacing
              Flexible(
                // Changed from Expanded to Flexible
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1.0,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.accent200,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ],
            if (!isActive && index < activeIndex)
              SizedBox(
                width: 38, // Fixed width for icon container
                child: Container(
                  padding: const EdgeInsets.all(6.0), // Reduced padding
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    navigationService.getScreenIcon(index),
                    color: colors.text200.withOpacity(0.7),
                    size: 20, // Slightly smaller icon
                  ),
                ),
              ),
          ],
        ),
      ).gestureDetector(onTap: () {
        if (!isActive) {
          navigationService.navigateToIndex(context, index, replace: true);
        }
      }),
    );
  }

  String _getNavLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Map';
      case 2:
        return 'Community';
      case 3:
        return 'Profile';
      default:
        return '';
    }
  }
}

// Extension to make the code cleaner
extension GestureDetectorExtension on Widget {
  Widget gestureDetector({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: this,
    );
  }
}
