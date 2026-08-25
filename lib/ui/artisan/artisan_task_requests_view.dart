import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/models/artisan_task_request.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

class ArtisanTaskRequestsView extends StatelessWidget {
  const ArtisanTaskRequestsView({super.key});

  static const _green = Color(0xFF005B4F);
  static const _gold = Color(0xFFD79A18);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GamificationViewModel>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5EF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _green,
          title: Text(
            'My Requests',
            style: GoogleFonts.dmSerifDisplay(color: _green, fontSize: 22),
          ),
          bottom: const TabBar(
            labelColor: _green,
            indicatorColor: _gold,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _requestList(context, viewModel, 'PENDING_APPROVAL'),
            _requestList(context, viewModel, 'APPROVED'),
            _requestList(context, viewModel, 'REJECTED'),
          ],
        ),
      ),
    );
  }

  Widget _requestList(
    BuildContext context,
    GamificationViewModel viewModel,
    String status,
  ) {
    final requests = viewModel.myRequests
        .where((request) => request.status.toUpperCase() == status)
        .toList(growable: false);
    return RefreshIndicator(
      color: _green,
      onRefresh: viewModel.loadArtisanQuestAndTasks,
      child: requests.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(28),
              children: [
                const SizedBox(height: 130),
                Icon(
                  status == 'PENDING_APPROVAL'
                      ? Icons.hourglass_empty_rounded
                      : status == 'APPROVED'
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  color: _gold,
                  size: 52,
                ),
                const SizedBox(height: 14),
                Text(
                  'No ${status.replaceAll('_', ' ').toLowerCase()} requests',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    color: _green,
                    fontSize: 21,
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              itemCount: requests.length,
              itemBuilder: (_, index) =>
                  _requestCard(context, viewModel, requests[index]),
            ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    GamificationViewModel viewModel,
    ArtisanTaskRequest request,
  ) {
    final statusColor = switch (request.status.toUpperCase()) {
      'APPROVED' => const Color(0xFF087F5B),
      'REJECTED' => const Color(0xFFB42318),
      _ => const Color(0xFF9A6700),
    };
    final isNew = request.type == ArtisanTaskRequestType.newTask;
    final isEdit = request.type == ArtisanTaskRequestType.edit;
    final change = request.changeRequest;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E5E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNew
                    ? Icons.add_task_rounded
                    : isEdit
                    ? Icons.edit_outlined
                    : Icons.delete_outline_rounded,
                color: isNew || isEdit ? _green : const Color(0xFFB42318),
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isNew
                      ? 'NEW TASK'
                      : '${change!.requestType.toUpperCase()} REQUEST',
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusChip(request.status, statusColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isNew ? 'SUBMITTED TASK' : 'ORIGINAL / CURRENT TASK',
            style: _sectionLabelStyle,
          ),
          const SizedBox(height: 8),
          _versionBox(
            title: request.task.title,
            isRequired: request.task.isRequired,
            xpReward: request.task.xpReward,
            inactive: !isNew && request.task.isArchived,
          ),
          if (!isNew) ...[
            const SizedBox(height: 14),
            Text(
              isEdit ? 'REQUESTED VERSION' : 'REQUESTED ACTION',
              style: _sectionLabelStyle,
            ),
            const SizedBox(height: 8),
            if (isEdit)
              _versionBox(
                title: change!.proposedTitle ?? 'No proposed title',
                isRequired: change.proposedIsRequired,
                xpReward: change.proposedXpReward,
              )
            else
              _deleteActionBox(),
          ],
          if (request.rejectionReason != null) ...[
            const SizedBox(height: 14),
            Text('REJECTION REASON', style: _sectionLabelStyle),
            const SizedBox(height: 6),
            Text(
              request.rejectionReason!,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          ],
          if (request.submittedAt != null) ...[
            const SizedBox(height: 14),
            Text(
              'Submitted ${_formatDate(request.submittedAt!)}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
          if (isNew) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: viewModel.isUpdatingNewTask
                      ? null
                      : () => _confirmCancel(context, viewModel, request.task),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB42318),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: Text(
                    request.status.toUpperCase() == 'REJECTED'
                        ? 'Delete'
                        : 'Cancel',
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: viewModel.isUpdatingNewTask
                      ? null
                      : () => _showEditNewTaskSheet(context, request.task),
                  style: FilledButton.styleFrom(backgroundColor: _green),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: Text(
                    request.status.toUpperCase() == 'REJECTED'
                        ? 'Edit & Resubmit'
                        : 'Edit',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditNewTaskSheet(
    BuildContext context,
    HeritageTask task,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<GamificationViewModel>(),
        child: _EditNewTaskSheet(task: task),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    GamificationViewModel viewModel,
    HeritageTask task,
  ) async {
    final isRejected = task.status.toUpperCase() == 'REJECTED';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isRejected ? 'Delete rejected task?' : 'Cancel task submission?',
        ),
        content: const Text(
          'This removes the unapproved task. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: Text(isRejected ? 'Delete Task' : 'Cancel Submission'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await viewModel.cancelNewTaskSubmission(task);
    if (context.mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.artisanTaskError ?? 'Unable to cancel.'),
        ),
      );
    }
  }

  Widget _deleteActionBox() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDEC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'Deactivate this task after admin approval',
      style: TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w700),
    ),
  );

  Widget _statusChip(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status.replaceAll('_', ' ').toUpperCase(),
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
    ),
  );

  Widget _versionBox({
    required String title,
    bool? isRequired,
    int? xpReward,
    bool inactive = false,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7F5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (isRequired != null || xpReward != null) ...[
          const SizedBox(height: 7),
          Text(
            '${isRequired == true ? 'Required' : 'Optional'}'
            '${xpReward == null ? '' : ' · $xpReward XP'}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
        if (inactive) ...[
          const SizedBox(height: 7),
          const Text(
            'NOT ACTIVE',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    ),
  );

  TextStyle get _sectionLabelStyle => const TextStyle(
    color: Color(0xFF64748B),
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.7,
  );

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _EditNewTaskSheet extends StatefulWidget {
  final HeritageTask task;
  const _EditNewTaskSheet({required this.task});

  @override
  State<_EditNewTaskSheet> createState() => _EditNewTaskSheetState();
}

class _EditNewTaskSheetState extends State<_EditNewTaskSheet> {
  static const _green = Color(0xFF005B4F);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _xp;
  late bool _required;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _xp = TextEditingController(text: widget.task.xpReward.toString());
    _required = widget.task.isRequired;
  }

  @override
  void dispose() {
    _title.dispose();
    _xp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await context
        .read<GamificationViewModel>()
        .updateNewTaskSubmission(
          task: widget.task,
          title: _title.text,
          isRequired: _required,
          xpReward: int.parse(_xp.text.trim()),
        );
    if (mounted && success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GamificationViewModel>();
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.status.toUpperCase() == 'REJECTED'
                      ? 'Edit & Resubmit Task'
                      : 'Edit Task Submission',
                  style: GoogleFonts.dmSerifDisplay(
                    color: _green,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saving updates this submission and resets it to pending approval.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Task title is required.'
                      : null,
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Required')),
                    ButtonSegment(value: false, label: Text('Optional')),
                  ],
                  selected: {_required},
                  onSelectionChanged: viewModel.isUpdatingNewTask
                      ? null
                      : (value) => setState(() => _required = value.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _xp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'XP reward',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final xp = int.tryParse(value?.trim() ?? '');
                    return xp == null || xp < 0
                        ? 'Enter a whole number of 0 or more.'
                        : null;
                  },
                ),
                if (viewModel.artisanTaskError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    viewModel.artisanTaskError!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: viewModel.isUpdatingNewTask
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: viewModel.isUpdatingNewTask ? null : _save,
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        child: viewModel.isUpdatingNewTask
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save & Submit'),
                      ),
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
}
