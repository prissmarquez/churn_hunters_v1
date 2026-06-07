import 'package:flutter/material.dart';
import 'frontend/pages/home_page.dart';
import 'frontend/theme/app_theme.dart';

void main() {
  runApp(const ArcaApp());
}

class ArcaApp extends StatelessWidget {
  const ArcaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomePage(),
    );
  }
}