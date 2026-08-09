import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/ui/admin_web/widgets/artisan_review_dialog.dart';

class PendingArtisansTable extends StatelessWidget {
  final List<PendingArtisanProfile> artisans;
  final Function(PendingArtisanProfile) onApprove;
  final Function(PendingArtisanProfile) onReject;

  const PendingArtisansTable({
    super.key,
    required this.artisans,
    required this.onApprove,
    required this.onReject,
  });

  void _openReviewDialog(BuildContext context, PendingArtisanProfile artisan) {
    showDialog(
      context: context,
      builder: (_) => ArtisanReviewDialog(
        artisan: artisan,
        onApprove: () => onApprove(artisan),
        onReject: () => onReject(artisan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (artisans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'All Pending Profiles Reviewed!',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'There are no artisan applications requiring moderation at this time.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowHeight: 52,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          horizontalMargin: 24,
          columnSpacing: 24,
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columns: [
            DataColumn(
              label: Text(
                'ARTISAN NAME',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'CRAFT CATEGORY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'DATE SUBMITTED',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ACTIONS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
          rows: artisans.map((artisan) => _buildRow(context, artisan)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, PendingArtisanProfile artisan) {
    return DataRow(
      cells: [
        // Artisan Name Cell
        DataCell(
          InkWell(
            onTap: () => _openReviewDialog(context, artisan),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    artisan.imageUrl,
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artisan.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          artisan.state,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${artisan.experience}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Craft Category Cell
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              artisan.craftCategory,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D4ED8),
              ),
            ),
          ),
        ),

        // Date Submitted Cell
        DataCell(
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                artisan.dateSubmitted,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),

        // Actions Column Cell (Review Modal Button, Green Approve Button & Red Reject Button)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Inspect / Review Details Modal Button
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF2563EB), size: 18),
                onPressed: () => _openReviewDialog(context, artisan),
                tooltip: 'Review Full Profile & Portfolio Modal',
              ),
              const SizedBox(width: 4),

              // Green Approve Button
              ElevatedButton.icon(
                onPressed: () => onApprove(artisan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 15),
                label: Text(
                  'Approve',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Red Reject Outline Button
              OutlinedButton.icon(
                onPressed: () => onReject(artisan),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 15),
                label: Text(
                  'Reject',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
