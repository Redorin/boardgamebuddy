import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../config/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image layer with heavy blur
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('img/IMAGE.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Overlay with reduced opacity for readability
        Container(color: AppColors.darkBg.withOpacity(0.5)),
        // Content on top
        child,
      ],
    );
  }
}
