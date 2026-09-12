import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A dynamic, auto-rotating image carousel for artisan cards.
/// Automatically transitions pictures only when the card is actively in the user's viewport.
/// Pauses automatically when scrolled off-screen or during user interaction.
class RotatingArtisanImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final Duration interval;
  final BorderRadius borderRadius;
  final Widget? topLeading;
  final Widget? topTrailing;
  final Widget? bottomContent;
  final VoidCallback? onTap;

  const RotatingArtisanImageCarousel({
    super.key,
    required this.images,
    this.height = 195.0,
    this.interval = const Duration(seconds: 3),
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(28)),
    this.topLeading,
    this.topTrailing,
    this.bottomContent,
    this.onTap,
  });

  @override
  State<RotatingArtisanImageCarousel> createState() =>
      _RotatingArtisanImageCarouselState();
}

class _RotatingArtisanImageCarouselState
    extends State<RotatingArtisanImageCarousel> {
  late final PageController _pageController;
  Timer? _rotationTimer;
  int _currentIndex = 0;
  bool _isInteracting = false;

  List<String> get _safeImages {
    if (widget.images.isEmpty) {
      return const [
        'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
      ];
    }
    return widget.images;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoRotation();
  }

  @override
  void didUpdateWidget(covariant RotatingArtisanImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length ||
        oldWidget.interval != widget.interval) {
      _restartAutoRotation();
    }
  }

  @override
  void dispose() {
    _stopAutoRotation();
    _pageController.dispose();
    super.dispose();
  }

  bool _isWidgetVisibleInViewport() {
    if (!mounted) return false;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;

    try {
      final position = renderObject.localToGlobal(Offset.zero);
      final size = renderObject.size;
      final mediaQuery = MediaQuery.maybeOf(context);
      final screenHeight = mediaQuery?.size.height ?? 800.0;
      final screenWidth = mediaQuery?.size.width ?? 400.0;

      final widgetTop = position.dy;
      final widgetBottom = position.dy + size.height;
      final widgetLeft = position.dx;
      final widgetRight = position.dx + size.width;

      // Check if at least 40% of the card is within the visible viewport bounds
      final visibleTop = widgetTop.clamp(0.0, screenHeight);
      final visibleBottom = widgetBottom.clamp(0.0, screenHeight);
      final visibleHeight = (visibleBottom - visibleTop).clamp(0.0, size.height);

      final isVerticallyVisible = visibleHeight >= (size.height * 0.40);
      final isHorizontallyVisible = widgetRight > 0 && widgetLeft < screenWidth;

      return isVerticallyVisible && isHorizontallyVisible;
    } catch (_) {
      return false;
    }
  }

  void _startAutoRotation() {
    _stopAutoRotation();
    if (_safeImages.length <= 1) return;

    _rotationTimer = Timer.periodic(widget.interval, (_) {
      if (!mounted || _isInteracting) return;
      if (!_pageController.hasClients) return;

      // Only advance when the card is currently visible in the user's viewport
      if (!_isWidgetVisibleInViewport()) {
        return;
      }

      final nextPage = (_currentIndex + 1) % _safeImages.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  void _restartAutoRotation() {
    _stopAutoRotation();
    _startAutoRotation();
  }

  void _onUserTouchStart() {
    _isInteracting = true;
    _stopAutoRotation();
  }

  void _onUserTouchEnd() {
    _isInteracting = false;
    // Resume auto-rotation after user interaction ends
    _rotationTimer?.cancel();
    _rotationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isInteracting) {
        _startAutoRotation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = _safeImages;
    final hasMultipleImages = images.length > 1;

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Interactive PageView for Images
              Listener(
                onPointerDown: (_) => _onUserTouchStart(),
                onPointerUp: (_) => _onUserTouchEnd(),
                onPointerCancel: (_) => _onUserTouchEnd(),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: images.length,
                  onPageChanged: (index) {
                    if (mounted) {
                      setState(() => _currentIndex = index);
                    }
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];
                    return Image.network(
                      imageUrl,
                      height: widget.height,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF0F172A),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFFFD54F),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF0F172A),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.palette_outlined,
                                  color: Color(0xFFFFD54F),
                                  size: 36,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Warisan Gallery',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 2. Cinematic Dual-Gradient Scrim
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Top Leading Widget (e.g., "VERIFIED MASTER")
              if (widget.topLeading != null)
                Positioned(
                  top: 14,
                  left: 14,
                  child: widget.topLeading!,
                ),

              // 4. Optional top-trailing quest XP badge.
              if (widget.topTrailing != null)
                Positioned(
                  top: 14,
                  right: 14,
                  child: widget.topTrailing!,
                ),

              // 5. Floating Photo Counter Pill (Bottom Right Above Bottom Content)
              if (hasMultipleImages)
                Positioned(
                  bottom: widget.bottomContent != null ? 48 : 12,
                  right: 14,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_rounded,
                            size: 11,
                            color: Color(0xFFFFD54F),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentIndex + 1}/${images.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 6. Bottom Content Strip (e.g. Studio name, Experience)
              if (widget.bottomContent != null)
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: widget.bottomContent!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
