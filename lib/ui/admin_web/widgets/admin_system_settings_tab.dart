import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSystemSettingsTab extends StatefulWidget {
  const AdminSystemSettingsTab({super.key});

  @override
  State<AdminSystemSettingsTab> createState() => _AdminSystemSettingsTabState();
}

class _AdminSystemSettingsTabState extends State<AdminSystemSettingsTab> {
  bool _requireMfaForModeration = true;
  bool _autoFlagMissingDocs = true;
  bool _enableAuditTrailLogging = true;
  bool _autoFlagForumSpam = true;

  final double _maxFileSizeMb = 5.0;
  final int _minDeletionReasonLength = 10;

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'System Moderation Settings Saved Successfully!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Admin System Settings',
                style: GoogleFonts.dmSerifDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'v1.0.4 Production',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure platform moderation constraints, security session rules, and database API services.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
          ),

          const SizedBox(height: 32),

          // SECTION 1: SECURITY & SESSION CONTROL (C1 & C3)
          _buildSettingsCard(
            title: 'Security & Admin Session Control',
            subtitle: 'Enforce active session timeouts and audit logging',
            icon: Icons.shield_outlined,
            children: [
              _buildSwitchRow(
                title: 'Require MFA for Administrative Moderation Actions',
                subtitle: 'Prompts two-factor authentication before deleting forum threads or suspending users',
                value: _requireMfaForModeration,
                onChanged: (val) => setState(() => _requireMfaForModeration = val),
              ),
              const Divider(height: 24),
              _buildSwitchRow(
                title: 'Security Audit Trail Logging (C3 Constraint)',
                subtitle: 'Record admin_id, action_timestamp, and IP address for all moderation edits',
                value: _enableAuditTrailLogging,
                onChanged: (val) => setState(() => _enableAuditTrailLogging = val),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // SECTION 2: ARTISAN VERIFICATION RULES (C1 & C2)
          _buildSettingsCard(
            title: 'Artisan Moderation & Verification Rules',
            subtitle: 'SSM license check, proof document enforcement, and image size limits',
            icon: Icons.assignment_ind_outlined,
            children: [
              _buildSwitchRow(
                title: 'Auto-Flag Profiles Missing SSM or Kraftangan Documents',
                subtitle: 'Automatically highlight applications that do not include business proof certificates',
                value: _autoFlagMissingDocs,
                onChanged: (val) => setState(() => _autoFlagMissingDocs = val),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max Portfolio Image Upload Limit (C1 Constraint)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        'Uploaded media files must be JPEG/PNG and below this limit',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '${_maxFileSizeMb.toInt()} MB Max',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // SECTION 3: FORUM MODERATION RULES (C2)
          _buildSettingsCard(
            title: 'Forum Community Moderation Constraints',
            subtitle: 'Deletion reason requirements and automated spam detection',
            icon: Icons.forum_outlined,
            children: [
              _buildSwitchRow(
                title: 'Automated Spam & Keyword Filter',
                subtitle: 'Auto-flag reported forum replies matching offensive spam patterns',
                value: _autoFlagForumSpam,
                onChanged: (val) => setState(() => _autoFlagForumSpam = val),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum Deletion Reason Length (C2 Constraint)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        'Enforces deletion_reason.length >= 10 when removing posts',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '$_minDeletionReasonLength Characters',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // SAVE BUTTON
          SizedBox(
            width: 240,
            child: FilledButton.icon(
              onPressed: _saveSettings,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF0F172A))),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF10B981),
        ),
      ],
    );
  }
}
