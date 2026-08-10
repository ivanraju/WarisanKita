import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ssmController = TextEditingController();

  String _selectedRole = 'TOURIST'; // 'TOURIST' or 'ARTISAN'
  String? _errorMessage;

  String? _ssmFileName;
  String? _kraftanganFileName;
  final List<String> _uploadedPhotoNames = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ssmController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final ssm = _ssmController.text.trim();

    // UC002 - A3: Account already exists
    if (email == 'taken@example.com') {
      setState(() => _errorMessage = 'USERNAME ALREADY TAKEN');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('USERNAME ALREADY TAKEN'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // UC002 - Constraint C1: Password length > 7 characters
    if (password.length <= 7) {
      setState(() => _errorMessage = 'PASSWORD MUST BE GREATER THAN 7 CHARACTERS');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PASSWORD MUST BE GREATER THAN 7 CHARACTERS'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // UC002 - Constraint C2: Passwords match
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'PASSWORDS DO NOT MATCH');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PASSWORDS DO NOT MATCH'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _errorMessage = null);

    if (_selectedRole == 'ARTISAN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ARTISAN APPLICATION SUBMITTED: Pending Admin Verification'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ArtisanApplicationPendingScreen(
            studioName: email.contains('@') ? '${email.split('@')[0].toUpperCase()} STUDIO' : 'ARTISAN MASTER STUDIO',
            craftCategory: 'Pottery & Ceramics',
            ssmNumber: ssm.isEmpty ? '202601004821 (SSM Verified)' : ssm,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('REGISTRATION SUCCESSFUL: Authenticated as Cultural Explorer'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/tourist');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isArtisan = _selectedRole == 'ARTISAN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF004D40)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: isDesktop ? 450 : double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004D40).withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isArtisan ? 'Artisan Studio Registration' : 'Tourist Registration',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 26,
                    color: const Color(0xFF004D40),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  isArtisan
                      ? 'REGISTER YOUR MASTER STUDIO FOR CULTURAL TOURISTS'
                      : 'PLEASE ENTER REGISTRATION DETAILS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isArtisan ? const Color(0xFFD97706) : const Color(0xFF004D40),
                  ),
                ),

                const SizedBox(height: 20),

                // Role Toggle Selector Bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'TOURIST'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isArtisan ? const Color(0xFF004D40) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '🧳 Tourist',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !isArtisan ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'ARTISAN'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isArtisan ? const Color(0xFFD97706) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '🎨 Master Artisan',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isArtisan ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Username / Email Input
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: isArtisan ? 'Artisan Email / Studio Account' : 'Username / Email Address',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(height: 16),

                if (isArtisan) ...[
                  // SSM License / Kraftangan Number Input
                  TextField(
                    controller: _ssmController,
                    decoration: InputDecoration(
                      labelText: 'SSM License / Kraftangan Reg. No.',
                      prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 📄 SSM License Document Upload Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proof of Business License (SSM)',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _ssmFileName ?? 'Attach PDF or JPG proof',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _ssmFileName = 'SSM_Registration_Cert.pdf');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📄 SSM Business License attached successfully!'),
                                backgroundColor: Color(0xFF004D40),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(_ssmFileName == null ? 'Upload' : 'Attached ✓', style: const TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🏆 Kraftangan Master Certificate Upload Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kraftangan Master Certification',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _kraftanganFileName ?? 'Attach Official Master Certificate',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _kraftanganFileName = 'Kraftangan_Master_Cert.pdf');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🏆 Kraftangan Master Certificate attached successfully!'),
                                backgroundColor: Color(0xFF004D40),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(_kraftanganFileName == null ? 'Upload' : 'Attached ✓', style: const TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 📸 Studio & Masterwork Photos Upload Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_a_photo_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Studio & Masterwork Photos',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_uploadedPhotoNames.length} Photos Attached (Unlimited Uploads)',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _uploadedPhotoNames.add('Studio_Photo_${_uploadedPhotoNames.length + 1}.jpg'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📸 Studio Photo ${_uploadedPhotoNames.length} attached!'),
                                backgroundColor: const Color(0xFF004D40),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('+ Add Photo', style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // Password Input (C1 > 7 chars)
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password (> 7 characters)',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm Password Input (C2 match check)
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(height: 24),

                // Register Button
                FilledButton(
                  onPressed: _handleRegister,
                  style: FilledButton.styleFrom(
                    backgroundColor: isArtisan ? const Color(0xFFD97706) : const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isArtisan ? 'SUBMIT ARTISAN APPLICATION' : 'SUBMIT REGISTRATION',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Artisan Link Prompt
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRole = isArtisan ? 'TOURIST' : 'ARTISAN';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isArtisan ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isArtisan
                            ? '🧳 Register as a Cultural Tourist instead?'
                            : '🎨 Are you a Master Artisan? Register your studio here',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isArtisan ? const Color(0xFF047857) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Already Registered Link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already registered? ',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF004D40),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
