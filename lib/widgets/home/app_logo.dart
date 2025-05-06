import 'package:flutter/material.dart';
import 'package:skillpe/providers/theme_provider.dart';

class AppLogo extends StatelessWidget {
  final ThemeProvider themeProvider;

  const AppLogo({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: 100,
      child: Image.asset(
        themeProvider.isDarkMode
            ? 'assets/logos/skillpe-logo-dark.png'
            : 'assets/logos/skillpe-logo-light.png',
      ),
    );
  }
}
