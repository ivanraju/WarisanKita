import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/domain/models/user.dart';

class UserManagementTable extends StatelessWidget {
  final List<UserModel> users;
  final Function(UserModel) onSuspend;
  final Function(UserModel) onReactivate;

  const UserManagementTable({
    super.key,
    required this.users,
    required this.onSuspend,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
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
          dataRowMinHeight: 68,
          dataRowMaxHeight: 68,
          horizontalMargin: 24,
          columnSpacing: 32,
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columns: [
            DataColumn(
              label: Text(
                'USER NAME',
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
                'ROLE',
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
                'EMAIL ADDRESS',
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
                'STATUS',
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
          rows: users.map((user) => _buildRow(user)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(UserModel user) {
    final bool isArtisan = user.role == 'Artisan';

    return DataRow(
      cells: [
        // User Name Cell
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isArtisan ? const Color(0xFFD97706).withOpacity(0.15) : const Color(0xFF004D40).withOpacity(0.15),
                child: Text(
                  (user.displayName ?? user.email)[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: isArtisan ? const Color(0xFFD97706) : const Color(0xFF004D40),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'User',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Joined ${user.joinedDate}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Role Cell
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isArtisan ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              user.role,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isArtisan ? const Color(0xFFB45309) : const Color(0xFF0369A1),
              ),
            ),
          ),
        ),

        // Email Cell
        DataCell(
          Text(
            user.email,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF475569),
            ),
          ),
        ),

        // Status Cell (Active / Suspended)
        DataCell(
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: user.isSuspended ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.isSuspended ? 'Suspended' : 'Active',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: user.isSuspended ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),

        // Actions Cell (Suspend / Reactivate)
        DataCell(
          user.isSuspended
              ? ElevatedButton.icon(
                  onPressed: () => onReactivate(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const Text('Reactivate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              : OutlinedButton.icon(
                  onPressed: () => onSuspend(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.block_rounded, size: 14),
                  label: const Text('Suspend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
        ),
      ],
    );
  }
}
