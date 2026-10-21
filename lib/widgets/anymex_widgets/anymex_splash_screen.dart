import 'package:flutter/material.dart';

/// Schermata di avvio di Shinra: immagine a tutto schermo diversa per
/// verticale e orizzontale.
class AnymeXSplashScreen extends StatelessWidget {
  final VoidCallback? onAnimationComplete;

  const AnymeXSplashScreen({
    super.key,
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image.asset(
          isLandscape
              ? 'assets/images/splash_landscape.jpg'
              : 'assets/images/splash_portrait.jpg',
          // In verticale riempie lo schermo; in orizzontale resta intera
          // con i bordi sfumati nel nero.
          fit: isLandscape ? BoxFit.contain : BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
