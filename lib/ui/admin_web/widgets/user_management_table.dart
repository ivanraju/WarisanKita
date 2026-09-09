import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/domain/models/user.dart';

class UserManagementTable extends StatelessWidget {
  final List<UserModel> users;
  final Function(UserModel) onSuspend;
  final Function(UserModel) onReactivate;
  final Function(UserModel)? onResetPassword;

  const UserManagementTable({
    super.key,
    required this.users,
    required this.onSuspend,
    required this.onReactivate,
    this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth > 960 ? constraints.maxWidth : 960,
                ),
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
          },
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
            mainAxisSize: MainAxisSize.min,
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
                    user.username != null && user.username!.isNotEmpty
                        ? (user.joinedDate.isNotEmpty
                            ? '@${user.username} • Joined ${user.joinedDate}'
                            : '@${user.username}')
                        : (user.joinedDate.isNotEmpty
                            ? 'Joined ${user.joinedDate}'
                            : ''),
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
          Builder(
            builder: (context) {
              final r = user.role.toLowerCase();
              final bool isAdmin = r.contains('admin');
              final bool isDual = user.isDualRole || r.contains('&') || (r.contains('artisan') && r.contains('tourist'));
              final bool isArt = !isDual && (r.contains('artisan') || user.isArtisan);

              Color bgColor;
              Color textColor;
              Color borderColor;
              IconData roleIcon;

              if (isAdmin) {
                bgColor = const Color(0xFFF5F3FF);
                textColor = const Color(0xFF6D28D9);
                borderColor = const Color(0xFFDDD6FE);
                roleIcon = Icons.shield_rounded;
              } else if (isDual) {
                bgColor = const Color(0xFFF0FDF4);
                textColor = const Color(0xFF15803D);
                borderColor = const Color(0xFF86EFAC);
                roleIcon = Icons.auto_awesome_rounded;
              } else if (isArt) {
                bgColor = const Color(0xFFFEF3C7);
                textColor = const Color(0xFFB45309);
                borderColor = const Color(0xFFFDE68A);
                roleIcon = Icons.palette_rounded;
              } else {
                bgColor = const Color(0xFFE0F2FE);
                textColor = const Color(0xFF0369A1);
                borderColor = const Color(0xFFBAE6FD);
                roleIcon = Icons.explore_rounded;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 12, color: textColor),
                    const SizedBox(width: 5),
                    Text(
                      user.role,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              );
            },
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

        // Actions Cell (Suspend / Reactivate + Reset Password)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.role.toLowerCase().contains('admin') || user.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        'Admin (Protected)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              else if (user.isSuspended)
                ElevatedButton.icon(
                  onPressed: () => onReactivate(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const Text('Reactivate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => onSuspend(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.block_rounded, size: 14),
                  label: const Text('Suspend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFF64748B)),
                tooltip: 'Send Password Reset Email',
                onPressed: onResetPassword != null ? () => onResetPassword!(user) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
