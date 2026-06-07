import 'package:flutter/material.dart';
 
class ArcaLogo extends StatelessWidget {
  const ArcaLogo({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/frontend/assets/loho.jpeg',
      width: 160,
      height: 90,
      fit: BoxFit.contain,
    );
  }
}