import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:voicesewa_worker/features/auth/providers/aadhaar_verification_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET — drop this inside WorkerProfileFormPage
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in widget for the profile form.
/// Handles: scan → decode → prefill callback → verified badge.
///
/// Usage:
///   AadhaarVerificationSection(
///     onVerified: (data) {
///       nameController.text = data.name ?? '';
///       dobController.text  = data.dob  ?? '';
///       // etc.
///     },
///   )
class AadhaarVerificationSection extends ConsumerWidget {
  /// Called when Aadhaar is successfully decoded.
  /// Use this to prefill your form controllers.
  final void Function(AadhaarData data) onVerified;

  const AadhaarVerificationSection({super.key, required this.onVerified});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aadhaarVerificationProvider);

    // Fire prefill callback once on verification
    ref.listen<AadhaarVerificationState>(aadhaarVerificationProvider, (
      _,
      next,
    ) {
      if (next.isVerified && next.data != null) {
        onVerified(next.data!);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section header ──────────────────────────────────────────────────
        _SectionHeader(isVerified: state.isVerified),

        const SizedBox(height: 12),

        // ── State-driven body ───────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          child: switch (state.status) {
            AadhaarVerificationStatus.idle ||
            AadhaarVerificationStatus.scanning => _ScanCard(
              key: const ValueKey('scan'),
            ),
            AadhaarVerificationStatus.loading => _LoadingCard(
              key: const ValueKey('loading'),
            ),
            AadhaarVerificationStatus.verified => _VerifiedCard(
              key: const ValueKey('verified'),
              data: state.data!,
            ),
            AadhaarVerificationStatus.failed => _FailedCard(
              key: const ValueKey('failed'),
              message: state.errorMessage ?? 'Scan failed. Try again.',
            ),
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final bool isVerified;
  const _SectionHeader({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Aadhaar Verification',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        if (isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1DB954), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 13,
                  color: Color(0xFF1DB954),
                ),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1DB954),
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        // Optional badge
        if (!isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Optional',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCAN CARD — idle state, tap to open scanner
// ─────────────────────────────────────────────────────────────────────────────

class _ScanCard extends ConsumerWidget {
  const _ScanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openScanner(context, ref),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1.5,
            // Dashed-style via gradient not supported natively;
            // using solid subtle border instead
          ),
        ),
        child: Column(
          children: [
            // Boost message ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.12),
                    const Color(0xFF00C9A7).withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verified workers get 3× more job suggestions!',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QR icon ────────────────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 38,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Scan Aadhaar QR Code',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Point camera at the QR on your\nAadhaar card or mAadhaar app',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.55),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: () => _openScanner(context, ref),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Open Scanner'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Where to find QR hint
            TextButton(
              onPressed: () => _showHowToDialog(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.45),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Where is the QR code on my Aadhaar?'),
            ),
          ],
        ),
      ),
    );
  }

  void _openScanner(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AadhaarQrScannerPage(
          onScanned: (rawQr) {
            Navigator.of(context).pop();
            ref.read(aadhaarVerificationProvider.notifier).decodeQr(rawQr);
          },
        ),
      ),
    );
  }

  void _showHowToDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finding your Aadhaar QR'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HowToItem(
              icon: '🪪',
              title: 'Physical card',
              desc: 'The QR code is on the back of your Aadhaar card.',
            ),
            SizedBox(height: 12),
            _HowToItem(
              icon: '📱',
              title: 'mAadhaar app',
              desc: 'Open mAadhaar → tap your profile → tap "Show QR Code".',
            ),
            SizedBox(height: 12),
            _HowToItem(
              icon: '🖨️',
              title: 'e-Aadhaar PDF',
              desc:
                  'Download from uidai.gov.in and scan the QR on the last page.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _HowToItem extends StatelessWidget {
  final String icon, title, desc;
  const _HowToItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QR SCANNER PAGE — full-screen camera
// ─────────────────────────────────────────────────────────────────────────────

class _AadhaarQrScannerPage extends StatefulWidget {
  final void Function(String rawQr) onScanned;
  const _AadhaarQrScannerPage({required this.onScanned});

  @override
  State<_AadhaarQrScannerPage> createState() => _AadhaarQrScannerPageState();
}

class _AadhaarQrScannerPageState extends State<_AadhaarQrScannerPage> {
  late final MobileScannerController _controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    // Start camera after first frame to avoid black screen on Android
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.start();
    });
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _scanned = true;
    widget.onScanned(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan Aadhaar QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay with scan window cutout
          _ScannerOverlay(),

          // Hint text at bottom
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'Align the QR code within the box',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const boxSize = 260.0;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2 - 40;

    return Stack(
      children: [
        // Dark overlay
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Corner brackets
        Positioned(
          left: left,
          top: top,
          child: _CornerBrackets(size: boxSize),
        ),
      ],
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  final double size;
  const _CornerBrackets({required this.size});

  @override
  Widget build(BuildContext context) {
    const thickness = 4.0;
    const length = 30.0;
    const color = Colors.white;
    const radius = 4.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BracketPainter(
          thickness: thickness,
          length: length,
          color: color,
          radius: radius,
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final double thickness, length, radius;
  final Color color;
  const _BracketPainter({
    required this.thickness,
    required this.length,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final corners = [
      // Top-left
      [Offset(0, length), const Offset(0, 0), Offset(length, 0)],
      // Top-right
      [
        Offset(size.width - length, 0),
        Offset(size.width, 0),
        Offset(size.width, length),
      ],
      // Bottom-left
      [
        Offset(0, size.height - length),
        Offset(0, size.height),
        Offset(length, size.height),
      ],
      // Bottom-right
      [
        Offset(size.width - length, size.height),
        Offset(size.width, size.height),
        Offset(size.width, size.height - length),
      ],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Reading your Aadhaar...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This usually takes 2–3 seconds',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFIED CARD
// ─────────────────────────────────────────────────────────────────────────────

class _VerifiedCard extends ConsumerWidget {
  final AadhaarData data;
  const _VerifiedCard({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1DB954).withOpacity(0.08),
            const Color(0xFF00C9A7).withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF1DB954),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Aadhaar Verified',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Rescan button
              TextButton(
                onPressed: () =>
                    ref.read(aadhaarVerificationProvider.notifier).reset(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  textStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Re-scan'),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Decoded data rows
          if (data.name != null) _InfoRow(label: 'Name', value: data.name!),
          if (data.gender != null)
            _InfoRow(label: 'Gender', value: data.gender!),
          if (data.dob != null)
            _InfoRow(label: 'Date of Birth', value: data.dob!),
          if (data.district != null || data.state != null)
            _InfoRow(
              label: 'Location',
              value: [
                data.district,
                data.state,
              ].where((e) => e != null).join(', '),
            ),
          if (data.uidLast4 != null)
            _InfoRow(label: 'Aadhaar', value: 'XXXX XXXX ${data.uidLast4}'),

          const SizedBox(height: 14),

          // 🚀 Boost message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Great! Verified workers get priority matching — you\'ll see 3× more relevant jobs.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAILED CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FailedCard extends ConsumerWidget {
  final String message;
  const _FailedCard({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () =>
                ref.read(aadhaarVerificationProvider.notifier).reset(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
