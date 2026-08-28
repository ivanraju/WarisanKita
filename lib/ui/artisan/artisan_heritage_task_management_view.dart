import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/ui/artisan/artisan_task_requests_view.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

class ArtisanHeritageTaskManagementView extends StatefulWidget {
  const ArtisanHeritageTaskManagementView({super.key});

  @override
  State<ArtisanHeritageTaskManagementView> createState() =>
      _ArtisanHeritageTaskManagementViewState();
}

class _ArtisanHeritageTaskManagementViewState
    extends State<ArtisanHeritageTaskManagementView> {
  static const _green = Color(0xFF005B4F);
  static const _gold = Color(0xFFD79A18);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GamificationViewModel>().loadArtisanQuestAndTasks();
      }
    });
  }

  Future<void> _showAddTaskSheet() async {
    final viewModel = context.read<GamificationViewModel>();
    viewModel.clearArtisanTaskError();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _AddHeritageTaskSheet(),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Heritage task submitted for admin approval.'),
          backgroundColor: _green,
        ),
      );
    }
  }

  void _handleAddTaskTap() {
    final viewModel = context.read<GamificationViewModel>();
    if (viewModel.artisanQuest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A cultural quest must be assigned before you can add tasks.',
          ),
          backgroundColor: Color(0xFF9A6700),
        ),
      );
      return;
    }
    _showAddTaskSheet();
  }

  Future<void> _showEditTaskSheet(HeritageTask task) async {
    final viewModel = context.read<GamificationViewModel>();
    viewModel.clearArtisanTaskError();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _EditHeritageTaskSheet(task: task),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task edit request submitted for admin approval.'),
          backgroundColor: _green,
        ),
      );
    }
  }

  Future<void> _requestTaskDeletion(HeritageTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request task deletion?'),
        content: Text(
          '“${task.title}” will remain active until an admin approves the deletion request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await context
        .read<GamificationViewModel>()
        .requestHeritageTaskDelete(task);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deletion request submitted for admin approval.'),
          backgroundColor: _green,
        ),
      );
    }
  }

  void _showWorkshopQr(Quest quest) {
    final secret = quest.qrCodeSecret;
    if (secret == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This workshop QR has not been configured yet.'),
          backgroundColor: Color(0xFFB42318),
        ),
      );
      return;
    }

    final payload = 'WK_ARTISAN:${quest.artisanId}:$secret';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Workshop QR',
                  style: GoogleFonts.dmSerifDisplay(
                    color: _green,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _green, width: 2),
                  ),
                  child: SizedBox.square(
                    dimension: 200,
                    child: QrImageView(
                      data: payload,
                      padding: EdgeInsets.zero,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: _green,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: _green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Display this single QR at your workshop. Tourists scan the '
                  'same code to verify each completed task.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(backgroundColor: _green),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GamificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isLoadingArtisanQuest || viewModel.isAddingTask
            ? null
            : _handleAddTaskTap,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        disabledElevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _green,
        elevation: 0,
        title: Text(
          'Task Management',
          style: GoogleFonts.dmSerifDisplay(color: _green, fontSize: 22),
        ),
      ),
      body: RefreshIndicator(
        color: _green,
        onRefresh: viewModel.loadArtisanQuestAndTasks,
        child: _body(viewModel),
      ),
    );
  }

  Widget _body(GamificationViewModel viewModel) {
    if (viewModel.isLoadingArtisanQuest) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator(color: _green)),
        ],
      );
    }

    if (viewModel.artisanTaskError != null && viewModel.artisanQuest == null) {
      return _stateView(
        icon: Icons.error_outline_rounded,
        title: 'Unable to Load Task Management',
        message: viewModel.artisanTaskError!,
        actionLabel: 'Try Again',
        onAction: viewModel.loadArtisanQuestAndTasks,
      );
    }

    final quest = viewModel.artisanQuest;
    if (quest == null) {
      return _stateView(
        icon: Icons.map_outlined,
        title: 'Cultural Quest Not Configured',
        message:
            'Your studio does not currently have a cultural quest assigned.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      children: [
        Text(
          'MY CULTURAL QUEST',
          style: GoogleFonts.plusJakartaSans(
            color: _green,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _questSummary(quest),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'ACTIVE TASKS',
                style: GoogleFonts.plusJakartaSans(
                  color: _green,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            Text(
              '${viewModel.artisanTasks.length}',
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ArtisanTaskRequestsView(),
                ),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 17),
              label: const Text('View Requests'),
              style: TextButton.styleFrom(foregroundColor: _green),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Potential XP',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            Text(
              '${viewModel.artisanTotalPotentialXp} XP',
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (viewModel.artisanTaskError != null) ...[
          const SizedBox(height: 12),
          _errorBanner(viewModel.artisanTaskError!),
        ],
        const SizedBox(height: 14),
        if (viewModel.artisanTasks.isEmpty)
          _emptyTasks()
        else
          for (var index = 0; index < viewModel.artisanTasks.length; index++)
            _taskCard(index, viewModel.artisanTasks[index]),
        const SizedBox(height: 72),
      ],
    );
  }

  Widget _questSummary(Quest quest) {
    final statusColor = switch (quest.status.toUpperCase()) {
      'APPROVED' => const Color(0xFF087F5B),
      'REJECTED' => const Color(0xFFB42318),
      _ => const Color(0xFF9A6700),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quest.title,
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            quest.category,
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            quest.description,
            style: const TextStyle(color: Color(0xFFD6E7E2), height: 1.45),
          ),
          const SizedBox(height: 18),
          _summaryRow('Interaction Radius', '${quest.geofenceRadiusMeters} m'),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Status',
                  style: TextStyle(color: Color(0xFFD6E7E2)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  quest.status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showWorkshopQr(quest),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('View Workshop QR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD166),
                side: const BorderSide(color: Color(0xFFFFD166)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: Color(0xFFD6E7E2))),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _taskCard(int index, HeritageTask task) {
    final viewModel = context.read<GamificationViewModel>();
    final pendingChange = viewModel.pendingChangeForTask(task.id);
    final statusColor = switch (task.status.toUpperCase()) {
      'APPROVED' => const Color(0xFF087F5B),
      'REJECTED' => const Color(0xFFB42318),
      _ => const Color(0xFF9A6700),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E6E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${index + 1}'.padLeft(2, '0'),
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  task.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: const TextStyle(
              color: Color(0xFF183B34),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: task.isRequired
                      ? const Color(0xFFE0F2ED)
                      : const Color(0xFFF1F3F2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  task.isRequired ? 'REQUIRED' : 'OPTIONAL',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '+${task.xpReward} XP',
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (task.status.toUpperCase() == 'REJECTED' &&
              task.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Reason: ${task.rejectionReason}',
              style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          if (task.isSystemTask)
            const Row(
              children: [
                Icon(Icons.lock_rounded, size: 15, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'SYSTEM TASK · EDITING LOCKED',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          else if (pendingChange != null)
            Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 15,
                  color: Color(0xFF9A6700),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${pendingChange.requestType} REQUEST PENDING APPROVAL',
                    style: const TextStyle(
                      color: Color(0xFF9A6700),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: viewModel.isSubmittingTaskChange
                      ? null
                      : () => _showEditTaskSheet(task),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: viewModel.isSubmittingTaskChange
                      ? null
                      : () => _requestTaskDeletion(task),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB42318),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('Delete'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _emptyTasks() => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(Icons.playlist_add_rounded, color: _gold, size: 38),
        SizedBox(height: 10),
        Text('No approved active tasks yet.'),
      ],
    ),
  );

  Widget _errorBanner(String message) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDEC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318)),
        const SizedBox(width: 9),
        Expanded(child: Text(message)),
      ],
    ),
  );

  Widget _stateView({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(28),
    children: [
      const SizedBox(height: 130),
      Icon(icon, size: 58, color: _gold),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSerifDisplay(color: _green, fontSize: 24),
      ),
      const SizedBox(height: 8),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
      ),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    ],
  );
}

class _AddHeritageTaskSheet extends StatefulWidget {
  const _AddHeritageTaskSheet();

  @override
  State<_AddHeritageTaskSheet> createState() => _AddHeritageTaskSheetState();
}

class _AddHeritageTaskSheetState extends State<_AddHeritageTaskSheet> {
  static const _green = Color(0xFF005B4F);
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _xp = TextEditingController(text: '50');
  bool _required = true;

  @override
  void dispose() {
    _title.dispose();
    _xp.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await context.read<GamificationViewModel>().addHeritageTask(
      title: _title.text,
      isRequired: _required,
      xpReward: int.parse(_xp.text.trim()),
    );
    if (mounted && success) {
      Navigator.of(context).pop(true);
    }
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
                  'Submit Heritage Task',
                  style: GoogleFonts.dmSerifDisplay(
                    color: _green,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The task will be saved as pending and sent for admin approval.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  decoration: _decoration('Task title'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Task title is required.'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Task type',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Required')),
                    ButtonSegment(value: false, label: Text('Optional')),
                  ],
                  selected: {_required},
                  onSelectionChanged: viewModel.isAddingTask
                      ? null
                      : (selection) =>
                            setState(() => _required = selection.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _xp,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('XP reward'),
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
                        onPressed: viewModel.isAddingTask
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: viewModel.isAddingTask ? null : _add,
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        child: viewModel.isAddingTask
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit'),
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

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _EditHeritageTaskSheet extends StatefulWidget {
  final HeritageTask task;

  const _EditHeritageTaskSheet({required this.task});

  @override
  State<_EditHeritageTaskSheet> createState() => _EditHeritageTaskSheetState();
}

class _EditHeritageTaskSheetState extends State<_EditHeritageTaskSheet> {
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await context
        .read<GamificationViewModel>()
        .requestHeritageTaskEdit(
          task: widget.task,
          title: _title.text,
          isRequired: _required,
          xpReward: int.parse(_xp.text.trim()),
        );
    if (mounted && success) {
      Navigator.of(context).pop(true);
    }
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
                  'Request Task Edit',
                  style: GoogleFonts.dmSerifDisplay(
                    color: _green,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The existing task remains unchanged until an admin approves this request.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  decoration: _decoration('Task title'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Task title is required.'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Task type',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Required')),
                    ButtonSegment(value: false, label: Text('Optional')),
                  ],
                  selected: {_required},
                  onSelectionChanged: viewModel.isSubmittingTaskChange
                      ? null
                      : (selection) =>
                            setState(() => _required = selection.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _xp,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('XP reward'),
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
                        onPressed: viewModel.isSubmittingTaskChange
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: viewModel.isSubmittingTaskChange
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        child: viewModel.isSubmittingTaskChange
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit Request'),
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

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
