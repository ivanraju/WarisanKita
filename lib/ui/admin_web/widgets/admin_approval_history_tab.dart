import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/approval_history_record.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

class AdminApprovalHistoryTab extends StatefulWidget {
  const AdminApprovalHistoryTab({super.key});

  @override
  State<AdminApprovalHistoryTab> createState() =>
      _AdminApprovalHistoryTabState();
}

class _AdminApprovalHistoryTabState extends State<AdminApprovalHistoryTab> {
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ModerationViewModel>();
      vm.loadApprovalHistory();
      _searchController.text = vm.historySearchQuery;
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ModerationViewModel>();
    final records = viewModel.filteredApprovalHistory;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval History & Audit Trail',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Official immutable audit log of all approved master artisans and workshop premise relocations.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 12 : 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF004D40).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF004D40),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${viewModel.totalApprovalHistoryCount} Logged',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF004D40),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Summary Metric Cards Row
          _buildMetricsCardsRow(context, viewModel, isMobile),

          const SizedBox(height: 28),

          // Filters & Search Bar Row
          _buildFilterControls(context, viewModel, isMobile),

          const SizedBox(height: 20),

          // Approvals Records Table Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.history_edu_rounded,
                              size: 20,
                              color: Color(0xFF004D40),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Approval Ledger (${records.length})',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 18,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        if (viewModel.historySearchQuery.isNotEmpty ||
                            viewModel.historyTypeFilter != 'All Types')
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              viewModel.setHistorySearchQuery('');
                              viewModel.setHistoryTypeFilter('All Types');
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset Filters'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  if (records.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.folder_open_rounded,
                              size: 40,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            viewModel.historySearchQuery.isNotEmpty ||
                                    viewModel.historyTypeFilter != 'All Types'
                                ? 'No approval records match your filter criteria'
                                : 'No approval records recorded yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Approvals completed by administrators will automatically be logged here with complete timestamps.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 980),
                          child: DataTable(
                            horizontalMargin: 24,
                            columnSpacing: 24,
                            headingRowHeight: 48,
                            dataRowMinHeight: 68,
                            dataRowMaxHeight: 76,
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF8FAFC),
                            ),
                            columns: [
                              DataColumn(
                                label: Text(
                                  'MASTER ARTISAN / STUDIO',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'APPROVAL TYPE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'APPROVAL DETAILS & PREMISE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'DATE & TIME',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'MODERATOR',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'ACTIONS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            rows: records.map((record) {
                              return _buildDataRow(context, record);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCardsRow(
    BuildContext context,
    ModerationViewModel vm,
    bool isMobile,
  ) {
    final total = vm.totalApprovalHistoryCount;
    final profiles = vm.profileApprovalCount;
    final relocations = vm.relocationApprovalCount;
    final rejections = vm.rejectionHistoryCount;

    final cards = [
      _buildMetricCard(
        title: 'Total Decisions Logged',
        count: total.toString(),
        subtitle: 'All-time audit records',
        icon: Icons.assignment_turned_in_rounded,
        iconColor: const Color(0xFF004D40),
        bgColor: const Color(0xFFE0F2F1),
      ),
      _buildMetricCard(
        title: 'Artisan Profiles Approved',
        count: profiles.toString(),
        subtitle: 'Accredited masters & studios',
        icon: Icons.person_pin_rounded,
        iconColor: const Color(0xFF0284C7),
        bgColor: const Color(0xFFE0F2FE),
      ),
      _buildMetricCard(
        title: 'Premise Relocations Approved',
        count: relocations.toString(),
        subtitle: 'Verified workshop relocations',
        icon: Icons.swap_horiz_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _buildMetricCard(
        title: 'Applications Rejected',
        count: rejections.toString(),
        subtitle: 'Declined submissions',
        icon: Icons.cancel_outlined,
        iconColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEE2E2),
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: c,
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: cards
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: c,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(
    BuildContext context,
    ModerationViewModel vm,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(vm),
                const SizedBox(height: 12),
                _buildTypeFilterDropdown(vm),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSearchField(vm)),
                const SizedBox(width: 16),
                _buildTypeFilterDropdown(vm),
              ],
            ),
    );
  }

  Widget _buildSearchField(ModerationViewModel vm) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => vm.setHistorySearchQuery(val),
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
      decoration: InputDecoration(
        hintText:
            'Search approval records by artisan, craft, email, state, or SSM...',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: const Color(0xFF94A3B8),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: Color(0xFF94A3B8),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  vm.setHistorySearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF004D40), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypeFilterDropdown(ModerationViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.historyTypeFilter,
          icon: const Icon(
            Icons.filter_list_rounded,
            size: 18,
            color: Color(0xFF004D40),
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          items: vm.historyTypeFilters.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (newVal) {
            if (newVal != null) {
              vm.setHistoryTypeFilter(newVal);
            }
          },
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, ApprovalHistoryRecord record) {
    final isRelocation = record.isRelocation;
    final isRejected = record.status.toUpperCase() == 'REJECTED';

    return DataRow(
      cells: [
        // Artisan / Studio
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRejected
                        ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                        : isRelocation
                            ? [const Color(0xFFD97706), const Color(0xFFB45309)]
                            : [const Color(0xFF004D40), const Color(0xFF00796B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    record.targetName.isNotEmpty
                        ? record.targetName.substring(0, 1).toUpperCase()
                        : 'A',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    record.targetName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record.craftCategory,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${record.state}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    record.targetEmail,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Approval Type
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isRejected
                  ? const Color(0xFFFEE2E2)
                  : isRelocation
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isRejected
                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                    : isRelocation
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                        : const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRejected
                      ? Icons.cancel_rounded
                      : isRelocation
                          ? Icons.swap_horiz_rounded
                          : Icons.verified_rounded,
                  size: 14,
                  color: isRejected
                      ? const Color(0xFFDC2626)
                      : isRelocation
                          ? const Color(0xFFB45309)
                          : const Color(0xFF047857),
                ),
                const SizedBox(width: 6),
                Text(
                  isRejected
                      ? 'Rejected (${record.approvalType})'
                      : record.approvalType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isRejected
                        ? const Color(0xFFDC2626)
                        : isRelocation
                            ? const Color(0xFFB45309)
                            : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Approval Details
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Date & Time
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.formattedDate,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                record.formattedTime,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),

        // Moderator
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isRejected
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.gavel_rounded : Icons.shield_rounded,
                  size: 12,
                  color: isRejected
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                record.approvedBy,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),

        // Action Button
        DataCell(
          ElevatedButton.icon(
            onPressed: () => _showAuditDetailsModal(context, record),
            icon: const Icon(Icons.visibility_rounded, size: 14),
            label: const Text('Audit Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAuditDetailsModal(
    BuildContext context,
    ApprovalHistoryRecord record,
  ) {
    final isRelocation = record.isRelocation;
    final isRejected = record.status.toUpperCase() == 'REJECTED';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isRejected
                                      ? const Color(0xFFFEE2E2)
                                      : isRelocation
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isRejected
                                      ? 'REJECTED • ${record.approvalType.toUpperCase()}'
                                      : record.approvalType.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isRejected
                                        ? const Color(0xFFDC2626)
                                        : isRelocation
                                            ? const Color(0xFFB45309)
                                            : const Color(0xFF047857),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isRejected
                                    ? 'Official Rejection Record'
                                    : 'Official Approval Record',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Warisan Kita Heritage Moderation System • Immutable Ledger',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Information Grid
                    _buildAuditFieldRow(
                      'Record ID',
                      record.id,
                      isRejected ? 'Decided On' : 'Approved On',
                      record.formattedDateTime,
                    ),
                    const SizedBox(height: 12),
                    _buildAuditFieldRow(
                      'Target Studio / Master',
                      record.targetName,
                      'Contact Email',
                      record.targetEmail,
                    ),
                    const SizedBox(height: 12),
                    _buildAuditFieldRow(
                      'Craft Specialization',
                      record.craftCategory,
                      'State / Region',
                      record.state,
                    ),
                    if (record.ssmNumber != null) ...[
                      const SizedBox(height: 12),
                      _buildAuditFieldRow(
                        'SSM / License No.',
                        record.ssmNumber!,
                        'Moderator',
                        record.approvedBy,
                      ),
                    ],

                    if (isRelocation) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premise Relocation Audit Trail',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPremiseLocationTile(
                              'Former Premise Address',
                              record.previousPremise ?? 'Not specified',
                              Icons.location_off_rounded,
                              const Color(0xFFDC2626),
                            ),
                            const SizedBox(height: 8),
                            _buildPremiseLocationTile(
                              'Approved New Workshop Address',
                              record.newPremise ?? record.state,
                              Icons.check_circle_rounded,
                              const Color(0xFF16A34A),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Summary Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ledger Note & Action Detail',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.details,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Verification Seal Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isRejected
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRejected
                                ? Icons.gavel_rounded
                                : Icons.verified_user_rounded,
                            color: isRejected
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF059669),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isRejected
                                  ? 'DECISION RECORDED • Official Warisan Kita Heritage Administration Audit Seal'
                                  : 'VERIFIED & SECURED • Official Warisan Kita Heritage Administration Audit Seal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isRejected
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Close Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Close Record'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditFieldRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return Row(
      children: [
        Expanded(child: _buildAuditField(label1, value1)),
        const SizedBox(width: 16),
        Expanded(child: _buildAuditField(label2, value2)),
      ],
    );
  }

  Widget _buildAuditField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiseLocationTile(
    String label,
    String address,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF78350F),
                ),
              ),
              Text(
                address,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
