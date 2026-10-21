import 'dart:io';
import 'dart:math' as math;

import 'package:anymex/controllers/custom_logo/custom_logo_service.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class AnymeXAnimatedLogo extends StatefulWidget {
  final double size;
  final bool autoPlay;
  final VoidCallback? onAnimationComplete;
  final Color? color;
  final Gradient? gradient;
  final LogoAnimationType? forceAnimationType;
  final String? forceCustomLogoPath;
  final bool? useOriginalSize;

  const AnymeXAnimatedLogo({
    super.key,
    this.size = 200,
    this.autoPlay = true,
    this.onAnimationComplete,
    this.color,
    this.gradient,
    this.forceAnimationType,
    this.forceCustomLogoPath,
    this.useOriginalSize,
  });

  @override
  State<AnymeXAnimatedLogo> createState() => _AnymeXAnimatedLogoState();
}

class _AnymeXAnimatedLogoState extends State<AnymeXAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late LogoAnimationType _animationType;
  String? _customLogoPath;
  int _replayKeyCounter = 0;

  @override
  void initState() {
    super.initState();
    _animationType = widget.forceAnimationType ?? _getStoredAnimationType();
    if (widget.forceCustomLogoPath != null) {
      _customLogoPath = widget.forceCustomLogoPath;
    } else if (widget.forceAnimationType == null) {
      _customLogoPath = CustomLogoService.getSelectedCustomLogoPath();
    }
    _controller = AnimationController(
      duration: _getDurationForAnimationType(_animationType),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _getCurveForAnimationType(_animationType),
    ));

    if (widget.autoPlay) {
      _startAnimation();
    }
  }

  LogoAnimationType _getStoredAnimationType() {
    try {
      final index = ThemeKeys.logoAnimationType.get<int>(0);
      return LogoAnimationType.fromIndex(index);
    } catch (e) {
      return LogoAnimationType.smokeTrace;
    }
  }

  Duration _getDurationForAnimationType(LogoAnimationType type) {
    switch (type) {
      case LogoAnimationType.smokeTrace:
        return const Duration(milliseconds: 5600);
      default:
        return const Duration(milliseconds: 2000);
    }
  }

  Curve _getCurveForAnimationType(LogoAnimationType type) {
    switch (type) {
      case LogoAnimationType.smokeTrace:
        return Curves.linear;
      case LogoAnimationType.bottomToTop:
      case LogoAnimationType.wave:
        return Curves.easeInOut;
      case LogoAnimationType.fadeIn:
        return Curves.easeIn;
      case LogoAnimationType.scale:
        return Curves.elasticOut;
      case LogoAnimationType.rotate:
        return Curves.easeInOutCubic;
      case LogoAnimationType.slideRight:
        return Curves.easeOutCubic;
      case LogoAnimationType.pulse:
        return Curves.easeInOut;
      case LogoAnimationType.glitch:
        return Curves.easeInOutQuad;
      case LogoAnimationType.bounce:
        return Curves.bounceOut;
      case LogoAnimationType.spiral:
        return Curves.easeInOutQuart;
      case LogoAnimationType.particleConvergence:
        return Curves.easeInOutCubic;
      case LogoAnimationType.particleExplosion:
        return Curves.easeInOutCubic;
      case LogoAnimationType.orbitalRings:
        return Curves.easeInOutQuart;
      case LogoAnimationType.pixelAssembly:
        return Curves.easeOut;
      case LogoAnimationType.liquidMorph:
        return Curves.easeInOutSine;
      case LogoAnimationType.geometricUnfold:
        return Curves.easeInOutCubic;
      case LogoAnimationType.matrixRain:
        return Curves.easeInOut;
      case LogoAnimationType.shatter:
        return Curves.easeOutBack;
      case LogoAnimationType.hologram:
        return Curves.easeInOutCubic;
      case LogoAnimationType.vortex:
        return Curves.easeInOutQuart;
    }
  }

  Future<void> _startAnimation() async {
    await _controller.forward();
    widget.onAnimationComplete?.call();
  }

  void replay() {
    setState(() {
      _replayKeyCounter++;
    });
    _controller.reset();
    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldUseOriginalSize() {
    if (widget.useOriginalSize != null) {
      return widget.useOriginalSize!;
    }
    // Don't auto-expand inside small headers, titlebars or about dialog
    if (widget.size < 150) {
      return false;
    }
    if (_customLogoPath != null) {
      final logos = CustomLogoService.getCustomLogos();
      try {
        final match = logos.firstWhere((l) => l.filePath == _customLogoPath);
        return match.useOriginalSize;
      } catch (_) {}
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isOriginal = _shouldUseOriginalSize();
    final isCustom =
        _customLogoPath != null && File(_customLogoPath!).existsSync();

    if (isCustom && isOriginal) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) =>
            _buildCustomLogoFile(_customLogoPath!, useOriginalSize: true),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Don't show anything during initial delay (except smokeTrace or custom logo which starts immediately)
          if (_animation.value < 0.05 &&
              _animationType != LogoAnimationType.smokeTrace &&
              _customLogoPath == null) {
            return const SizedBox.shrink();
          }
          return _buildAnimatedLogo();
        },
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    if (_customLogoPath != null && File(_customLogoPath!).existsSync()) {
      return _buildCustomLogoFile(_customLogoPath!);
    }

    switch (_animationType) {
      case LogoAnimationType.bottomToTop:
        return _buildBottomToTopLogo();
      case LogoAnimationType.fadeIn:
        return _buildFadeInLogo();
      case LogoAnimationType.scale:
        return _buildScaleLogo();
      case LogoAnimationType.rotate:
        return _buildRotateLogo();
      case LogoAnimationType.slideRight:
        return _buildSlideRightLogo();
      case LogoAnimationType.pulse:
        return _buildPulseLogo();
      case LogoAnimationType.glitch:
        return _buildGlitchLogo();
      case LogoAnimationType.bounce:
        return _buildBounceLogo();
      case LogoAnimationType.wave:
        return _buildWaveLogo();
      case LogoAnimationType.spiral:
        return _buildSpiralLogo();
      case LogoAnimationType.particleConvergence:
        return _buildParticleConvergenceLogo();
      case LogoAnimationType.particleExplosion:
        return _buildParticleExplosionLogo();
      case LogoAnimationType.orbitalRings:
        return _buildOrbitalRingsLogo();
      case LogoAnimationType.pixelAssembly:
        return _buildPixelAssemblyLogo();
      case LogoAnimationType.liquidMorph:
        return _buildLiquidMorphLogo();
      case LogoAnimationType.geometricUnfold:
        return _buildGeometricUnfoldLogo();
      case LogoAnimationType.matrixRain:
        return _buildMatrixRainLogo();
      case LogoAnimationType.shatter:
        return _buildShatterLogo();
      case LogoAnimationType.hologram:
        return _buildHologramLogo();
      case LogoAnimationType.vortex:
        return _buildVortexLogo();
      case LogoAnimationType.smokeTrace:
        return _buildSmokeTraceLogo();
    }
  }

  // custom logo file
  Widget _buildCustomLogoFile(String filePath,
      {bool useOriginalSize = false}) {
    Widget content = Image.file(
      File(filePath),
      key: ValueKey('custom_logo_${filePath}_$_replayKeyCounter'),
      width: useOriginalSize ? null : widget.size,
      height: useOriginalSize ? null : widget.size,
      fit: useOriginalSize ? BoxFit.scaleDown : BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return _buildBaseLogo(100);
      },
    );

    if (widget.gradient != null) {
      content = ShaderMask(
        shaderCallback: (bounds) => widget.gradient!.createShader(bounds),
        blendMode: BlendMode.modulate,
        child: content,
      );
    } else if (widget.color != null) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(
          widget.color!,
          BlendMode.modulate,
        ),
        child: content,
      );
    }

    return content;
  }

  // smoke trace (animated GIF/WebP)
  Widget _buildSmokeTraceLogo() {
    Widget content = Image.asset(
      'assets/images/logo_smoke.webp',
      key: ValueKey('smoke_logo_$_replayKeyCounter'),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/logo_smoke.gif',
          key: ValueKey('smoke_logo_gif_$_replayKeyCounter'),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
      },
    );

    if (widget.gradient != null) {
      content = ShaderMask(
        shaderCallback: (bounds) => widget.gradient!.createShader(bounds),
        blendMode: BlendMode.modulate,
        child: content,
      );
    } else if (widget.color != null) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(
          widget.color!,
          BlendMode.modulate,
        ),
        child: content,
      );
    }

    return content;
  }

  // bottom to top
  Widget _buildBottomToTopLogo() {
    return ClipRect(
      child: _buildBaseLogo(_animation.value * 100),
    );
  }

  // fade in
  Widget _buildFadeInLogo() {
    final scale = 0.95 + (_animation.value * 0.05);
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  // scale
  Widget _buildScaleLogo() {
    return Transform.scale(
      scale: _animation.value,
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: _buildBaseLogo(100),
      ),
    );
  }

  // rotation
  Widget _buildRotateLogo() {
    final rotationAngle = (1 - _animation.value) * math.pi * 1.5;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateY(rotationAngle),
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  // horizontal slide
  Widget _buildSlideRightLogo() {
    final slideValue = Curves.easeOutCubic.transform(_animation.value);
    return Transform.translate(
      offset: Offset((1 - slideValue) * -widget.size * 1.2, 0),
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: _buildBaseLogo(100),
      ),
    );
  }

  // pulse
  Widget _buildPulseLogo() {
    final pulseScale = 0.85 +
        (math.sin(_animation.value * math.pi * 3) * 0.08) +
        (_animation.value * 0.15);
    final glowIntensity = math.sin(_animation.value * math.pi * 2) * 0.3;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (glowIntensity > 0)
          Opacity(
            opacity: glowIntensity,
            child: Transform.scale(
              scale: pulseScale * 1.15,
              child: _buildBaseLogo(100),
            ),
          ),
        Transform.scale(
          scale: pulseScale,
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: _buildBaseLogo(100),
          ),
        ),
      ],
    );
  }

  // glitch
  Widget _buildGlitchLogo() {
    final phase = (_animation.value * 5) % 1.0;
    final glitchActive = phase > 0.85;
    final glitchOffset =
        glitchActive ? (math.Random().nextDouble() - 0.5) * 8 : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (glitchActive)
          Transform.translate(
            offset: Offset(-glitchOffset * 1.5, glitchOffset * 0.5),
            child: Opacity(
              opacity: 0.4,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.cyan.opaque(0.7, iReallyMeanIt: true),
                  BlendMode.modulate,
                ),
                child: _buildBaseLogo(100),
              ),
            ),
          ),
        if (glitchActive)
          Transform.translate(
            offset: Offset(glitchOffset * 1.5, -glitchOffset * 0.5),
            child: Opacity(
              opacity: 0.4,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.red.opaque(0.7, iReallyMeanIt: true),
                  BlendMode.modulate,
                ),
                child: _buildBaseLogo(100),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(glitchOffset * 0.3, 0),
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: _buildBaseLogo(100),
          ),
        ),
      ],
    );
  }

  // bounce
  Widget _buildBounceLogo() {
    final bounceProgress = Curves.bounceOut.transform(_animation.value);
    return Transform.translate(
      offset: Offset(0, (1 - bounceProgress) * -widget.size * 0.6),
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: _buildBaseLogo(100),
      ),
    );
  }

  // Professional wave animation with fluid motion
  Widget _buildWaveLogo() {
    final wavePhase = _animation.value * math.pi * 2;
    final waveAmplitude = (1 - _animation.value) * 12;
    final xOffset = math.sin(wavePhase) * waveAmplitude;
    final yOffset = math.cos(wavePhase * 1.5) * waveAmplitude * 0.5;

    return Transform.translate(
      offset: Offset(xOffset, yOffset),
      child: Transform.rotate(
        angle: math.sin(wavePhase) * 0.08,
        child: Opacity(
          opacity: _animation.value.clamp(0.0, 1.0),
          child: _buildBaseLogo(_animation.value * 100),
        ),
      ),
    );
  }

  // spiral
  Widget _buildSpiralLogo() {
    final spiralAngle = (1 - _animation.value) * math.pi * 3;
    final spiralScale = _animation.value * _animation.value;
    final distance = (1 - _animation.value) * widget.size * 0.3;

    return Transform.translate(
      offset: Offset(
        math.cos(spiralAngle) * distance,
        math.sin(spiralAngle) * distance,
      ),
      child: Transform.rotate(
        angle: spiralAngle,
        child: Transform.scale(
          scale: spiralScale,
          child: Opacity(
            opacity: _animation.value,
            child: _buildBaseLogo(100),
          ),
        ),
      ),
    );
  }

  // PARTICLE CONVERGENCE
  Widget _buildParticleConvergenceLogo() {
    // Adjust timing so animation starts after initial delay
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final particlePhase = adjustedProgress.clamp(0.0, 0.5) / 0.5;
    final convergePhase = (adjustedProgress - 0.4).clamp(0.0, 0.5) / 0.5;
    final logoPhase = (adjustedProgress - 0.7).clamp(0.0, 0.3) / 0.3;

    final particles = List.generate(16, (index) {
      final angle = (index / 16) * 2 * math.pi;
      final radius = widget.size * 0.5;
      final startX = math.cos(angle) * radius;
      final startY = math.sin(angle) * radius;

      final spiralFactor = math.sin(particlePhase * math.pi * 2 + index * 0.3);
      final moveX = startX + (math.cos(angle + spiralFactor) * 40);
      final moveY = startY + (math.sin(angle + spiralFactor) * 40);

      final currentX = convergePhase < 1.0 ? moveX * (1 - convergePhase) : 0.0;
      final currentY = convergePhase < 1.0 ? moveY * (1 - convergePhase) : 0.0;

      final colorPhase = (particlePhase + (index / 16)) % 1.0;
      final particleColor =
          HSVColor.fromAHSV(1.0, colorPhase * 360, 0.9, 1.0).toColor();
      final particleSize =
          10.0 + (math.sin(particlePhase * math.pi + index) * 4);
      final particleOpacity =
          convergePhase < 0.9 ? 1.0 : 1.0 - ((convergePhase - 0.9) / 0.1);

      return Positioned(
        left: widget.size / 2 + currentX - particleSize / 2,
        top: widget.size / 2 + currentY - particleSize / 2,
        child: Opacity(
          opacity: particleOpacity,
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              color: particleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: particleColor.opaque(0.8, iReallyMeanIt: true),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...particles,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // PARTICLE EXPLOSION
  Widget _buildParticleExplosionLogo() {
    // Adjust timing
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final initialPhase = (adjustedProgress.clamp(0.0, 0.2) / 0.2);
    final explosionPhase = (adjustedProgress.clamp(0.2, 0.5) / 0.3);
    final reformPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final logoOpacity = adjustedProgress < 0.2
        ? 1.0 - initialPhase
        : adjustedProgress > 0.6
            ? reformPhase
            : 0.0;
    final particles = List.generate(24, (index) {
      final angle = (index / 24) * 2 * math.pi;
      final speed = 0.8 + (math.Random(index).nextDouble() * 0.4);
      final distance = explosionPhase * widget.size * 0.9 * speed;
      final x = math.cos(angle) * distance * (1 - reformPhase);
      final y = math.sin(angle) * distance * (1 - reformPhase);

      final rotation = explosionPhase * math.pi * 6 * (1 - reformPhase);
      final particleOpacity =
          adjustedProgress > 0.15 && adjustedProgress < 0.85 ? 1.0 : 0.0;

      final colorIndex = (index / 24);
      final color =
          HSVColor.fromAHSV(1.0, colorIndex * 360, 0.95, 1.0).toColor();
      final particleSize = 8.0 + (index % 3) * 3.0;

      return Positioned(
        left: widget.size / 2 + x - particleSize / 2,
        top: widget.size / 2 + y - particleSize / 2,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: particleOpacity,
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [color, color.opaque(0.6, iReallyMeanIt: true)],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.opaque(0.6, iReallyMeanIt: true),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...particles,
        if (logoOpacity > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoOpacity),
            child: Opacity(
              opacity: logoOpacity,
              child: _buildBaseLogo(logoOpacity * 100),
            ),
          ),
      ],
    );
  }

  // ORBITAL RINGS
  Widget _buildOrbitalRingsLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final ringPhase = adjustedProgress.clamp(0.0, 0.7) / 0.7;
    final logoPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final rings = List.generate(5, (index) {
      final ringSize = widget.size * (0.3 + (index * 0.18));
      final rotationSpeed = (index % 2 == 0 ? 1 : -1) * (1 + index * 0.3);
      final rotation = ringPhase * math.pi * 2.5 * rotationSpeed;
      final scale = 1.2 - (ringPhase * (0.9 - index * 0.12));
      final opacity = (1.0 - ringPhase) * (1.0 - index * 0.15);

      final colors = [
        Colors.cyan,
        Colors.purple,
        Colors.pink,
        Colors.amber,
        Colors.teal,
      ];

      return Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors[index],
                  width: 3.0 + (index * 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[index].opaque(0.5, iReallyMeanIt: true),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...rings,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // PIXEL ASSEMBLY
  Widget _buildPixelAssemblyLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;
    final assemblyPhase = adjustedProgress;
    final logoPhase = (adjustedProgress - 0.7).clamp(0.0, 0.3) / 0.3;

    const gridSize = 10;
    final pixels = <Widget>[];

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final pixelIndex = i * gridSize + j;
        const totalPixels = gridSize * gridSize;
        final random = math.Random(pixelIndex);
        final appearTime = (random.nextDouble() * 0.5) + 0.1;
        final pixelProgress =
            (assemblyPhase - appearTime).clamp(0.0, 0.3) / 0.3;

        if (pixelProgress > 0) {
          final pixelSize = widget.size / gridSize;
          final startAngle = random.nextDouble() * math.pi * 2;
          final startDistance = random.nextDouble() * widget.size * 1.5;
          final startX = math.cos(startAngle) * startDistance;
          final startY = math.sin(startAngle) * startDistance;

          final currentX = startX * (1 - pixelProgress);
          final currentY = startY * (1 - pixelProgress);

          final colorValue = (pixelIndex / totalPixels);
          final color = HSVColor.fromAHSV(
            1.0,
            (colorValue * 360 + assemblyPhase * 60) % 360,
            0.8,
            0.95,
          ).toColor();

          pixels.add(
            Positioned(
              left: (i * pixelSize) + currentX,
              top: (j * pixelSize) + currentY,
              child: Transform.rotate(
                angle: (1 - pixelProgress) * math.pi * 2,
                child: Opacity(
                  opacity: pixelProgress,
                  child: Container(
                    width: pixelSize - 1.5,
                    height: pixelSize - 1.5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: color.opaque(0.4, iReallyMeanIt: true),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (assemblyPhase < 0.8)
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(children: pixels),
          ),
        if (logoPhase > 0)
          Opacity(
            opacity: logoPhase,
            child: _buildBaseLogo(logoPhase * 100),
          ),
      ],
    );
  }

  // LIQUID MORPH
  Widget _buildLiquidMorphLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final dropPhase = adjustedProgress.clamp(0.0, 0.4) / 0.4;
    final mergePhase = (adjustedProgress - 0.3).clamp(0.0, 0.5) / 0.5;
    final logoPhase = (adjustedProgress - 0.6).clamp(0.0, 0.4) / 0.4;

    final drops = List.generate(10, (index) {
      final angle = (index / 10) * 2 * math.pi;
      final radius = widget.size * 0.45;
      final startX = math.cos(angle) * radius;
      final startY = math.sin(angle) * radius - widget.size * 0.4;

      final gravity = dropPhase * dropPhase;
      final bounceHeight = startY + (widget.size * 0.4 * gravity);
      final elasticity =
          dropPhase > 0.8 ? math.sin((dropPhase - 0.8) * math.pi * 5) * 5 : 0.0;

      final currentX = startX * (1 - mergePhase);
      final currentY = (bounceHeight + elasticity) * (1 - mergePhase);

      final dropSize = 12.0 +
          (mergePhase * 15) +
          (math.sin(dropPhase * math.pi * 3 + index) * 3);
      final opacity = adjustedProgress < 0.75 ? 1.0 : 1.0 - logoPhase;

      final colors = [
        Colors.blue.shade400,
        Colors.cyan.shade400,
        Colors.teal.shade400,
        Colors.lightBlue.shade300,
        Colors.indigo.shade400,
        Colors.blue.shade600,
        Colors.cyan.shade600,
        Colors.teal.shade600,
        Colors.lightBlue.shade500,
        Colors.indigo.shade600,
      ];

      return Positioned(
        left: widget.size / 2 + currentX - dropSize / 2,
        top: widget.size / 2 + currentY - dropSize / 2,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: dropSize,
            height: dropSize,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colors[index].opaque(0.9, iReallyMeanIt: true),
                  colors[index],
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[index].opaque(0.6, iReallyMeanIt: true),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...drops,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // GEOMETRIC UNFOLD
  Widget _buildGeometricUnfoldLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final unfoldPhase = adjustedProgress.clamp(0.0, 0.7) / 0.7;
    final logoPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final shapes = List.generate(8, (index) {
      final angle = (index / 8) * 2 * math.pi;
      final distance = (1 - unfoldPhase) * widget.size * 0.6;
      final x = math.cos(angle) * distance;
      final y = math.sin(angle) * distance;

      final rotation = unfoldPhase * math.pi * 3 + (index * math.pi / 4);
      final scale = 1.2 - (unfoldPhase * 0.7);

      final shapeColors = [
        Colors.red.shade400,
        Colors.orange.shade400,
        Colors.amber.shade400,
        Colors.lime.shade400,
        Colors.green.shade400,
        Colors.cyan.shade400,
        Colors.blue.shade400,
        Colors.purple.shade400,
      ];

      Widget shape;
      final shapeType = index % 4;

      if (shapeType == 0) {
        shape = CustomPaint(
          size: const Size(45, 45),
          painter: _TrianglePainter(shapeColors[index]),
        );
      } else if (shapeType == 1) {
        shape = Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: shapeColors[index],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: shapeColors[index].opaque(0.6, iReallyMeanIt: true),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      } else if (shapeType == 2) {
        shape = Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: shapeColors[index],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shapeColors[index].opaque(0.6, iReallyMeanIt: true),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      } else {
        shape = Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: shapeColors[index],
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: shapeColors[index].opaque(0.6, iReallyMeanIt: true),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      }

      return Positioned(
        left: widget.size / 2 + x - 22.5,
        top: widget.size / 2 + y - 22.5,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: 1.0 - unfoldPhase,
              child: shape,
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...shapes,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // MATRIX RAIN
  Widget _buildMatrixRainLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final rainPhase = adjustedProgress.clamp(0.0, 0.6) / 0.6;
    final formPhase = (adjustedProgress - 0.4).clamp(0.0, 0.6) / 0.6;
    final logoPhase = (adjustedProgress - 0.7).clamp(0.0, 0.3) / 0.3;

    const columns = 15;
    final rainDrops = List.generate(columns, (col) {
      final drops = <Widget>[];
      const dropsPerColumn = 8;

      for (int row = 0; row < dropsPerColumn; row++) {
        final random = math.Random(col * 100 + row);
        final dropDelay = random.nextDouble() * 0.3;
        final dropProgress = (rainPhase - dropDelay).clamp(0.0, 1.0);

        if (dropProgress > 0) {
          final x = (col / columns) * widget.size;
          final fallDistance = dropProgress * widget.size * 1.3;
          final y = -20.0 + fallDistance - (row * 25);

          final opacity =
              dropProgress < 0.8 ? 1.0 : 1.0 - ((dropProgress - 0.8) / 0.2);
          final fade = formPhase > 0 ? 1.0 - formPhase : 1.0;

          final brightness = 1.0 - (row / dropsPerColumn) * 0.6;

          drops.add(
            Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: opacity * fade,
                child: Container(
                  width: widget.size / columns * 0.8,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.lightGreen
                            .opaque(brightness, iReallyMeanIt: true),
                        Colors.green
                            .opaque(brightness * 0.3, iReallyMeanIt: true),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green
                            .opaque(0.5 * brightness, iReallyMeanIt: true),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnymeXText(
                      String.fromCharCode(33 + random.nextInt(94)),
                      style: TextStyle(
                        color: Colors.white
                            .opaque(brightness, iReallyMeanIt: true),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      return drops;
    }).expand((x) => x).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        if (formPhase < 1.0) ...rainDrops,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // SHATTER
  Widget _buildShatterLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final shatterPhase = adjustedProgress.clamp(0.0, 0.5) / 0.5;
    final reformPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final shards = List.generate(20, (index) {
      final angle = (index / 20) * 2 * math.pi;
      final random = math.Random(index);
      final distance =
          shatterPhase * widget.size * (0.6 + random.nextDouble() * 0.4);
      final x = math.cos(angle) * distance * (1 - reformPhase);
      final y = math.sin(angle) * distance * (1 - reformPhase);

      final rotation = shatterPhase *
          (random.nextDouble() * math.pi * 4 - math.pi * 2) *
          (1 - reformPhase);
      final scale = 0.3 + (shatterPhase * 0.7) * (1 - reformPhase * 0.5);

      final shardOpacity = adjustedProgress < 0.2
          ? 1.0 - (adjustedProgress / 0.2)
          : adjustedProgress > 0.8
              ? reformPhase
              : 0.8;

      final colors = [
        Colors.cyan.shade200,
        Colors.blue.shade200,
        Colors.lightBlue.shade200,
        Colors.teal.shade200,
      ];
      final color = colors[index % colors.length];

      return Positioned(
        left: widget.size / 2 + x - 25,
        top: widget.size / 2 + y - 25,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: shardOpacity,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.opaque(0.3, iReallyMeanIt: true),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.opaque(0.5, iReallyMeanIt: true),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.opaque(0.4, iReallyMeanIt: true),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });

    final logoOpacity = adjustedProgress < 0.15
        ? 1.0 - (adjustedProgress / 0.15)
        : adjustedProgress > 0.7
            ? reformPhase
            : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (adjustedProgress > 0.1 && adjustedProgress < 0.9) ...shards,
        if (logoOpacity > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoOpacity),
            child: Opacity(
              opacity: logoOpacity,
              child: _buildBaseLogo(logoOpacity * 100),
            ),
          ),
      ],
    );
  }

  // HOLOGRAM
  Widget _buildHologramLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final scanPhase = adjustedProgress.clamp(0.0, 0.6) / 0.6;
    final stabilizePhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final flickerOffset = adjustedProgress < 0.7
        ? math.sin(adjustedProgress * math.pi * 30) * 2 * (1 - stabilizePhase)
        : 0.0;

    final scanLineY = -widget.size + (scanPhase * widget.size * 2);
    final glitchActive = adjustedProgress > 0.3 &&
        adjustedProgress < 0.6 &&
        ((adjustedProgress * 20) % 1.0) > 0.8;

    final logoOpacity = adjustedProgress.clamp(0.2, 0.9);
    final hologramColor = Colors.cyan.shade400;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (scanPhase < 1.0)
          Positioned(
            top: scanLineY,
            child: Container(
              width: widget.size,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    hologramColor,
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: hologramColor.opaque(0.8, iReallyMeanIt: true),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        if (glitchActive)
          Transform.translate(
            offset: Offset(flickerOffset * 3, 0),
            child: Opacity(
              opacity: 0.3,
              child: _buildBaseLogo(logoOpacity * 100),
            ),
          ),
        Transform.translate(
          offset: Offset(flickerOffset, 0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.4 * logoOpacity,
                child: Transform.scale(
                  scale: 1.1,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      hologramColor,
                      BlendMode.srcATop,
                    ),
                    child: _buildBaseLogo(logoOpacity * 100),
                  ),
                ),
              ),
              Opacity(
                opacity: logoOpacity * 0.9,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    hologramColor.opaque(0.6, iReallyMeanIt: true),
                    BlendMode.modulate,
                  ),
                  child: _buildBaseLogo(logoOpacity * 100),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(8, (index) {
          return Positioned(
            top: (index / 8) * widget.size,
            child: Opacity(
              opacity: 0.1 * logoOpacity,
              child: Container(
                width: widget.size,
                height: 1,
                color: Colors.cyan.shade100,
              ),
            ),
          );
        }),
      ],
    );
  }

  // VORTEX
  Widget _buildVortexLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final vortexPhase = adjustedProgress.clamp(0.0, 0.7) / 0.7;
    final logoPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final rings = List.generate(12, (index) {
      final progress = (vortexPhase - (index * 0.05)).clamp(0.0, 1.0);
      final ringSize = widget.size * (0.1 + index * 0.08) * progress;
      final depth = (1 - progress) * 0.8;
      final rotation = progress * math.pi * 6 + (index * math.pi / 6);

      final opacity = progress < 0.8
          ? (progress * 1.2).clamp(0.0, 1.0)
          : 1.0 - ((progress - 0.8) / 0.2);

      final zDepth = 1.0 - (depth * 0.5);

      final colors = [
        Colors.purple.shade400,
        Colors.deepPurple.shade400,
        Colors.indigo.shade400,
        Colors.blue.shade400,
      ];
      final color = colors[index % colors.length];

      return Transform.scale(
        scale: zDepth,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: opacity * (1 - logoPhase),
            child: Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.opaque(0.6, iReallyMeanIt: true),
                    blurRadius: 12 * zDepth,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...rings,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX((1 - logoPhase) * math.pi * 0.5),
              child: Opacity(
                opacity: logoPhase,
                child: _buildBaseLogo(logoPhase * 100),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBaseLogo(double fillHeight) {
    // Logo di Shinra: appare gradualmente durante le animazioni.
    return Opacity(
      opacity: (fillHeight / 100).clamp(0.0, 1.0),
      child: Image.asset(
        'assets/images/logo_glyph.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawShadow(path, color.opaque(0.5, iReallyMeanIt: true), 10.0, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
