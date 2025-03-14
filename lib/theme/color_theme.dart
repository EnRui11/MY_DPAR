import 'package:flutter/material.dart';

abstract class AppColorTheme {
  Color get primary100;
  Color get primary200;
  Color get primary300;
  Color get accent100;
  Color get accent200;
  Color get text100;
  Color get text200;
  Color get bg100;
  Color get bg200;
  Color get bg300;
  Color get warning;
}

class DarkAppColors implements AppColorTheme {
  @override
  final Color primary100 = const Color(0xFF1F3A5F);
  @override
  final Color primary200 = const Color(0xFF4D648D);
  @override
  final Color primary300 = const Color(0xFFACC2EF);
  @override
  final Color accent100 = const Color(0xFF3D5A80);
  @override
  final Color accent200 = const Color(0xFFCEE8FF);
  @override
  final Color text100 = const Color(0xFFFFFFFF);
  @override
  final Color text200 = const Color(0xFFE0E0E0);
  @override
  final Color bg100 = const Color(0xFF0F1C2E);
  @override
  final Color bg200 = const Color(0xFF1F2B3E);
  @override
  final Color bg300 = const Color(0xFF374357);
  @override
  final Color warning = const Color(0xFFFF3D3D);

  DarkAppColors();
}

class LightAppColors implements AppColorTheme {
  @override
  final Color primary100 = const Color(0xFFD4EAF7);
  @override
  final Color primary200 = const Color(0xFFB6CCD8);
  @override
  final Color primary300 = const Color(0xFF3B3C3D);
  @override
  final Color accent100 = const Color(0xFF71C4EF);
  @override
  final Color accent200 = const Color(0xFF00668C);
  @override
  final Color text100 = const Color(0xFF1D1C1C);
  @override
  final Color text200 = const Color(0xFF313D44);
  @override
  final Color bg100 = const Color(0xFFFFFEFB);
  @override
  final Color bg200 = const Color(0xFFF5F4F1);
  @override
  final Color bg300 = const Color(0xFFCCCBC8);
  @override
  final Color warning = const Color(0xFFFF3D3D);

  LightAppColors();
}

class AppColors {
  static final LightAppColors light = LightAppColors();
  static final DarkAppColors dark = DarkAppColors();
}
