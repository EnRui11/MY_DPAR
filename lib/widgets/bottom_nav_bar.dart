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
      decoration: BoxDecoration(
        color: colors.bg100,
        border: Border(top: BorderSide(color: colors.bg100)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, colors, navigationService),
          _buildNavItem(context, 1, colors, navigationService),
          _buildNavItem(context, 2, colors, navigationService),
          _buildNavItem(context, 3, colors, navigationService),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, 
    int index, 
    AppColorTheme colors, 
    NavigationService navigationService
  ) {
    final bool isActive = index == navigationService.currentIndex;
    
    return Container(
      decoration: BoxDecoration(
        color: isActive ? colors.accent200.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(navigationService.getScreenIcon(index)),
        color: isActive ? colors.accent200 : colors.text200,
        onPressed: () {
          // Only navigate if we're not already on this screen
          if (!isActive) {
            navigationService.navigateToIndex(context, index, replace: true);
          }
        },
        iconSize: 24,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
