import 'package:flutter/material.dart';

/// A reusable heritage parchment background container featuring the official
/// WarisanKita textured passport pattern with automatic light and dark mode adaptation.
class HeritageBackground extends StatelessWidget {
  final Widget child;
  final bool? isDark;
  final double? opacity;
  final Color? baseColor;

  const HeritageBackground({
    super.key,
    required this.child,
    this.isDark,
    this.opacity,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final effectiveColor = baseColor ??
        (effectiveIsDark ? const Color(0xFF041412) : const Color(0xFFFFF8E1));
    final effectiveOpacity = opacity ?? (effectiveIsDark ? 0.55 : 0.62);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: effectiveColor,
              image: DecorationImage(
                image: const AssetImage(
                  'assets/images/heritage_passport_background.png',
                ),
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeatY,
                opacity: effectiveOpacity,
                colorFilter: effectiveIsDark
                    ? const ColorFilter.mode(
                        Color(0xFF2A6A5C),
                        BlendMode.modulate,
                      )
                    : null,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
