import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/gamification_moderation_request.dart';
import 'package:warisan_kita/viewmodels/gamification_moderation_viewmodel.dart';

class AdminQuestApprovalsTab extends StatefulWidget {
  const AdminQuestApprovalsTab({super.key});

  @override
  State<AdminQuestApprovalsTab> createState() => _AdminQuestApprovalsTabState();
}

class _AdminQuestApprovalsTabState extends State<AdminQuestApprovalsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GamificationModerationViewModel>().loadRequests();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GamificationModerationViewModel>();
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(viewModel, isMobile),
          const SizedBox(height: 20),
          _buildFilters(viewModel),
          const SizedBox(height: 20),
          if (viewModel.error != null) ...[
            _buildError(viewModel),
            const SizedBox(height: 14),
          ],
          Expanded(child: _buildBody(viewModel, isMobile)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    GamificationModerationViewModel viewModel,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Gamification Moderation',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: isMobile ? 24 : 30,
                color: const Color(0xFF0F172A),
              ),
            ),
            _pill(
              '${viewModel.totalCount} Pending',
              background: const Color(0xFFFEF3C7),
              foreground: const Color(0xFFB45309),
            ),
            IconButton(
              tooltip: 'Refresh requests',
              onPressed: viewModel.isLoading ? null : viewModel.loadRequests,
              icon: const Icon(Icons.refresh_rounded),
              color: const Color(0xFF00695C),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Review new tasks and proposed changes before they go live.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(GamificationModerationViewModel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            viewModel,
            GamificationModerationFilter.all,
            'All ${viewModel.totalCount}',
          ),
          _filterChip(
            viewModel,
            GamificationModerationFilter.newTasks,
            'New Tasks ${viewModel.newTaskCount}',
          ),
          _filterChip(
            viewModel,
            GamificationModerationFilter.taskChanges,
            'Task Changes ${viewModel.taskChangeCount}',
          ),
          _filterChip(
            viewModel,
            GamificationModerationFilter.deleteRequests,
            'Delete Requests ${viewModel.deleteRequestCount}',
          ),
          _filterChip(
            viewModel,
            GamificationModerationFilter.questChanges,
            'Quest Changes ${viewModel.questChangeCount}',
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    GamificationModerationViewModel viewModel,
    GamificationModerationFilter filter,
    String label,
  ) {
    final selected = viewModel.filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => viewModel.setFilter(filter),
        label: Text(label),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: selected ? Colors.white : const Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: const Color(0xFF00695C),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF00695C) : const Color(0xFFE2E8F0),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
    );
  }

  Widget _buildError(GamificationModerationViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB91C1C),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              viewModel.error!,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF991B1B),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: viewModel.loadRequests,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GamificationModerationViewModel viewModel, bool isMobile) {
    if (viewModel.isLoading && viewModel.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00695C)),
      );
    }

    final requests = viewModel.filteredRequests;
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.task_alt_rounded,
              size: 56,
              color: Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            Text(
              'No pending requests in this category.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 21,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadRequests,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final request = requests[index];
          return switch (request.type) {
            GamificationModerationRequestType.newTask => _buildNewTaskCard(
              viewModel,
              request,
              isMobile,
            ),
            GamificationModerationRequestType.taskChange =>
              _buildTaskChangeCard(viewModel, request, isMobile),
            GamificationModerationRequestType.questChange =>
              _buildQuestChangeCard(viewModel, request, isMobile),
          };
        },
      ),
    );
  }

  Widget _buildNewTaskCard(
    GamificationModerationViewModel viewModel,
    GamificationModerationRequest request,
    bool isMobile,
  ) {
    final task = request.task!;
    return _requestCard(
      isMobile: isMobile,
      header: Wrap(
        spacing: 8,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _requestTypeBadge(
            '+  NEW TASK',
            const Color(0xFF047857),
            const Color(0xFFD1FAE5),
          ),
          _pill(
            request.quest.category,
            background: const Color(0xFFEFF6FF),
            foreground: const Color(0xFF1D4ED8),
          ),
          _pill(
            task.isRequired ? 'REQUIRED' : 'OPTIONAL',
            background: const Color(0xFFF1F5F9),
            foreground: const Color(0xFF334155),
          ),
          _pill(
            '+${task.xpReward} XP',
            background: const Color(0xFFFEF3C7),
            foreground: const Color(0xFFB45309),
          ),
        ],
      ),
      title: task.title,
      request: request,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'New activity proposed for “${request.quest.title}”.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF475569),
            fontSize: 13,
          ),
        ),
      ),
      actions: _reviewActions(viewModel, request),
    );
  }

  Widget _buildTaskChangeCard(
    GamificationModerationViewModel viewModel,
    GamificationModerationRequest request,
    bool isMobile,
  ) {
    final task = request.task!;
    final change = request.taskChange!;
    final isDelete = request.isDeleteRequest;
    final changes = <Widget>[];

    if (!isDelete) {
      if (change.proposedTitle != null && change.proposedTitle != task.title) {
        changes.add(
          _comparisonRow('Task title', task.title, change.proposedTitle!),
        );
      }
      if (change.proposedIsRequired != null &&
          change.proposedIsRequired != task.isRequired) {
        changes.add(
          _comparisonRow(
            'Task type',
            task.isRequired ? 'Required' : 'Optional',
            change.proposedIsRequired! ? 'Required' : 'Optional',
          ),
        );
      }
      if (change.proposedXpReward != null &&
          change.proposedXpReward != task.xpReward) {
        changes.add(
          _comparisonRow(
            'XP reward',
            '+${task.xpReward} XP',
            '+${change.proposedXpReward} XP',
          ),
        );
      }
    }

    return _requestCard(
      isMobile: isMobile,
      header: Wrap(
        spacing: 8,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _requestTypeBadge(
            isDelete ? '−  DELETE TASK' : '✎  TASK CHANGE',
            isDelete ? const Color(0xFFB91C1C) : const Color(0xFF7C3AED),
            isDelete ? const Color(0xFFFEE2E2) : const Color(0xFFEDE9FE),
          ),
          _pill(
            request.quest.category,
            background: const Color(0xFFEFF6FF),
            foreground: const Color(0xFF1D4ED8),
          ),
          _pill(
            task.isRequired ? 'REQUIRED' : 'OPTIONAL',
            background: const Color(0xFFF1F5F9),
            foreground: const Color(0xFF334155),
          ),
        ],
      ),
      title: task.title,
      request: request,
      body: isDelete ? _deleteWarning(task.title) : _changesPanel(changes),
      actions: _reviewActions(viewModel, request),
    );
  }

  Widget _buildQuestChangeCard(
    GamificationModerationViewModel viewModel,
    GamificationModerationRequest request,
    bool isMobile,
  ) {
    final quest = request.quest;
    final change = request.questChange!;
    final changes = <Widget>[];

    if (change.proposedTitle != quest.title) {
      changes.add(
        _comparisonRow('Quest title', quest.title, change.proposedTitle),
      );
    }
    if (change.proposedCategory != quest.category) {
      changes.add(
        _comparisonRow('Category', quest.category, change.proposedCategory),
      );
    }
    if (change.proposedDescription != quest.description) {
      changes.add(
        _comparisonRow(
          'Description',
          quest.description,
          change.proposedDescription,
        ),
      );
    }

    return _requestCard(
      isMobile: isMobile,
      header: Wrap(
        spacing: 8,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _requestTypeBadge(
            '✎  QUEST CHANGE',
            const Color(0xFF9A3412),
            const Color(0xFFFFEDD5),
          ),
          _pill(
            'PENDING REVIEW',
            background: const Color(0xFFFEF3C7),
            foreground: const Color(0xFFB45309),
          ),
        ],
      ),
      title: quest.title,
      request: request,
      body: _changesPanel(changes),
      actions: _reviewActions(viewModel, request),
    );
  }

  Widget _requestCard({
    required bool isMobile,
    required Widget header,
    required String title,
    required GamificationModerationRequest request,
    required Widget body,
    required Widget actions,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 17 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 15),
          Text(
            title,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: isMobile ? 20 : 23,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Artisan: ${request.artisanName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Submitted: ${_formatSubmitted(request.submittedAt)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          body,
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      ),
    );
  }

  Widget _changesPanel(List<Widget> changes) {
    return Container(
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
            'CHANGES REQUESTED',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF475569),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          if (changes.isEmpty)
            Text(
              'No changed fields were detected.',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            )
          else
            ...changes,
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, String current, String requested) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          _valueRow('Current', current, const Color(0xFF64748B)),
          const SizedBox(height: 5),
          _valueRow('Requested', requested, const Color(0xFF047857)),
        ],
      ),
    );
  }

  Widget _valueRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: valueColor,
              fontSize: 12,
              fontWeight: label == 'Requested'
                  ? FontWeight.w700
                  : FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _deleteWarning(String taskTitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.archive_outlined,
            color: Color(0xFFB91C1C),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'The artisan requested removal of “$taskTitle”. Approval will archive the task and remove it from the tourist quest.',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF991B1B),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewActions(
    GamificationModerationViewModel viewModel,
    GamificationModerationRequest request,
  ) {
    final isReviewing = viewModel.isReviewing(request.id);
    final approveLabel = switch (request.type) {
      GamificationModerationRequestType.newTask => 'Approve & Publish',
      GamificationModerationRequestType.taskChange =>
        request.isDeleteRequest ? 'Approve Removal' : 'Approve Changes',
      GamificationModerationRequestType.questChange => 'Approve Changes',
    };
    final rejectLabel = request.isNewTask ? 'Reject' : 'Reject Changes';

    return Wrap(
      spacing: 10,
      runSpacing: 9,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: isReviewing
              ? null
              : () => _rejectRequest(viewModel, request),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB91C1C),
            side: const BorderSide(color: Color(0xFFFCA5A5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
          icon: const Icon(Icons.close_rounded, size: 17),
          label: Text(rejectLabel),
        ),
        FilledButton.icon(
          onPressed: isReviewing
              ? null
              : () => _approveRequest(viewModel, request),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF047857),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          ),
          icon: isReviewing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 17),
          label: Text(approveLabel),
        ),
      ],
    );
  }

  Future<void> _approveRequest(
    GamificationModerationViewModel viewModel,
    GamificationModerationRequest request,
  ) async {
    final success = await viewModel.reviewRequest(request, approve: true);
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          request.isNewTask
              ? 'Task approved and published.'
              : 'Requested changes approved.',
        ),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _rejectRequest(
    GamificationModerationViewModel viewModel,
    GamificationModerationRequest request,
  ) async {
    final reason = await _requestRejectionReason();
    if (!mounted || reason == null) return;
    final success = await viewModel.reviewRequest(
      request,
      approve: false,
      rejectionReason: reason,
    );
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request rejected and returned to the artisan.'),
        backgroundColor: Color(0xFFB91C1C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _requestRejectionReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Reject Request',
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF0F172A)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Explain what the artisan needs to revise.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(dialogContext).pop(reason);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
            ),
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Widget _requestTypeBadge(String label, Color foreground, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _pill(
    String label, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _formatSubmitted(DateTime? date) {
    if (date == null) return 'Unknown';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}
