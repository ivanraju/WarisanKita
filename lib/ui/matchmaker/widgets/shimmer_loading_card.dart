import 'package:flutter/material.dart';

class ShimmerLoadingCard extends StatefulWidget {
  const ShimmerLoadingCard({super.key});

  @override
  State<ShimmerLoadingCard> createState() => _ShimmerLoadingCardState();
}

class _ShimmerLoadingCardState extends State<ShimmerLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = isDark ? const Color(0xFF1E3A34) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF041412) : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2825) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1E3A34) : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Skeleton Image
              _buildShimmerBox(
                width: 90,
                height: 90,
                borderRadius: BorderRadius.circular(16),
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
              const SizedBox(width: 14),
              // Skeleton Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Chip Skeleton
                    _buildShimmerBox(
                      width: 80,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 8),
                    // Name Skeleton
                    _buildShimmerBox(
                      width: 160,
                      height: 20,
                      borderRadius: BorderRadius.circular(6),
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 10),
                    // Walking time & button row skeleton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildShimmerBox(
                          width: 90,
                          height: 14,
                          borderRadius: BorderRadius.circular(6),
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                        ),
                        _buildShimmerBox(
                          width: 85,
                          height: 32,
                          borderRadius: BorderRadius.circular(12),
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required BorderRadius borderRadius,
    required Color baseColor,
    required Color highlightColor,
  }) {
    final gradientPosition = _controller.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment(-1.0 + (gradientPosition * 3.0), -0.3),
          end: Alignment(1.0 + (gradientPosition * 3.0), 0.3),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
