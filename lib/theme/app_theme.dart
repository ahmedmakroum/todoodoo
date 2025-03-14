import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: FlexColor.schemes[FlexScheme.deepPurple]!.light,
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarStyle: FlexAppBarStyle.material,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 9,
      subThemesData: FlexSubThemesData(
        textButtonRadius: 12,
        fabRadius: 12,
        cardRadius: 12,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: FlexColor.schemes[FlexScheme.deepPurple]!.dark,
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarStyle: FlexAppBarStyle.material,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 15,
      subThemesData: FlexSubThemesData(
        textButtonRadius: 12,
        fabRadius: 12,
        cardRadius: 12,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
