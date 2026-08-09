import 'package:flutter/material.dart';

class ShimmerDirectoryLoading extends StatefulWidget {
  const ShimmerDirectoryLoading({super.key});

  @override
  State<ShimmerDirectoryLoading> createState() => _ShimmerDirectoryLoadingState();
}

class _ShimmerDirectoryLoadingState extends State<ShimmerDirectoryLoading>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(16),
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildShimmerBox(
                    width: 70,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                  const SizedBox(height: 6),
                  _buildShimmerBox(
                    width: 120,
                    height: 16,
                    borderRadius: BorderRadius.circular(6),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ],
              ),
            );
          },
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
    final pos = _controller.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment(-1.0 + (pos * 3.0), -0.3),
          end: Alignment(1.0 + (pos * 3.0), 0.3),
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
