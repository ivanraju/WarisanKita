import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileBuilderTab extends StatefulWidget {
  const ProfileBuilderTab({super.key});

  @override
  State<ProfileBuilderTab> createState() => _ProfileBuilderTabState();
}

class _ProfileBuilderTabState extends State<ProfileBuilderTab> {
  final _studioNameController = TextEditingController(text: 'Pak Mat Ceramic Studio');
  final _craftCategoryController = TextEditingController(text: 'Pottery & Ceramics');
  final _bioController = TextEditingController(
    text: 'Hand-crafted clay labu sayong and traditional ceramic vessels.',
  );

  final List<String?> _portfolioImages = [
    'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
    null,
    null,
    null,
    null,
    null,
    null,
  ];

  @override
  void dispose() {
    _studioNameController.dispose();
    _craftCategoryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile Submitted! Default Tasks ("Arrive at Workshop" & "Stay 15 Mins") auto-created!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFD97706), fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📝 OFFICIAL ARTISAN APPLICATION BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Artisan Application Form',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        Text(
                          'Complete your studio credentials & portfolio images to apply for official marketplace verification.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Studio Information',
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 16),

            // Studio Name Input
            TextField(
              controller: _studioNameController,
              decoration: InputDecoration(
                labelText: 'Studio / Artisan Name',
                prefixIcon: const Icon(Icons.storefront_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 14),

            // Craft Category Input
            TextField(
              controller: _craftCategoryController,
              decoration: InputDecoration(
                labelText: 'Craft Category',
                prefixIcon: const Icon(Icons.palette_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 14),

            // Bio Input
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Biography & Craft Story',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 32),

            // 3x3 Portfolio Image Manager Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portfolio Image Manager',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF1F2937)),
                ),
                Text(
                  '3 / 9 Uploaded',
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
              'Upload up to 9 high-resolution images of your handcrafted items.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),

            // 3x3 Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final image = _portfolioImages[index];

                if (image != null) {
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
                          onTap: () => setState(() => _portfolioImages[index] = null),
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

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _portfolioImages[index] =
                          'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop&q=80';
                    });
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
                Text(
                  'Proof of Authenticity & Documents',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF1F2937)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '3 / 3 Required Uploaded',
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
              'Upload official certificates to verify master craftsman authenticity with admin moderators.',
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

            // Save & Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _handleSave,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'SAVE & SUBMIT FOR APPROVAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
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
        border: Border.all(color: isUploaded ? const Color(0xFFCBD5E1) : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFF004D40).withOpacity(0.1) : Colors.grey[100],
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
