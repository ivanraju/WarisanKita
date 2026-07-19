import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/state/gamification_state.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mock Camera View with Heritage Image
          Positioned.fill(
            child: Opacity(
              opacity: _isProcessing ? 0.3 : 0.6,
              child: Image.network(
                'https://images.unsplash.com/photo-1590739225287-bd31519780c3?w=800',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          _buildScannerOverlay(context),

          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
            ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white12,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Verification Scanner',
                    style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button (Simulating a successful scan)
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00796B)]),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _simulateSuccessfulScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 64),
                ),
                child: const Text('TAP TO SIMULATE SCAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateSuccessfulScan() async {
    setState(() => _isProcessing = true);
    
    // Call the logic layer (State) to update user progress
    await context.read<GamificationState>().verifyQRCode('MOCK_CODE_123');
    
    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Color(0xFFFFD54F)),
            const SizedBox(height: 24),
            Text('Stamp Unlocked!', style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFF004D40))),
            const SizedBox(height: 8),
            const Text('You have earned the "Heritage Guardian" stamp and 150 XP.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to tasks
            },
            child: const Text('AWESOME!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF7043))),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    double scanArea = MediaQuery.of(context).size.width * 0.7;
    return Center(
      child: Container(
        height: scanArea,
        width: scanArea,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }
}
