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

// ── Job detail page skeleton ───────────────────────────────────────────────

class JobDetailSkeleton extends StatelessWidget {
  const JobDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _skeletonCard(
              child: Row(
                children: [
                  const _Box(width: 4, height: 44, radius: 2),
                  const SizedBox(width: 14),
                  const _Box(width: 36, height: 36, radius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _Box(width: 100, height: 11),
                        SizedBox(height: 6),
                        _Box(width: 140, height: 15),
                      ],
                    ),
                  ),
                  const _Box(width: 80, height: 28, radius: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Job details card
            _skeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(),
                  const Divider(height: 1, color: Color(0xFFEBEBF4)),
                  const SizedBox(height: 12),
                  _detailRow(labelWidth: 60, valueWidth: 120),
                  const SizedBox(height: 10),
                  _detailRow(labelWidth: 70, valueWidth: 200),
                  const SizedBox(height: 10),
                  _detailRow(labelWidth: 50, valueWidth: 90),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location card
            _skeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(),
                  const Divider(height: 1, color: Color(0xFFEBEBF4)),
                  const SizedBox(height: 12),
                  _detailRow(labelWidth: 180, valueWidth: 0),
                  const SizedBox(height: 12),
                  // Map placeholder
                  const _Box(width: double.infinity, height: 180, radius: 12),
                  const SizedBox(height: 10),
                  const _Box(width: double.infinity, height: 40, radius: 8),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action card
            _skeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(),
                  const Divider(height: 1, color: Color(0xFFEBEBF4)),
                  const SizedBox(height: 12),
                  const _Box(width: double.infinity, height: 44, radius: 8),
                  const SizedBox(height: 10),
                  const _Box(width: double.infinity, height: 44, radius: 8),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonCard({required Widget child}) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: const [
          _Box(width: 18, height: 18, radius: 4),
          SizedBox(width: 8),
          _Box(width: 100, height: 13),
        ],
      ),
    );
  }

  Widget _detailRow({required double labelWidth, required double valueWidth}) {
    return Row(
      children: [
        const _Box(width: 15, height: 15, radius: 4),
        const SizedBox(width: 8),
        _Box(width: 90, height: 12),
        const SizedBox(width: 8),
        if (valueWidth > 0) _Box(width: valueWidth, height: 12),
      ],
    );
  }
}
