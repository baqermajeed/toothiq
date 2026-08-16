import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// إعدادات التدرج والتلاشي لرؤوس الصفحات الزجاجية
abstract final class PinnedBlurHeaderStyle {
  static List<Color> gradientColors() => [
        AppColors.primarySoft.withValues(alpha: 0.92),
        AppColors.primarySoft.withValues(alpha: 0.72),
        AppColors.primaryLight.withValues(alpha: 0.28),
        AppColors.background.withValues(alpha: 0.04),
      ];

  static const List<double> gradientStops = [0.0, 0.35, 0.70, 1.0];

  static const List<double> fadeStops = [0.0, 0.55, 0.85, 1.0];

  /// تلاشي أخف من الأسفل — للهيدر المثبت بعد السكرول
  static const List<double> compactFadeStops = [0.0, 0.50, 0.82, 1.0];

  static const List<Color> defaultFadeMaskColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0xAAFFFFFF),
    Color(0x00FFFFFF),
  ];

  static const List<Color> compactFadeMaskColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0xE6FFFFFF),
    Color(0x88FFFFFF),
  ];

  static const double strongBlurSigma = 44;
  static const double mediumBlurSigma = 24;
  static const double lightBlurSigma = 8;
  static const double strongBlurMaskEnd = 0.48;

  static Shader fadeMaskShader(
    Rect bounds,
    List<double> stops, {
    List<Color>? colors,
  }) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors ?? defaultFadeMaskColors,
      stops: stops,
    ).createShader(bounds);
  }
}

/// خلفية التغويش المتدرج + التدرج اللوني للهيدر
class PinnedBlurGradientBackground extends StatelessWidget {
  const PinnedBlurGradientBackground({
    super.key,
    this.fadeStops = PinnedBlurHeaderStyle.fadeStops,
    this.fadeMaskColors,
    this.strongBlurSigma = PinnedBlurHeaderStyle.strongBlurSigma,
    this.mediumBlurSigma = PinnedBlurHeaderStyle.mediumBlurSigma,
    this.lightBlurSigma = PinnedBlurHeaderStyle.lightBlurSigma,
    this.strongBlurMaskEnd = PinnedBlurHeaderStyle.strongBlurMaskEnd,
  });

  final List<double> fadeStops;
  final List<Color>? fadeMaskColors;
  final double strongBlurSigma;
  final double mediumBlurSigma;
  final double lightBlurSigma;
  final double strongBlurMaskEnd;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => PinnedBlurHeaderStyle.fadeMaskShader(
        bounds,
        fadeStops,
        colors: fadeMaskColors,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _MaskedBlurLayer(
            sigma: strongBlurSigma,
            maskStops: [0.0, strongBlurMaskEnd, 1.0],
            maskColors: const [
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
          ),
          _MaskedBlurLayer(
            sigma: mediumBlurSigma,
            maskStops: const [0.0, 0.5, 1.0],
            maskColors: const [
              Colors.transparent,
              Colors.white,
              Colors.transparent,
            ],
          ),
          _MaskedBlurLayer(
            sigma: lightBlurSigma,
            maskStops: const [0.0, 0.75, 1.0],
            maskColors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
            ],
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: PinnedBlurHeaderStyle.gradientColors(),
                stops: PinnedBlurHeaderStyle.gradientStops,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaskedBlurLayer extends StatelessWidget {
  const _MaskedBlurLayer({
    required this.sigma,
    required this.maskStops,
    required this.maskColors,
  });

  final double sigma;
  final List<double> maskStops;
  final List<Color> maskColors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: maskColors,
        stops: maskStops,
      ).createShader(bounds),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: const ColoredBox(color: Color(0x01FFFFFF)),
      ),
    );
  }
}
