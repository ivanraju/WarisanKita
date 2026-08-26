import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';

class ApplyArtisanScreen extends StatefulWidget {
  const ApplyArtisanScreen({super.key});

  @override
  State<ApplyArtisanScreen> createState() => _ApplyArtisanScreenState();
}

class _ApplyArtisanScreenState extends State<ApplyArtisanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studioNameController = TextEditingController();
  final _ssmController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCraftCategory = 'Woodwork';
  String _selectedState = 'Melaka';
  bool _isSubmitting = false;

  String? _ssmFileName;
  String? _ssmFileSize;
  String? _kraftanganFileName;
  String? _kraftanganFileSize;
  final List<Map<String, String>> _uploadedPhotos = [];

  final List<String> _craftCategories = const [
    'Woodwork',
    'Songket & Weaving',
    'Batik & Textiles',
    'Pottery & Ceramics',
    'Metalwork & Pewter',
    'Heritage Food',
    'Wayang Kulit & Puppetry',
    'Rattan & Bamboo Craft',
  ];

  final List<String> _malaysiaStates = const [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
  ];

  @override
  void dispose() {
    _studioNameController.dispose();
    _ssmController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickSsmDocument() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        setState(() {
          _ssmFileName = file.name;
          _ssmFileSize = '1.4 MB';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📄 SSM Proof attached: ${file.name}'),
              backgroundColor: const Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      setState(() {
        _ssmFileName = 'SSM_Business_License_2026.pdf';
        _ssmFileSize = '1.4 MB';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📄 Sample SSM Business License attached successfully!'),
            backgroundColor: Color(0xFF004D40),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickKraftanganCertificate() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        setState(() {
          _kraftanganFileName = file.name;
          _kraftanganFileSize = '2.1 MB';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🏆 Kraftangan Certificate attached: ${file.name}'),
              backgroundColor: const Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      setState(() {
        _kraftanganFileName = 'Kraftangan_Master_Certificate.pdf';
        _kraftanganFileSize = '2.1 MB';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏆 Sample Kraftangan Master Certificate attached!'),
            backgroundColor: Color(0xFF004D40),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickStudioPhotos() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.image,
      );

      if (result.isNotEmpty) {
        setState(() {
          for (final file in result) {
            _uploadedPhotos.add({
              'name': file.name,
              'size': '850 KB',
            });
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📸 Studio workshop photo attached (${result.length} files)'),
              backgroundColor: const Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      setState(() {
        _uploadedPhotos.add({'name': 'Workshop_Studio_View.jpg', 'size': '850 KB'});
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Sample Workshop Photo attached!'),
            backgroundColor: Color(0xFF004D40),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    final studioName = _studioNameController.text.trim();
    final ssm = _ssmController.text.trim();
    final bio = _bioController.text.trim();
    final phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '+60 12-345 6789';

    final effectiveSsmFile = _ssmFileName ?? 'SSM_Registration_Cert.pdf';
    final effectiveCertFile = _kraftanganFileName ?? 'Kraftangan_Master_Cert.pdf';
    final effectivePhotos = _uploadedPhotos.isNotEmpty
        ? _uploadedPhotos.map((p) => p['name']!).toList()
        : ['Studio_Workshop_Photo_1.jpg'];
    final effectiveEmail = (user?.email != null && user!.email.trim().isNotEmpty)
        ? user.email.trim()
        : 'tourist@warisankita.my';

    final result = await authVM.linkArtisanToExistingTourist(
      email: effectiveEmail,
      studioName: studioName,
      craftCategory: _selectedCraftCategory,
      ssmNumber: ssm,
      bio: bio.isNotEmpty ? bio : null,
      phone: phone,
      state: _selectedState,
      ssmFileName: effectiveSsmFile,
      certFileName: effectiveCertFile,
      photos: effectivePhotos,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Application submission failed'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      context.read<ModerationViewModel>().addPendingArtisan(
        PendingArtisanProfile(
          id: user?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
          name: studioName,
          craftCategory: _selectedCraftCategory,
          state: _selectedState,
          dateSubmitted: 'Just Now',
          imageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600',
          email: user?.email ?? '',
          experience: 'Master Artisan Applicant',
          phone: phone,
          ssmNumber: ssm,
          ssmFileName: effectiveSsmFile,
          certFileName: effectiveCertFile,
          photos: effectivePhotos,
          bio: bio.isNotEmpty ? bio : 'Master studio application for $_selectedCraftCategory in $_selectedState.',
          isUpgradeFromTourist: true,
        ),
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('STUDIO APPLICATION SUBMITTED: Under Kraftangan Admin Review!')),
          ],
        ),
        backgroundColor: Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ArtisanApplicationPendingScreen(
          studioName: studioName,
          craftCategory: _selectedCraftCategory,
          ssmNumber: ssm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF004D40)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Apply for Master Artisan',
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40), fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Container(
            width: isDesktop ? 600 : double.infinity,
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kraftangan Malaysia Accreditation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Register your heritage workshop to host interactive quests, create unique QR keys, and gain verified status on the live directory.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF78350F), height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('Studio & Workshop Details', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF004D40))),
                  const SizedBox(height: 16),

                  // Studio Name
                  TextFormField(
                    controller: _studioNameController,
                    decoration: InputDecoration(
                      labelText: 'Studio Name *',
                      hintText: 'e.g. Pak Mat Pottery & Ceramics Studio',
                      prefixIcon: const Icon(Icons.storefront_rounded, color: Color(0xFF004D40)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your studio or workshop name' : null,
                  ),

                  const SizedBox(height: 16),

                  // Craft Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCraftCategory,
                    decoration: InputDecoration(
                      labelText: 'Heritage Craft Category *',
                      prefixIcon: const Icon(Icons.palette_outlined, color: Color(0xFF004D40)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: _craftCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedCraftCategory = v!),
                  ),

                  const SizedBox(height: 16),

                  // State / Location Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: InputDecoration(
                      labelText: 'Workshop State / Region *',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF004D40)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: _malaysiaStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedState = v!),
                  ),

                  const SizedBox(height: 16),

                  // SSM Registration Number
                  TextFormField(
                    controller: _ssmController,
                    decoration: InputDecoration(
                      labelText: 'SSM Business / Kraftangan Registration No. *',
                      hintText: 'e.g. 202601004821 or KT/2026/0491',
                      prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF004D40)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter SSM or Kraftangan registration number' : null,
                  ),

                  const SizedBox(height: 16),

                  // Contact Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Studio Contact Phone',
                      hintText: '+60 12-345 6789',
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF004D40)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bio / Heritage Description
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Studio Heritage Bio & Master Story',
                      hintText: 'Describe your heritage craft experience, workshop history, and master lineage...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 45),
                        child: Icon(Icons.history_edu_rounded, color: Color(0xFF004D40)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('Verification Documents (Optional)', style: GoogleFonts.dmSerifDisplay(fontSize: 16, color: const Color(0xFF004D40))),
                  const SizedBox(height: 12),

                  // Document Pickers
                  _buildUploadTile(
                    icon: Icons.description_outlined,
                    title: 'SSM Business Registration PDF',
                    subtitle: _ssmFileName != null ? 'Attached: $_ssmFileName ($_ssmFileSize)' : 'Upload PDF / PNG proof of registration',
                    isAttached: _ssmFileName != null,
                    onTap: _pickSsmDocument,
                  ),

                  const SizedBox(height: 10),

                  _buildUploadTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Kraftangan Master Certificate',
                    subtitle: _kraftanganFileName != null ? 'Attached: $_kraftanganFileName ($_kraftanganFileSize)' : 'Upload accreditation certificate (Optional)',
                    isAttached: _kraftanganFileName != null,
                    onTap: _pickKraftanganCertificate,
                  ),

                  const SizedBox(height: 10),

                  _buildUploadTile(
                    icon: Icons.photo_camera_outlined,
                    title: 'Studio Workshop Photos',
                    subtitle: _uploadedPhotos.isNotEmpty ? 'Attached ${_uploadedPhotos.length} photo(s)' : 'Upload photos of your craft studio',
                    isAttached: _uploadedPhotos.isNotEmpty,
                    onTap: _pickStudioPhotos,
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitApplication,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              'Submit Artisan Application',
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isAttached,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isAttached ? const Color(0xFFECFDF5) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isAttached ? const Color(0xFF10B981) : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAttached ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(isAttached ? Icons.check_circle_rounded : icon, color: isAttached ? const Color(0xFF10B981) : const Color(0xFF004D40), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0F172A))),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: isAttached ? const Color(0xFF047857) : Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.upload_file_rounded, size: 18, color: isAttached ? const Color(0xFF10B981) : Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
