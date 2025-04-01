import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

/// A custom bottom navigation bar with animated item selection.
class BottomNavBar extends StatelessWidget {
  /// Callback invoked when a navigation item is tapped.
  final void Function(int)? onTap;

  const BottomNavBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final navigationService =
        Provider.of<NavigationService>(context, listen: true);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final colors = themeProvider.currentTheme;
    final activeIndex = navigationService.currentIndex;

    return Container(
      height: 70,
      decoration: _buildContainerDecoration(colors),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          4, // Number of navigation items
          (index) => _NavItem(
            index: index,
            isActive: index == activeIndex,
            navigationService: navigationService,
            colors: colors,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  /// Builds the decoration for the navigation bar container.
  BoxDecoration _buildContainerDecoration(AppColorTheme colors) =>
      BoxDecoration(
        color: colors.bg100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      );
}

/// A single navigation item with animation and styling.
class _NavItem extends StatelessWidget {
  final int index;
  final bool isActive;
  final NavigationService navigationService;
  final AppColorTheme colors;
  final void Function(int)? onTap;

  const _NavItem({
    required this.index,
    required this.isActive,
    required this.navigationService,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = navigationService.getScreenName(index);
    final icon = navigationService.getScreenIcon(index);
    final activeIndex = navigationService.currentIndex;

    return Expanded(
      flex: isActive ? 2 : 1,
      child: GestureDetector(
        onTap: () => _handleTap(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 1.0),
          padding: EdgeInsets.symmetric(
              horizontal: isActive ? 8.0 : 4.0, vertical: 8.0),
          decoration: _buildItemDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: _getAlignment(activeIndex),
            children: _buildItemContent(label, icon),
          ),
        ),
      ),
    );
  }

  /// Handles tap events, using the provided callback or default navigation.
  void _handleTap() {
    if (onTap != null) {
      onTap!(index);
    } else {
      navigationService.changeIndex(index);
    }
  }

  /// Builds the decoration for the navigation item.
  BoxDecoration _buildItemDecoration() => BoxDecoration(
        color:
            isActive ? colors.accent200.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      );

  /// Determines the alignment of the item content based on its position.
  MainAxisAlignment _getAlignment(int activeIndex) {
    if (isActive) return MainAxisAlignment.start;
    return index < activeIndex
        ? MainAxisAlignment.start
        : MainAxisAlignment.end;
  }

  /// Builds the content of the navigation item (icon and label).
  List<Widget> _buildItemContent(String label, IconData icon) {
    if (isActive) {
      return [
        _buildActiveIcon(icon),
        const SizedBox(width: 4.0),
        _buildActiveLabel(label),
      ];
    }

    final isLeftOfActive = index < navigationService.currentIndex;
    return [
      if (!isLeftOfActive) _buildInactiveIcon(icon),
      if (isLeftOfActive) _buildInactiveIcon(icon),
    ];
  }

  /// Builds the icon for an active navigation item.
  Widget _buildActiveIcon(IconData icon) => SizedBox(
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
              ),
            ],
          ),
          child: Icon(icon, color: colors.bg100, size: 20),
        ),
      );

  /// Builds the label for an active navigation item with animation.
  Widget _buildActiveLabel(String label) => Flexible(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.translate(
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
          ),
        ),
      );

  /// Builds the icon for an inactive navigation item.
  Widget _buildInactiveIcon(IconData icon) => SizedBox(
        width: 38,
        child: Container(
          padding: const EdgeInsets.all(6.0),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(
            icon,
            color: colors.text200.withOpacity(0.7),
            size: 20,
          ),
        ),
      );
}
