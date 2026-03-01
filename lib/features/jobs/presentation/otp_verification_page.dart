import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'bill_form_page.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';

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
  bool _error = false;

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

    if (!ok) {
      setState(() {
        _verifying = false;
        _error = true;
      });
      for (final c in _ctrls) c.clear();
      _nodes.first.requestFocus();
      return;
    }

    // OTP correct — start job immediately, navigate to BillFormPage
    final started = await ref.read(startJobProvider)(widget.job.jobId);
    if (!mounted) return;

    if (started) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BillFormPage(job: widget.job)),
      );
    } else {
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.failedToStartJobPleaseTryAgain),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 40,
                color: ColorConstants.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Enter Client OTP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ColorConstants.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask the client for their 4-digit OTP\nto verify and begin this job.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ColorConstants.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => _OtpBox(
                  ctrl: _ctrls[i],
                  node: _nodes[i],
                  hasError: _error,
                  onChanged: (val) {
                    if (val.length == 1 && i < 3) _nodes[i + 1].requestFocus();
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