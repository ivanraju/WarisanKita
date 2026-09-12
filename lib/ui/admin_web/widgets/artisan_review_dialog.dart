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

  String _formatSubmissionDate(String raw) {
    if (raw.trim().isEmpty) return 'Recent';
    try {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        final local = parsed.toLocal();
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
        final ampm = local.hour >= 12 ? 'PM' : 'AM';
        final min = local.minute.toString().padLeft(2, '0');
        return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$min $ampm';
      }
    } catch (_) {}
    if (raw.length > 10 && raw.contains('T')) {
      return raw.split('T').first;
    }
    return raw;
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
                                    ? 'Requested on ${_formatSubmissionDate(widget.artisan.dateSubmitted)} • ${widget.artisan.name}'
                                    : 'Submitted on ${_formatSubmissionDate(widget.artisan.dateSubmitted)}',
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
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: widget.artisan.isVillageWorkshop
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.artisan.isVillageWorkshop
                                              ? Icons.cottage_outlined
                                              : Icons.store_outlined,
                                          size: 12,
                                          color: widget.artisan.isVillageWorkshop
                                              ? const Color(0xFF047857)
                                              : const Color(0xFF475569),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.artisan.isVillageWorkshop
                                              ? 'Village Workshop'
                                              : 'Commercial Studio',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: widget.artisan.isVillageWorkshop
                                                ? const Color(0xFF047857)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

                    _buildDetailRow(
                      widget.artisan.isVillageWorkshop ? Icons.cottage_outlined : Icons.store_outlined,
                      'Premise Type',
                      widget.artisan.premiseType ?? (widget.artisan.isVillageWorkshop ? 'Home / Village Workshop' : 'Commercial Studio'),
                    ),
                    _buildDetailRow(
                      Icons.verified_user_outlined,
                      widget.artisan.isVillageWorkshop ? 'SSM / Reg No (Optional)' : 'SSM License / Reg No',
                      widget.artisan.ssmNumber?.isNotEmpty == true
                          ? widget.artisan.ssmNumber!
                          : (widget.artisan.isVillageWorkshop
                              ? 'Exempted (Village Crafter)'
                              : 'Pending SSM Verification'),
                    ),
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
                      widget.artisan.isVillageWorkshop ? Icons.verified_user_rounded : Icons.article_rounded,
                      widget.artisan.ssmFileName,
                      url: widget.artisan.ssmFileUrl,
                      missingLabel: widget.artisan.isVillageWorkshop
                          ? '⚠️ Village Head / Tok Batin Endorsement Not Attached'
                          : '⚠️ SSM Registration Certificate Not Attached',
                    ),
                    _buildAdminDocChip(
                      Icons.workspace_premium_rounded,
                      widget.artisan.certFileName,
                      url: widget.artisan.certFileUrl,
                      missingLabel: '⚠️ Kraftangan Master Accreditation Cert Not Attached',
                    ),
                    _buildAdminDocChip(
                      Icons.photo_library_rounded,
                      widget.artisan.photos.isNotEmpty
                          ? '${widget.artisan.photos.length} Studio & Workshop Photos Attached'
                          : null,
                      url: widget.artisan.photos.isNotEmpty
                          ? widget.artisan.photos.first
                          : null,
                      missingLabel: '⚠️ No Studio Photos Attached',
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
        const SizedBox(height: 16),
        // Artisan Profile & Contact Strip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.artisan.imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.person, color: Color(0xFF64748B)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.artisan.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.artisan.craftCategory,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined, size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              widget.artisan.email,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        if (widget.artisan.phone.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                widget.artisan.phone,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        if (widget.artisan.experience.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_outlined, size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                widget.artisan.experience,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildPremiseCard(
                  cardTitle: 'Current Accredited Premise',
                  badgeText: 'Active Premise',
                  badgeBgColor: const Color(0xFFECFDF5),
                  badgeTextColor: const Color(0xFF047857),
                  cardBorderColor: const Color(0xFFCBD5E1),
                  cardBgColor: const Color(0xFFF8FAFC),
                  statusIcon: Icons.verified_rounded,
                  statusColor: const Color(0xFF10B981),
                  state: widget.artisan.state,
                  address: widget.artisan.currentAddress ?? 'Accredited Studio Location',
                  isProposed: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildPremiseCard(
                  cardTitle: 'Proposed New Premise',
                  badgeText: 'Pending Approval',
                  badgeBgColor: const Color(0xFFFEF3C7),
                  badgeTextColor: const Color(0xFFB45309),
                  cardBorderColor: const Color(0xFFF59E0B),
                  cardBgColor: const Color(0xFFFFFBEB),
                  statusIcon: Icons.new_releases_rounded,
                  statusColor: const Color(0xFFD97706),
                  state: widget.artisan.proposedState ?? widget.artisan.state,
                  address: widget.artisan.proposedAddress ?? 'Not Specified',
                  latitude: widget.artisan.proposedLatitude,
                  longitude: widget.artisan.proposedLongitude,
                  isProposed: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                          const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            'Relocation Justification',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.artisan.relocationReason?.trim().isNotEmpty == true
                            ? widget.artisan.relocationReason!
                            : 'No relocation justification provided by artisan.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                          const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            'Updated Premise Certificate',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAdminDocChip(
                        Icons.article_rounded,
                        widget.artisan.relocationCertFileName ??
                            widget.artisan.certFileName ??
                            widget.artisan.ssmFileName,
                        url: widget.artisan.relocationCertFileUrl ??
                            widget.artisan.certFileUrl ??
                            widget.artisan.ssmFileUrl,
                        missingLabel: '⚠️ No Updated Premise Certificate Attached',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _feedbackController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Rejection Feedback (Required if rejecting relocation)',
            hintText: 'Specify reason for relocation rejection or required document updates...',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[400]),
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiseCard({
    required String cardTitle,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required Color cardBorderColor,
    required Color cardBgColor,
    required IconData statusIcon,
    required Color statusColor,
    required String state,
    required String address,
    double? latitude,
    double? longitude,
    required bool isProposed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cardTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'STATE / REGION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isProposed ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 12,
                      color: isProposed ? const Color(0xFFB45309) : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isProposed ? const Color(0xFF92400E) : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PREMISE ADDRESS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isProposed ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isProposed ? Icons.location_on_outlined : Icons.home_work_outlined,
                  size: 18,
                  color: isProposed ? const Color(0xFFD97706) : const Color(0xFF10B981),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    address.trim().isNotEmpty ? address : 'Accredited Studio Location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (latitude != null && longitude != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'GPS: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          TextSpan(
                            text: '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Linked to accredited map pin',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
          ),
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