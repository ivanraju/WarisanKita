import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

class QRScannerScreen extends StatefulWidget {
  final Quest quest;
  final HeritageTask task;

  const QRScannerScreen({super.key, required this.quest, required this.task});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    final payload = capture.barcodes.first.rawValue?.trim();
    if (payload == null || payload.isEmpty) return;

    setState(() => _isProcessing = true);
    await _scannerController.stop();
    if (!mounted) return;

    final viewModel = context.read<GamificationViewModel>();
    final completed = await viewModel.verifyArtisanQrForTask(
      task: widget.task,
      qrPayload: payload,
    );
    if (!mounted) return;

    if (completed) {
      await _showSuccessDialog(
        viewModel.authoritativeXpAwardForTask(widget.task.id),
      );
      if (!mounted) return;

      // The dialog and scanner are two separate overlay routes. Popping both
      // during the same pointer event can leave the dialog's constrained render
      // box between layout passes while Flutter processes the pointer-up event.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.startQuestError ??
              'The workshop QR could not verify this task.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB42318),
      ),
    );
    setState(() => _isProcessing = false);
    await _scannerController.start();
  }

  Future<void> _showSuccessDialog(int? xpAwarded) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 72,
              color: Color(0xFF087F5B),
            ),
            const SizedBox(height: 18),
            Text(
              'Task Verified!',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 25,
                color: const Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              xpAwarded == null
                  ? '${widget.task.title} completed successfully.'
                  : '${widget.task.title} is complete. '
                        'You earned $xpAwarded XP.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(height: 1.45),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF005B4F),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanArea = MediaQuery.sizeOf(context).width * 0.72;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetection,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Camera unavailable: '
                  '${error.errorDetails?.message ?? error.errorCode.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
          Center(
            child: Container(
              width: scanArea,
              height: scanArea,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFD54F), width: 3),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Workshop Verification',
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: 23,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xE6004D40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.task.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scan ${widget.quest.title}’s workshop QR. '
                          'The same artisan QR verifies every task.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
              ),
            ),
        ],
      ),
    );
  }
}
