import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/screens/officer/services/officer_nav_service.dart';
import 'package:mydpar/theme/color_theme.dart';
import 'package:mydpar/theme/theme_provider.dart';

class OfficerNavBar extends StatelessWidget {
  final void Function(int)? onTap;
  final VoidCallback? onBack;

  const OfficerNavBar({
    super.key,
    this.onTap,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<OfficerNavigationService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.currentTheme;
    final activeIndex = navigationService.currentIndex;

    return Container(
      height: 70,
      decoration: _buildContainerDecoration(colors),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBackButton(colors, context),
            ...List.generate(
              4,
              (index) => _OfficerNavItem(
                index: index,
                isActive: index == activeIndex,
                navigationService: navigationService,
                colors: colors,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildBackButton(AppColorTheme colors, BuildContext context) =>
      IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: colors.text200,
        ),
        onPressed: onBack ?? () => Navigator.pop(context),
      );
}

class _OfficerNavItem extends StatelessWidget {
  final int index;
  final bool isActive;
  final OfficerNavigationService navigationService;
  final AppColorTheme colors;
  final void Function(int)? onTap;

  const _OfficerNavItem({
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

  void _handleTap() {
    if (onTap != null) {
      onTap!(index);
    } else {
      navigationService.changeIndex(index);
    }
  }

  BoxDecoration _buildItemDecoration() => BoxDecoration(
        color:
            isActive ? colors.accent200.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      );

  MainAxisAlignment _getAlignment(int activeIndex) {
    if (isActive) return MainAxisAlignment.start;
    return index < activeIndex
        ? MainAxisAlignment.start
        : MainAxisAlignment.end;
  }

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
