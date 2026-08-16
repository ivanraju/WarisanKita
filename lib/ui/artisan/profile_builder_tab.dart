import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class ProfileBuilderTab extends StatefulWidget {
  const ProfileBuilderTab({super.key});

  @override
  State<ProfileBuilderTab> createState() => _ProfileBuilderTabState();
}

class _ProfileBuilderTabState extends State<ProfileBuilderTab> {
  late final TextEditingController _studioNameController;
  late final TextEditingController _craftCategoryController;
  late final TextEditingController _stateController;
  late final TextEditingController _experienceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _operatingHoursController;
  late final TextEditingController _bioController;

  bool _isOpenForDemos = true;

  final List<String> _toolsAndMaterials = [
    'Kampung Morten River Clay',
    'Paddy Husk Kiln Ash',
    'Organic Indigo Dyes',
    'Hand-spun Wooden Wheel',
  ];

  final List<String> _portfolioImages = [
    'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    _studioNameController = TextEditingController(
      text: user?.studioName ?? user?.effectiveUsername ?? 'Pak Mat Pottery Studio',
    );
    _craftCategoryController = TextEditingController(
      text: user?.craftCategory ?? 'Pottery & Ceramics',
    );
    _stateController = TextEditingController(text: user?.state ?? 'Melaka');
    _experienceController = TextEditingController(text: '25+ Years Experience');
    _phoneController = TextEditingController(text: '+60 12-345 6789');
    _operatingHoursController = TextEditingController(text: 'Mon - Sat: 9:00 AM - 6:00 PM');
    _bioController = TextEditingController(
      text: user?.bio ?? 'Master Pak Mat has been hand-crafting traditional clay labu sayong and ceramic vessels for over 25 years in Kampung Morten. Each piece is hand-spun and natural clay kilned.',
    );
  }

  @override
  void dispose() {
    _studioNameController.dispose();
    _craftCategoryController.dispose();
    _stateController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _operatingHoursController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final studio = _studioNameController.text.trim();
    final craft = _craftCategoryController.text.trim();
    final bio = _bioController.text.trim();
    final state = _stateController.text.trim();

    final authVM = context.read<AuthViewModel>();
    await authVM.updateProfile(
      studioName: studio,
      craftCategory: craft,
      bio: bio,
      state: state,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile Saved! Live Tourist View updated successfully!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _previewTouristView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtisanDetailScreen(
          artisanName: _studioNameController.text.trim().isEmpty ? 'Pak Mat Pottery Studio' : _studioNameController.text.trim(),
          craftCategory: _craftCategoryController.text.trim().isEmpty ? 'Pottery & Ceramics' : _craftCategoryController.text.trim(),
          state: _stateController.text.trim().isEmpty ? 'Melaka' : _stateController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? 'Master Pak Mat has been hand-crafting traditional clay labu sayong...' : _bioController.text.trim(),
          experience: _experienceController.text.trim().isEmpty ? '25+ Years Experience' : _experienceController.text.trim(),
          imageUrl: _portfolioImages.firstWhere((img) => img != null, orElse: () => 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80')!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Artisan Profile Builder',
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40), fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _previewTouristView,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF004D40)),
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: Text(
                'Preview Tourist View',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🛡️ VERIFIED MASTER LICENSE BADGE BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Master Artisan Profile (Approved)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                        Text(
                          'Your studio license is active & verified by Kraftangan Malaysia Officers. Profile edits sync live to tourists.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (context.watch<AuthViewModel>().currentUser?.isDualRole == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF38BDF8)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.explore_rounded, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dual Role: Cultural Explorer Mode',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFF0369A1),
                            ),
                          ),
                          Text(
                            'Switch to explore craft heritage, visit artisan workshops, and earn passport stamps.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        context.read<AuthViewModel>().selectActiveRole('Cultural Tourist');
                        Navigator.of(context).pushReplacementNamed('/tourist');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Studio Information',
                    softWrap: true,
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _previewTouristView,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: const BorderSide(color: Color(0xFF004D40)),
                  ),
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 14, color: Color(0xFF004D40)),
                  label: Text('Preview Tourist Page', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF004D40), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Cultural Demo Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isOpenForDemos ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isOpenForDemos ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ),
              child: SwitchListTile(
                value: _isOpenForDemos,
                onChanged: (val) => setState(() => _isOpenForDemos = val),
                activeColor: const Color(0xFF10B981),
                title: Text(
                  _isOpenForDemos ? '🟢 STUDIO STATUS: OPEN FOR EDUCATIONAL DEMOS' : '🔴 STUDIO STATUS: IN KILN SESSION / CLOSED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isOpenForDemos ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                  ),
                ),
                subtitle: Text(
                  'Toggling this updates your live availability banner on the Tourist Studio detail page.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[700]),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Studio Name Input
            TextField(
              controller: _studioNameController,
              decoration: InputDecoration(
                labelText: 'Studio / Master Artisan Name',
                prefixIcon: const Icon(Icons.storefront_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                // Craft Category Input
                Expanded(
                  child: TextField(
                    controller: _craftCategoryController,
                    decoration: InputDecoration(
                      labelText: 'Craft Category',
                      prefixIcon: const Icon(Icons.palette_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // State / Region Location Input
                Expanded(
                  child: TextField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State / Location',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                // Phone Number Input
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone / WhatsApp',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Operating Hours Input
                Expanded(
                  child: TextField(
                    controller: _operatingHoursController,
                    decoration: InputDecoration(
                      labelText: 'Operating Hours',
                      prefixIcon: const Icon(Icons.access_time_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Experience Input
            TextField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: 'Years of Experience & Rank Title',
                prefixIcon: const Icon(Icons.workspace_premium_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 14),

            // Bio Input
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Biography & Heritage Craft Story',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 28),

            // 🛠️ TRADITIONAL MATERIALS & TOOLS BUILDER SECTION
            Text(
              'Traditional Materials & Tools Used',
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
            ),
            const SizedBox(height: 6),
            Text(
              'Displayed on your tourist profile page to highlight authentic crafting methods.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._toolsAndMaterials.map((tool) => Chip(
                      avatar: const Icon(Icons.build_circle_rounded, size: 16, color: Color(0xFF004D40)),
                      label: Text(tool, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                      onDeleted: () {
                        setState(() => _toolsAndMaterials.remove(tool));
                      },
                    )),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: Color(0xFFD97706)),
                  label: Text('Add Tool/Material', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                  onPressed: () {
                    final textController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Traditional Tool or Material'),
                        content: TextField(
                          controller: textController,
                          decoration: const InputDecoration(hintText: 'e.g., Paddy Husk Kiln Ash'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () {
                              if (textController.text.trim().isNotEmpty) {
                                setState(() => _toolsAndMaterials.add(textController.text.trim()));
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Unlimited Portfolio Image Manager Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Portfolio Gallery Manager',
                    softWrap: true,
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_portfolioImages.length} Uploaded (Unlimited)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Images uploaded here populate the top gallery slider on the Tourist Profile page.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),

            // Dynamic Unlimited Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _portfolioImages.length + 1,
              itemBuilder: (context, index) {
                if (index < _portfolioImages.length) {
                  final image = _portfolioImages[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          image,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _portfolioImages.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Add Image Tile
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _portfolioImages.add(
                        'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop&q=80',
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📸 Photo ${_portfolioImages.length} added to gallery!'),
                        backgroundColor: const Color(0xFF004D40),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: Color(0xFFD97706), size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'Add Image',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // 📜 VERIFICATION DOCUMENTS & PROOF OF AUTHENTICITY SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Proof of Authenticity & Credentials',
                    softWrap: true,
                    style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF004D40)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '3 / 3 Uploaded',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Upload official certificates to populate master credentials on the Tourist Profile view.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),

            _buildDocumentUploadTile(
              title: 'Business Registration (SSM) Certificate',
              subtitle: 'SSM_Registration_License_2026.pdf (1.2 MB)',
              icon: Icons.article_rounded,
              isUploaded: true,
            ),
            _buildDocumentUploadTile(
              title: 'Kraftangan Malaysia Master Certification',
              subtitle: 'National_Heritage_Craftsman_Cert.pdf (2.4 MB)',
              icon: Icons.workspace_premium_rounded,
              isUploaded: true,
            ),
            _buildDocumentUploadTile(
              title: 'MyKad / Official Identity Document',
              subtitle: 'MyKad_Front_Back_Scan.jpg (950 KB)',
              icon: Icons.badge_rounded,
              isUploaded: true,
            ),

            const SizedBox(height: 36),

            // Save & Preview Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previewTouristView,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.visibility_rounded, color: Color(0xFF004D40)),
                    label: Text(
                      'PREVIEW TOURIST VIEW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF004D40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'SAVE PROFILE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUploaded,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUploaded ? const Color(0xFFCBD5E1) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFF004D40).withValues(alpha: 0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isUploaded ? const Color(0xFF004D40) : Colors.grey[500], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Re-uploaded document for $title.')),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(isUploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded, size: 14, color: isUploaded ? const Color(0xFF10B981) : Colors.grey),
            label: Text(isUploaded ? 'UPLOADED' : 'UPLOAD', style: TextStyle(fontSize: 10, color: isUploaded ? const Color(0xFF10B981) : Colors.grey)),
          ),
        ],
      ),
    );
  }
}