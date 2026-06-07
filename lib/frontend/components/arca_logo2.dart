import 'package:flutter/material.dart';
import '../constants/app_colors2.dart';
import 'dart:io';

class ArcaLogo extends StatelessWidget {
  final double width;
  final double height;

  const ArcaLogo({this.width = 100, this.height = 100, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: Image.file(
        File('/mnt/data/image.png'),
        fit: BoxFit.contain,
      ),
    );
  }
}