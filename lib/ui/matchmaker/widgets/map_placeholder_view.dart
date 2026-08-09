import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/domain/models/nearby_artisan.dart';

class MapPlaceholderView extends StatefulWidget {
  final List<NearbyArtisan> artisans;
  final NearbyArtisan? selectedArtisan;
  final ValueChanged<NearbyArtisan> onArtisanSelected;
  final bool isLoading;

  const MapPlaceholderView({
    super.key,
    required this.artisans,
    required this.selectedArtisan,
    required this.onArtisanSelected,
    required this.isLoading,
  });

  @override
  State<MapPlaceholderView> createState() => _MapPlaceholderViewState();
}

class _MapPlaceholderViewState extends State<MapPlaceholderView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5ECE9), // Subtle map terrain color
      child: Stack(
        children: [
          // Styled Map Vector Graphics Background
          CustomPaint(
            size: Size.infinite,
            painter: _MapCanvasPainter(),
          ),

          // Map Control Buttons Overlay (Top Bar)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Live Radar Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3D3E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isLoading
                              ? 'Searching map...'
                              : '${widget.artisans.length} Artisans Nearby',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map Action Buttons (Compass & Recenter)
                  Row(
                    children: [
                      _buildMapIconButton(
                        icon: Icons.explore_outlined,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      _buildMapIconButton(
                        icon: Icons.my_location_rounded,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // User Current Location Pulse Marker
          Positioned(
            left: MediaQuery.of(context).size.width * 0.48 - 18,
            top: MediaQuery.of(context).size.height * 0.32 - 18,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.4 * _pulseController.value),
                        blurRadius: 16 * _pulseController.value + 4,
                        spreadRadius: 8 * _pulseController.value,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Artisan Map Pins
          if (!widget.isLoading)
            ...widget.artisans.map((artisan) => _buildArtisanPin(artisan)),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF0F3D3E), size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildArtisanPin(NearbyArtisan artisan) {
    final bool isSelected = widget.selectedArtisan?.id == artisan.id;

    return Positioned(
      left: MediaQuery.of(context).size.width * artisan.mapXRatio - (isSelected ? 32 : 24),
      top: MediaQuery.of(context).size.height * 0.6 * artisan.mapYRatio - (isSelected ? 70 : 54),
      child: GestureDetector(
        onTap: () => widget.onArtisanSelected(artisan),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tooltip Callout if selected
            if (isSelected)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3D3E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      artisan.name,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${artisan.craftCategory} • ${artisan.walkingTime}',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Map Pin Icon / Avatar Bubble
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 56 : 44,
              height: isSelected ? 56 : 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFD97706) : const Color(0xFF0F3D3E),
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3.5 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFFD97706).withOpacity(0.4)
                        : Colors.black26,
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  artisan.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.palette,
                      color: Colors.white,
                      size: isSelected ? 24 : 18,
                    ),
                  ),
                ),
              ),
            ),

            // Pin Point Tail
            CustomPaint(
              size: Size(isSelected ? 14 : 10, isSelected ? 8 : 6),
              painter: _PinTailPainter(
                color: isSelected ? const Color(0xFFD97706) : const Color(0xFF0F3D3E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final mainRoadPaint = Paint()
      ..color = const Color(0xFFFDE68A).withOpacity(0.6)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke;

    final riverPaint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.5)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke;

    final parkPaint = Paint()
      ..color = const Color(0xFFA7F3D0).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Draw Parks
    final parkPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.1, 120, 90),
        const Radius.circular(24),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.35, 140, 100),
        const Radius.circular(30),
      ));
    canvas.drawPath(parkPath, parkPaint);

    // Draw River Curve
    final riverPath = Path()
      ..moveTo(-20, size.height * 0.45)
      ..cubicTo(
        size.width * 0.3, size.height * 0.4,
        size.width * 0.6, size.height * 0.55,
        size.width + 20, size.height * 0.48,
      );
    canvas.drawPath(riverPath, riverPaint);

    // Draw Main Avenue
    final mainRoad = Path()
      ..moveTo(size.width * 0.4, -20)
      ..lineTo(size.width * 0.4, size.height + 20);
    canvas.drawPath(mainRoad, mainRoadPaint);

    // Draw Roads Grid
    final road1 = Path()
      ..moveTo(-20, size.height * 0.25)
      ..lineTo(size.width + 20, size.height * 0.25);
    final road2 = Path()
      ..moveTo(-20, size.height * 0.6)
      ..lineTo(size.width + 20, size.height * 0.6);
    final road3 = Path()
      ..moveTo(size.width * 0.75, -20)
      ..lineTo(size.width * 0.75, size.height + 20);

    canvas.drawPath(road1, roadPaint);
    canvas.drawPath(road2, roadPaint);
    canvas.drawPath(road3, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
