import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';

// ── Shimmer base ───────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFEBEBF4),
            Color(0xFFF4F4F4),
            Color(0xFFEBEBF4),
          ],
          stops: const [0.1, 0.5, 0.9],
          transform: _SlidingGradientTransform(_anim.value),
        ).createShader(bounds),
        child: widget.child,
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// ── Skeleton box helper ────────────────────────────────────────────────────

class _Box extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Box({required this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBF4),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Single job card skeleton ───────────────────────────────────────────────

class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ColorConstants.pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.shadowBlack.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Box(width: 36, height: 36, radius: 10),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _Box(width: 120, height: 14),
                            SizedBox(height: 6),
                            _Box(width: 80, height: 11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _Box(width: 72, height: 26, radius: 20),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFEBEBF4)),
                  ),

                  // Info rows
                  Row(
                    children: const [
                      _Box(width: 16, height: 16, radius: 4),
                      SizedBox(width: 8),
                      _Box(width: 200, height: 12),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      _Box(width: 16, height: 16, radius: 4),
                      SizedBox(width: 8),
                      _Box(width: 100, height: 12),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action button
                  const _Box(width: double.infinity, height: 40, radius: 8),
                ],
              ),
            ),

            // Left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEBF4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List of skeletons — drop-in replacement for loading state ──────────────

class JobListSkeleton extends StatelessWidget {
  final int count;
  const JobListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => const JobCardSkeleton(),
    );
  }
}
