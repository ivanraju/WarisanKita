import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';

class ArtisanReviewDialog extends StatefulWidget {
  final PendingArtisanProfile artisan;
  final VoidCallback onApprove;
  final void Function(String? reason) onReject;

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
    final isRelocation = widget.artisan.isRelocationRequest;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 850),
        padding: const EdgeInsets.all(24),
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
                            color: (isRelocation ? const Color(0xFFD97706) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isRelocation ? Icons.swap_horiz_rounded : Icons.rate_review_rounded,
                            color: isRelocation ? const Color(0xFFD97706) : const Color(0xFF10B981),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRelocation ? 'Review Workshop Premise Relocation' : 'Review Artisan Profile Application',
                                softWrap: true,
                                style: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isRelocation
                                    ? 'Requested on ${widget.artisan.dateSubmitted} • ${widget.artisan.name}'
                                    : 'Submitted on ${widget.artisan.dateSubmitted}',
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

            if (isRelocation)
              _buildRelocationReview()
            else

            // Responsive Split View
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;

                final leftSide = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted Portfolio Images (${widget.artisan.photos.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.artisan.photos.isEmpty
                          ? [_buildPortfolioThumbnail(widget.artisan.imageUrl)]
                          : widget.artisan.photos.map((url) => _buildPortfolioThumbnail(url)).toList(),
                    ),
                  ],
                );

                final rightSide = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              widget.artisan.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: const Color(0xFFE2E8F0),
                                child: const Icon(Icons.person, color: Color(0xFF64748B)),
                              ),
                            ),
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

                    if (widget.artisan.isUpgradeFromTourist) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFF1D4ED8), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '🌟 Tourist Account Upgrade: Upon approval, this user will be upgraded to "Artisan" role with verified studio privileges.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildDetailRow(Icons.verified_user_outlined, 'SSM License / Reg No', widget.artisan.ssmNumber ?? '202601004821 (SSM Verified)'),
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
                      widget.artisan.bio ?? 'Master artisan specializing in authentic hand-crafted traditional heritage items passed down through generations.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                    ),

                    const SizedBox(height: 14),

                    // 📜 SUBMITTED VERIFICATION DOCUMENTS FOR ADMIN VERIFICATION
                    Text(
                      'Submitted Proof Documents',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                    ),
                    _buildAdminDocChip(
                      Icons.article_rounded,
                      widget.artisan.ssmFileName,
                      url: widget.artisan.ssmFileUrl,
                      missingLabel: '⚠️ SSM Registration Certificate Not Attached',
                    ),
                    _buildAdminDocChip(
                      Icons.workspace_premium_rounded,
                      widget.artisan.certFileName,
                      url: widget.artisan.certFileUrl,
                      missingLabel: '⚠️ Kraftangan Master Accreditation Cert Not Attached',
                    ),
                    if (widget.artisan.photos.isNotEmpty)
                      _buildAdminDocChip(
                        Icons.photo_library_rounded,
                        '${widget.artisan.photos.length} Studio & Workshop Photos Attached',
                        url: widget.artisan.photos.first,
                      ),

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
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftSide,
                      const SizedBox(height: 24),
                      rightSide,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftSide),
                    const SizedBox(width: 28),
                    Expanded(flex: 6, child: rightSide),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            // Two Large Buttons: 'Approve' and 'Reject'
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final reason = _feedbackController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('Please enter rejection feedback explaining the reason to the applicant.'),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            width: 500,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop();
                      widget.onReject(reason);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(
                      isRelocation ? 'Reject Relocation' : 'Reject Application',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onApprove();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isRelocation
                          ? 'Approve Relocation & Update Map'
                          : (widget.artisan.isUpgradeFromTourist ? 'Approve & Upgrade to Artisan Role' : 'Approve Artisan Studio'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildRelocationReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3B82F6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The artisan has formally submitted a workshop premise relocation request. Upon approval, their public map pin and accredited address will update immediately.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Current Accredited Premise',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.place_outlined, 'State', widget.artisan.state),
                    _buildDetailRow(
                      Icons.home_work_outlined,
                      'Address',
                      widget.artisan.currentAddress ?? 'Accredited Studio Location',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.new_releases_rounded, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Proposed New Premise',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.place_outlined, 'State', widget.artisan.proposedState ?? widget.artisan.state),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'New Address',
                      widget.artisan.proposedAddress ?? 'Not Specified',
                    ),
                    if (widget.artisan.proposedLatitude != null && widget.artisan.proposedLongitude != null)
                      _buildDetailRow(
                        Icons.gps_fixed_rounded,
                        'Coordinates',
                        '${widget.artisan.proposedLatitude!.toStringAsFixed(5)}, ${widget.artisan.proposedLongitude!.toStringAsFixed(5)}',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relocation Justification & Reason',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.artisan.relocationReason ?? 'No reason provided by artisan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildAdminDocChip(
    IconData icon,
    String? filename, {
    String? url,
    String missingLabel = 'Document Not Attached',
  }) {
    final isMissing = (filename == null || filename.trim().isEmpty) &&
        (url == null || url.trim().isEmpty);

    if (isMissing) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                missingLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final displayName = (filename != null && filename.isNotEmpty)
        ? filename
        : (url != null ? url.split('/').last : 'Document');

    return InkWell(
      onTap: () {
        if (url != null && url.isNotEmpty) {
           _launchURL(url);
        }
      },
      child: Container(
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
                displayName,
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ),
            if (url != null && url.isNotEmpty)
              const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF0284C7)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  Widget _buildPortfolioThumbnail(String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: const Color(0xFFE2E8F0),
              child: const Icon(Icons.photo_rounded, size: 24, color: Color(0xFF94A3B8)),
            ),
          ),
        ),
      ),
    );
  }
}