import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

class AdminActiveArtisansTab extends StatefulWidget {
  const AdminActiveArtisansTab({super.key});

  @override
  State<AdminActiveArtisansTab> createState() => _AdminActiveArtisansTabState();
}

class _AdminActiveArtisansTabState extends State<AdminActiveArtisansTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All Categories';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ModerationViewModel>().fetchActiveArtisans();
    });
  }

  final List<String> _categories = const [
    'All Categories',
    'Pottery & Ceramics',
    'Batik Weaving',
    'Wood Carving',
    'Songket Weaving',
    'Pewter Craft',
  ];

  void _showArtisanProfileModal(BuildContext context, ActiveArtisanMaster artisan) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF004D40).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Color(0xFF004D40), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artisan.name,
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'SSM & Kraftangan Verified Master Artisan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (artisan.isDualRole) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'DUAL ROLE ACCOUNT: This master is active as both an Artisan studio host and a Cultural Explorer.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildModalInfoRow('Craft Specialization', artisan.category, Icons.category_outlined),
                      const Divider(height: 20),
                      _buildModalInfoRow('Location & State', '${artisan.state}, Malaysia', Icons.location_on_outlined),
                      const Divider(height: 20),
                      _buildModalInfoRow('SSM License No.', artisan.licenseNo, Icons.verified_user_outlined),
                      const Divider(height: 20),
                      _buildModalInfoRow('Experience & Mastery', artisan.experience, Icons.history_edu_outlined),
                      const Divider(height: 20),
                      _buildModalInfoRow('Contact Phone', artisan.phone, Icons.phone_outlined),
                      const Divider(height: 20),
                      _buildModalInfoRow('Contact Email', artisan.email, Icons.email_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Master Artisan Bio & Heritage Statement',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  artisan.bio,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Close Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  void _confirmSuspendDialog(BuildContext context, ModerationViewModel vm, ActiveArtisanMaster artisan) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Text('Suspend Master License?', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
          ],
        ),
        content: Text(
          'Are you sure you want to suspend license ${artisan.licenseNo} (${artisan.name})? The studio will be hidden from the tourist directory until reactivated.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await vm.suspendActiveArtisan(artisan.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Suspended master studio: ${artisan.name}'),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            icon: const Icon(Icons.block_rounded, size: 16),
            label: const Text('Suspend License'),
          ),
        ],
      ),
    );
  }

  void _confirmReactivateDialog(BuildContext context, ModerationViewModel vm, ActiveArtisanMaster artisan) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 10),
            Text('Reactivate Master Studio?', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
          ],
        ),
        content: Text(
          'Reactivate license ${artisan.licenseNo} (${artisan.name})? The studio will become visible to cultural tourists again.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await vm.reactivateActiveArtisan(artisan.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reactivated master studio: ${artisan.name}'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text('Reactivate Studio'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ModerationViewModel>();

    final filteredList = vm.activeArtisanMasters.where((artisan) {
      final matchesSearch = _searchQuery.isEmpty ||
          artisan.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.licenseNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All Categories' ||
          artisan.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    final liveCount = vm.activeArtisanMasters.where((a) => !a.isSuspended).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Master Artisans Directory',
                      softWrap: true,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitor, inspect, and manage verified traditional craft masters actively published on WarisanKita.',
                      softWrap: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$liveCount Verified Masters Live',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Filters Row (Search + Category Filter)
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by master name, SSM license #, craft, or location state...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: filteredList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text(
                            'No active artisans match the selected filters.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 960),
                      child: DataTable(
                        headingRowHeight: 52,
                        dataRowMaxHeight: 80,
                        horizontalMargin: 20,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('MASTER ARTISAN & STUDIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('CRAFT & STATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('LICENSE & PLAQUES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('STUDIO LIVE STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        ],
                        rows: filteredList.map((artisan) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(artisan.imageUrl),
                                      onBackgroundImageError: (_, __) {},
                                      child: Text(artisan.name[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              artisan.name,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            if (artisan.isDualRole) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF0FDF4),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                                ),
                                                child: Text(
                                                  'Dual Role',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF16A34A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          '${artisan.experience} Experience • ${artisan.email}',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(artisan.category, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12)),
                                    Text('📍 ${artisan.state}, Malaysia', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('License: ${artisan.licenseNo}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF004D40))),
                                    Text('🏅 ${artisan.plaques} Digital Plaques Issued', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: artisan.isSuspended ? null : () => vm.toggleActiveArtisanLiveStatus(artisan.id),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: artisan.isSuspended
                                          ? const Color(0xFFFEF2F2)
                                          : (artisan.isLiveOpen ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: artisan.isSuspended
                                            ? const Color(0xFFEF4444)
                                            : (artisan.isLiveOpen ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                      ),
                                    ),
                                    child: Text(
                                      artisan.statusText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: artisan.isSuspended
                                            ? const Color(0xFFB91C1C)
                                            : (artisan.isLiveOpen ? const Color(0xFF047857) : const Color(0xFFB45309)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _showArtisanProfileModal(context, artisan),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        side: const BorderSide(color: Color(0xFF004D40)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF004D40)),
                                      label: Text(
                                        'Details',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF004D40),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (artisan.isSuspended)
                                      IconButton(
                                        icon: const Icon(Icons.replay_rounded, color: Color(0xFF10B981), size: 18),
                                        tooltip: 'Reactivate Studio',
                                        onPressed: () => _confirmReactivateDialog(context, vm, artisan),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 18),
                                        tooltip: 'Suspend Master License',
                                        onPressed: () => _confirmSuspendDialog(context, vm, artisan),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}