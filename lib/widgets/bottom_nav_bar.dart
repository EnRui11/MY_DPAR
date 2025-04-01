import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class BottomNavBar extends StatelessWidget {
  // Add onTap callback
  final Function(int)? onTap;

  const BottomNavBar({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<NavigationService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    final activeIndex = navigationService.currentIndex;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: colors.bg100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          4, // Number of navigation items
          (index) => _buildNavItem(
            context,
            index,
            activeIndex,
            navigationService,
            colors,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    int activeIndex,
    NavigationService navigationService,
    AppColorTheme colors,
  ) {
    final bool isActive = index == navigationService.currentIndex;
    final String label = navigationService.getScreenName(index);

    return Expanded(
      flex: isActive ? 2 : 1, // Reduced flex ratio for active items
      child: GestureDetector(
        onTap: () {
          // Use the callback if provided, otherwise use the navigation service
          if (onTap != null) {
            onTap!(index);
          } else {
            navigationService.changeIndex(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          // Changed curve to make animation feel more natural
          curve: Curves.easeOutCubic,
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
                  width: 38,
                  child: Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: Icon(
                      navigationService.getScreenIcon(index),
                      color: colors.text200.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
              if (isActive) ...[
                SizedBox(
                  width: 38,
                  child: Container(
                    padding: const EdgeInsets.all(6.0),
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
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
                Flexible(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset((1 - value) * -20, 0),
                        child: Opacity(
                          opacity: value,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: colors.accent200,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (!isActive && index < activeIndex)
                SizedBox(
                  width: 38,
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
        ),
      ),
    );
  }
}
