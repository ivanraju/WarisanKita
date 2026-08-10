import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';

class ArtisanReviewDialog extends StatefulWidget {
  final PendingArtisanProfile artisan;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ArtisanReviewDialog({
    super.key,
    required this.artisan,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<ArtisanReviewDialog> createState() => _ArtisanReviewDialogState();
}

class _ArtisanReviewDialogState extends State<ArtisanReviewDialog> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Container(
        width: 850,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.rate_review_rounded, color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Review Artisan Profile Application',
                                softWrap: true,
                                style: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Submitted on ${widget.artisan.dateSubmitted}',
                                softWrap: true,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Side-by-Side Split View
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Grid of the artisan's submitted portfolio images
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submitted Portfolio Images (3)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          _buildPortfolioThumbnail(widget.artisan.imageUrl),
                          _buildPortfolioThumbnail('https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600'),
                          _buildPortfolioThumbnail('https://images.unsplash.com/photo-1544717305-2782549b5136?w=600'),
                          _buildPortfolioThumbnail('https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 28),

                // Right side: Submitted text (Bio, Craft Type, Location) & Rejection Feedback
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              widget.artisan.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.artisan.name,
                                  style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF0F172A)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.artisan.craftCategory,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildDetailRow(Icons.location_on_outlined, 'State & Location', widget.artisan.state),
                      _buildDetailRow(Icons.email_outlined, 'Email Address', widget.artisan.email),
                      _buildDetailRow(Icons.phone_outlined, 'Contact Phone', widget.artisan.phone),
                      _buildDetailRow(Icons.workspace_premium_outlined, 'Craft Experience', widget.artisan.experience),

                      const SizedBox(height: 12),

                      Text(
                        'Artisan Biography',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Master artisan specializing in authentic hand-crafted traditional heritage items passed down through generations.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                      ),

                      const SizedBox(height: 14),

                      // 📜 SUBMITTED VERIFICATION DOCUMENTS FOR ADMIN VERIFICATION
                      Text(
                        'Submitted Proof Documents (Verified)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      _buildAdminDocChip(Icons.article_rounded, 'SSM_Registration_License_2026.pdf (1.2 MB)'),
                      _buildAdminDocChip(Icons.workspace_premium_rounded, 'Kraftangan_Malaysia_Master_Cert.pdf (2.4 MB)'),
                      _buildAdminDocChip(Icons.badge_rounded, 'MyKad_Identity_Scan.jpg (950 KB)'),

                      const SizedBox(height: 18),

                      // Text Field for 'Rejection Feedback'
                      TextField(
                        controller: _feedbackController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Rejection Feedback (Required if rejecting)',
                          hintText: 'Specify reason for rejection or missing documents...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[400]),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            // Two Large Buttons: 'Approve' and 'Reject'
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onReject();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onApprove();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve Artisan Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDocChip(IconData icon, String filename) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0284C7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filename,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
          ),
          const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF0284C7)),
        ],
      ),
    );
  }

  Widget _buildPortfolioThumbnail(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE2E8F0)),
      ),
    );
  }
}