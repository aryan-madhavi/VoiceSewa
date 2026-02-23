import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'bill_form_page.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  final JobModel job;

  const OtpVerificationPage({super.key, required this.job});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final List<TextEditingController> _ctrls = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());

  bool _verifying = false;
  bool _verified = false;
  bool _error = false;
  bool _starting = false;

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _otp => _ctrls.map((c) => c.text).join();
  bool get _complete => _otp.length == 4;

  Future<void> _verify() async {
    if (!_complete) return;
    setState(() {
      _verifying = true;
      _error = false;
    });

    final ok = await ref.read(verifyOtpProvider)(
      jobId: widget.job.jobId,
      enteredOtp: _otp,
    );

    if (!mounted) return;
    setState(() {
      _verifying = false;
      _verified = ok;
      _error = !ok;
    });

    if (!ok) {
      for (final c in _ctrls) c.clear();
      _nodes.first.requestFocus();
    }
  }

  Future<void> _startJob() async {
    setState(() => _starting = true);
    final ok = await ref.read(startJobProvider)(widget.job.jobId);
    if (!mounted) return;
    setState(() => _starting = false);

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BillFormPage(job: widget.job)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start job. Please try again.'),
          backgroundColor: ColorConstants.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Start Job',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: ColorConstants.pureWhite,
        foregroundColor: ColorConstants.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color:
                    (_verified
                            ? ColorConstants.successGreen
                            : ColorConstants.primaryBlue)
                        .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _verified ? Icons.check_circle_outline : Icons.lock_outline,
                size: 40,
                color: _verified
                    ? ColorConstants.successGreen
                    : ColorConstants.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              _verified ? 'OTP Verified! 🎉' : 'Enter Client OTP',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ColorConstants.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _verified
                  ? 'All set! Tap Start Job to begin.'
                  : 'Ask the client for their 4-digit OTP\nto verify and begin this job.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorConstants.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // ── OTP boxes ────────────────────────────────────────────────────
            if (!_verified) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => _OtpBox(
                    ctrl: _ctrls[i],
                    node: _nodes[i],
                    hasError: _error,
                    onChanged: (val) {
                      if (val.length == 1 && i < 3)
                        _nodes[i + 1].requestFocus();
                      if (val.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                      setState(() => _error = false);
                      if (_complete) _verify();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _error ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Text(
                  'Incorrect OTP — please try again.',
                  style: TextStyle(
                    color: ColorConstants.errorRed,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_complete && !_verifying) ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryBlue,
                    foregroundColor: ColorConstants.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorConstants.pureWhite,
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],

            // ── Verified state ───────────────────────────────────────────────
            if (_verified) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.successGreen.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorConstants.successGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: ColorConstants.successGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identity Verified',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.successGreen,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            widget.job.serviceName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ColorConstants.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_outline, size: 22),
                  label: Text(
                    _starting ? 'Starting...' : 'Start Job',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _starting ? null : _startJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.successTeal,
                    foregroundColor: ColorConstants.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Single OTP box ─────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode node;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.ctrl,
    required this.node,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 68,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      child: TextField(
        controller: ctrl,
        focusNode: node,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        obscureText: true,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ColorConstants.textDark,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: hasError
              ? ColorConstants.errorRed.withOpacity(0.05)
              : ColorConstants.pureWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError
                  ? ColorConstants.errorRed
                  : ColorConstants.dividerGrey,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError
                  ? ColorConstants.errorRed
                  : ColorConstants.dividerGrey,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError
                  ? ColorConstants.errorRed
                  : ColorConstants.primaryBlue,
              width: 2,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
