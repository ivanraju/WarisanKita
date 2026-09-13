import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

const _progressProtectionNotice =
    'Existing tourist progress will be protected. New tasks become bonus '
    'activities for tourists who already started. Previously awarded XP will '
    'not change.';

final _unsupportedControlCharacters = RegExp(
  r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
);

String? _boundedRequiredText(
  String? value, {
  required String label,
  required int maxLength,
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '$label is required.';
  }
  if (_unsupportedControlCharacters.hasMatch(trimmed)) {
    return '$label contains unsupported characters.';
  }
  if (trimmed.length > maxLength) {
    return '$label must be $maxLength characters or fewer.';
  }
  return null;
}

String? _taskXpError(String? value) {
  final xp = int.tryParse(value?.trim() ?? '');
  return xp == null || xp < 0 || xp > GamificationViewModel.maxTaskXpReward
      ? 'Enter a whole number from 0 to ${GamificationViewModel.maxTaskXpReward}.'
      : null;
}

Widget _buildProgressProtectionNotice({required bool isDark}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF332A12) : const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFE9B949),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.shield_outlined,
          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF9A6700),
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _progressProtectionNotice,
            style: TextStyle(
              color: isDark ? const Color(0xFFFFE8A3) : const Color(0xFF6B4F00),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

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
          content: Text(
            'Heritage task submitted for admin approval.',
            style: TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Color(0xFF00695C),
          behavior: SnackBarBehavior.floating,
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
            style: TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Color(0xFF9A6700),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _showAddTaskSheet();
  }

  Future<void> _showEditTaskSheet(
    HeritageTask task, {
    HeritageTaskChangeRequest? pendingChange,
    HeritageTaskChangeRequest? rejectedChange,
  }) async {
    final viewModel = context.read<GamificationViewModel>();
    final isPendingNewTaskEdit =
        task.status.toUpperCase() == 'PENDING_APPROVAL';
    final isNewTaskResubmission = task.status.toUpperCase() == 'REJECTED';
    viewModel.clearArtisanTaskError();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _EditHeritageTaskSheet(
          task: task,
          pendingChange: pendingChange,
          rejectedChange: rejectedChange,
        ),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.lastTaskEditReverted
                ? 'Task update cancelled. The approved task was kept unchanged.'
                : isPendingNewTaskEdit
                ? 'Pending task submission updated successfully.'
                : isNewTaskResubmission
                ? 'Task updated and resubmitted for admin approval.'
                : pendingChange != null
                ? 'Pending task update revised successfully.'
                : rejectedChange != null
                ? 'Task update revised and resubmitted for admin approval.'
                : 'Task edit request submitted for admin approval.',
            style: const TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF00695C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTaskChanges(HeritageTask task, HeritageTaskChangeRequest change) {
    final isDelete = change.requestType.toUpperCase() == 'DELETE';
    _showChangesSheet(
      title: isDelete ? 'Task Deletion Request' : 'Task Update Request',
      current: [
        ('Title', task.title),
        ('Type', task.isRequired ? 'Required' : 'Optional'),
        ('XP reward', '${task.xpReward} XP'),
      ],
      requested: isDelete
          ? [('Requested action', 'Delete this task after admin approval')]
          : [
              ('Title', change.proposedTitle ?? task.title),
              (
                'Type',
                (change.proposedIsRequired ?? task.isRequired)
                    ? 'Required'
                    : 'Optional',
              ),
              ('XP reward', '${change.proposedXpReward ?? task.xpReward} XP'),
            ],
      actionLabel:
          !isDelete && change.status.toUpperCase() == 'PENDING_APPROVAL'
          ? 'Edit Pending Update'
          : null,
      onAction: !isDelete && change.status.toUpperCase() == 'PENDING_APPROVAL'
          ? () => _showEditTaskSheet(task, pendingChange: change)
          : null,
    );
  }

  void _showPendingTaskSubmission(HeritageTask task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D2825) : const Color(0xFFF7F5EF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: isDark
              ? const Border(top: BorderSide(color: Color(0xFF31524B)))
              : null,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Task Submission',
                style: GoogleFonts.dmSerifDisplay(
                  color: isDark ? const Color(0xFFFFF8E1) : _green,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This task will become active only after an admin approves it.',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFB8CCC6)
                      : const Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              _changeVersion(
                'SUBMITTED TASK',
                [
                  ('Title', task.title),
                  ('Type', task.isRequired ? 'Required' : 'Optional'),
                  ('XP reward', '${task.xpReward} XP'),
                ],
                pending: true,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFFFFD54F)
                            : _green,
                        side: BorderSide(
                          color: isDark ? const Color(0xFFFFD54F) : _green,
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _showEditTaskSheet(task);
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF008F78)
                            : _green,
                        foregroundColor: const Color(0xFFFFF8E1),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit Submission'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangesSheet({
    required String title,
    required List<(String, String)> current,
    required List<(String, String)> requested,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D2825) : const Color(0xFFF7F5EF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    color: isDark ? const Color(0xFFFFD54F) : _green,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The approved information remains active until an admin approves this request.',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                _changeVersion('CURRENT / APPROVED', current, isDark: isDark),
                const SizedBox(height: 14),
                _changeVersion(
                  'REQUESTED CHANGES',
                  requested,
                  pending: true,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (actionLabel != null && onAction != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) onAction();
                            });
                          },
                          child: Text(actionLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF008F78)
                              : _green,
                          foregroundColor: const Color(0xFFFFF8E1),
                        ),
                        child: const Text('Done'),
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

  Widget _changeVersion(
    String heading,
    List<(String, String)> values, {
    bool pending = false,
    bool isDark = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pending
            ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFFFFF8E6))
            : (isDark ? const Color(0xFF041412) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pending
              ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFFE4B64D))
              : (isDark ? const Color(0xFF1E3A34) : const Color(0xFFE1E5E2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              color: pending
                  ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFFB87800))
                  : (isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF64748B)),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < values.length; index++) ...[
            Text(
              values[index].$1,
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              values[index].$2,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF183B34),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (index != values.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
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
          content: Text(
            'Task deletion request submitted for admin approval.',
            style: TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Color(0xFF00695C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmTaskRequestRemoval({
    required String title,
    required bool rejected,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(
              rejected
                  ? 'This removes the rejected request from your list. It will not change the published task.'
                  : 'This request will be withdrawn from admin review. Published tasks and existing tourist progress will not be affected.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep Request'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                  foregroundColor: Colors.white,
                ),
                child: Text(rejected ? 'Remove Request' : 'Cancel Request'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showTaskRequestResult({
    required bool success,
    required String successMessage,
    required Future<void> Function() retry,
  }) {
    if (!mounted) return;
    final viewModel = context.read<GamificationViewModel>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? successMessage
              : viewModel.artisanTaskError ??
                    'The request could not be updated. Please retry.',
          style: const TextStyle(
            color: Color(0xFFFFF8E1),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: success
            ? const Color(0xFF00695C)
            : const Color(0xFFB42318),
        behavior: SnackBarBehavior.floating,
        action: success
            ? null
            : SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: retry,
              ),
      ),
    );
  }

  Future<void> _cancelPendingNewTask(HeritageTask task) async {
    final confirmed = await _confirmTaskRequestRemoval(
      title: 'Cancel New Task Submission?',
      rejected: false,
    );
    if (!confirmed || !mounted) return;
    final success = await context
        .read<GamificationViewModel>()
        .cancelNewTaskSubmission(task);
    _showTaskRequestResult(
      success: success,
      successMessage: 'New task submission withdrawn from admin review.',
      retry: () => _cancelPendingNewTask(task),
    );
  }

  Future<void> _removeRejectedNewTask(HeritageTask task) async {
    final confirmed = await _confirmTaskRequestRemoval(
      title: 'Remove Rejected Request?',
      rejected: true,
    );
    if (!confirmed || !mounted) return;
    final success = await context
        .read<GamificationViewModel>()
        .cancelNewTaskSubmission(task);
    _showTaskRequestResult(
      success: success,
      successMessage: 'Rejected new-task request removed.',
      retry: () => _removeRejectedNewTask(task),
    );
  }

  Future<void> _cancelPendingTaskChange(
    HeritageTask task,
    HeritageTaskChangeRequest request,
  ) async {
    final isDelete = request.requestType.toUpperCase() == 'DELETE';
    final confirmed = await _confirmTaskRequestRemoval(
      title: isDelete
          ? 'Cancel Task Deletion Request?'
          : 'Cancel Task Edit Request?',
      rejected: false,
    );
    if (!confirmed || !mounted) return;
    final success = await context
        .read<GamificationViewModel>()
        .cancelPendingTaskChange(task, request);
    _showTaskRequestResult(
      success: success,
      successMessage: isDelete
          ? 'Task deletion request cancelled. The task remains active.'
          : 'Task edit request cancelled. The published task is unchanged.',
      retry: () => _cancelPendingTaskChange(task, request),
    );
  }

  Future<void> _dismissRejectedTaskChange(
    HeritageTask task,
    HeritageTaskChangeRequest request,
  ) async {
    final confirmed = await _confirmTaskRequestRemoval(
      title: 'Remove Rejected Request?',
      rejected: true,
    );
    if (!confirmed || !mounted) return;
    final success = await context
        .read<GamificationViewModel>()
        .dismissRejectedTaskChange(task, request);
    _showTaskRequestResult(
      success: success,
      successMessage: request.requestType.toUpperCase() == 'DELETE'
          ? 'Rejected deletion request dismissed. The task remains active.'
          : 'Rejected edit request dismissed. The published task is unchanged.',
      retry: () => _dismissRejectedTaskChange(task, request),
    );
  }

  void _showWorkshopQr(Quest quest) {
    final secret = quest.qrCodeSecret;
    if (secret == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This workshop QR has not been configured yet.',
            style: TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Color(0xFFB42318),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final payload = 'WK_ARTISAN:${quest.artisanId}:$secret';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: isDark
              ? const BorderSide(color: Color(0xFF1E3A34))
              : BorderSide.none,
        ),
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
                    color: isDark ? const Color(0xFFFFD54F) : _green,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFFFFD54F) : _green,
                      width: 2,
                    ),
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
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFFFFD54F)
                          : _green,
                      foregroundColor: isDark
                          ? const Color(0xFF041412)
                          : Colors.white,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewModel = context.watch<GamificationViewModel>();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF041412)
          : const Color(0xFFF7F5EF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isLoadingArtisanQuest || viewModel.isAddingTask
            ? null
            : _handleAddTaskTap,
        backgroundColor: isDark ? const Color(0xFFFFD54F) : _green,
        foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
        disabledElevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF041412) : Colors.white,
        foregroundColor: isDark ? const Color(0xFFFFD54F) : _green,
        elevation: 0,
        title: Text(
          'Task Management',
          style: GoogleFonts.dmSerifDisplay(
            color: isDark ? const Color(0xFFFFD54F) : _green,
            fontSize: 22,
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF041412) : const Color(0xFFF7F5EF),
          image: DecorationImage(
            image: const AssetImage(
              'assets/images/heritage_passport_background.png',
            ),
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeatY,
            opacity: isDark ? 0.28 : 0.55,
            colorFilter: isDark
                ? const ColorFilter.mode(Color(0xFF2A6A5C), BlendMode.modulate)
                : null,
          ),
        ),
        child: RefreshIndicator(
          color: isDark ? const Color(0xFFFFD54F) : _green,
          onRefresh: viewModel.loadArtisanQuestAndTasks,
          child: _body(viewModel, isDark),
        ),
      ),
    );
  }

  Widget _body(GamificationViewModel viewModel, bool isDark) {
    if (viewModel.isLoadingArtisanQuest) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 240),
          Center(
            child: CircularProgressIndicator(
              color: isDark ? const Color(0xFFFFD54F) : _green,
            ),
          ),
        ],
      );
    }

    if (viewModel.artisanTaskError != null && viewModel.artisanQuest == null) {
      return _stateView(
        isDark: isDark,
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
        isDark: isDark,
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
          'QUEST REWARD',
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? const Color(0xFFFFD54F) : _green,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _questRewardCard(quest),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'TASKS',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? const Color(0xFFFFD54F) : _green,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            Text(
              '${viewModel.artisanTasks.length}',
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'Potential XP',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
            Text(
              '${viewModel.artisanTotalPotentialXp} XP',
              style: TextStyle(
                color: isDark ? const Color(0xFFFFD54F) : _green,
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
          _emptyTasks(isDark)
        else
          for (var index = 0; index < viewModel.artisanTasks.length; index++)
            _taskCard(index, viewModel.artisanTasks[index], isDark),
        const SizedBox(height: 72),
      ],
    );
  }

  Widget _questRewardCard(Quest quest) {
    final hasStampImage = quest.stampImageUrl.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 58,
                  child: hasStampImage
                      ? Image.network(
                          quest.stampImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildStampFallback(),
                        )
                      : _buildStampFallback(),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.stampTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSerifDisplay(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Workshop passport stamp',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFD6E7E2),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showWorkshopQr(quest),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('View Workshop QR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD166),
                side: const BorderSide(color: Color(0xFFFFD166)),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampFallback() {
    return const ColoredBox(
      color: Color(0xFF0B7062),
      child: Icon(
        Icons.workspace_premium_rounded,
        color: Color(0xFFFFD166),
        size: 30,
      ),
    );
  }

  Widget _taskCard(int index, HeritageTask task, bool isDark) {
    final viewModel = context.read<GamificationViewModel>();
    final pendingChange = viewModel.pendingChangeForTask(task.id);
    final hasPendingEdit = pendingChange?.requestType.toUpperCase() == 'EDIT';
    final hasPendingDelete =
        pendingChange?.requestType.toUpperCase() == 'DELETE';
    final rejectedEdit = viewModel.rejectedEditForTask(task.id);
    final rejectedDelete = viewModel.rejectedDeleteForTask(task.id);
    final isPendingSubmission = task.status.toUpperCase() == 'PENDING_APPROVAL';
    final isRejectedSubmission = task.status.toUpperCase() == 'REJECTED';
    final isTaskActionBusy =
        viewModel.isUpdatingNewTask ||
        viewModel.isSubmittingTaskChange ||
        viewModel.isCancellingTaskRequest;
    final displayStatus = task.isArchived
        ? 'ARCHIVED'
        : hasPendingDelete
        ? 'DELETE PENDING'
        : hasPendingEdit
        ? 'EDIT PENDING'
        : isPendingSubmission
        ? 'PENDING'
        : isRejectedSubmission || rejectedEdit != null
        ? 'REJECTED'
        : task.status.replaceAll('_', ' ').toUpperCase();
    final statusColor = switch (displayStatus) {
      'APPROVED' => isDark ? const Color(0xFF6EE7B7) : const Color(0xFF087F5B),
      'REJECTED' => isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB42318),
      'DELETE PENDING' =>
        isDark ? const Color(0xFFFDBA74) : const Color(0xFF9F5C5C),
      'ARCHIVED' => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
      _ => isDark ? const Color(0xFFFFD54F) : const Color(0xFF9A6700),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  statusColor.withValues(alpha: 0.10),
                  const Color(0xFF12332D),
                  const Color(0xFF0D2825),
                ]
              : [
                  Color.alphaBlend(
                    statusColor.withValues(alpha: 0.12),
                    Colors.white,
                  ),
                  const Color(0xFFFFFBF2),
                  Colors.white,
                ],
          stops: isDark ? const [0, 0.42, 1] : const [0, 0.46, 1],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? statusColor.withValues(alpha: 0.34)
              : Color.alphaBlend(
                  statusColor.withValues(alpha: 0.18),
                  const Color(0xFFE3E6E2),
                ),
          width: isDark ? 1.2 : 1,
        ),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${index + 1}'.padLeft(2, '0'),
                style: TextStyle(
                  color: isDark ? const Color(0xFFFFD54F) : _gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: isDark
                      ? Border.all(color: statusColor.withValues(alpha: 0.24))
                      : null,
                ),
                child: Text(
                  displayStatus,
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
            style: TextStyle(
              color: isDark ? const Color(0xFFFFF8E1) : const Color(0xFF183B34),
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
                      ? (isDark
                            ? const Color(0xFF174B40)
                            : const Color(0xFFE0F2ED))
                      : (isDark
                            ? const Color(0xFF172A27)
                            : const Color(0xFFF1F3F2)),
                  borderRadius: BorderRadius.circular(999),
                  border: isDark
                      ? Border.all(
                          color: task.isRequired
                              ? const Color(0xFF2A6B5D)
                              : const Color(0xFF36554D),
                        )
                      : null,
                ),
                child: Text(
                  task.isRequired ? 'REQUIRED' : 'OPTIONAL',
                  style: TextStyle(
                    color: task.isRequired
                        ? (isDark ? const Color(0xFF34D399) : _green)
                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '+${task.xpReward} XP',
                style: TextStyle(
                  color: isDark ? const Color(0xFFFFD54F) : _gold,
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
            Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 15,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'SYSTEM TASK · EDITING LOCKED',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          else if (isPendingSubmission)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: isTaskActionBusy
                      ? null
                      : () => _showPendingTaskSubmission(task),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🕒 Task pending admin review',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF9A6700),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View submission ›',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFFFD54F) : _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: isTaskActionBusy
                        ? null
                        : () => _cancelPendingNewTask(task),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text('Cancel Request'),
                  ),
                ),
              ],
            )
          else if (pendingChange != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showTaskChanges(task, pendingChange),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPendingDelete
                              ? '🕒 Deletion pending admin review'
                              : '🕒 Update pending admin review',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF9A6700),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasPendingDelete
                              ? 'View deletion request ›'
                              : 'View changes ›',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF6EE7B7) : _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 6,
                    children: [
                      if (hasPendingEdit)
                        TextButton.icon(
                          onPressed: isTaskActionBusy
                              ? null
                              : () => _showEditTaskSheet(
                                  task,
                                  pendingChange: pendingChange,
                                ),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Edit'),
                        ),
                      TextButton.icon(
                        onPressed: isTaskActionBusy
                            ? null
                            : () =>
                                  _cancelPendingTaskChange(task, pendingChange),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 17),
                        label: const Text('Cancel Request'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else if (rejectedEdit != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task update rejected',
                    style: TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (rejectedEdit.rejectionReason != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Reason: ${rejectedEdit.rejectionReason}',
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: isTaskActionBusy
                            ? null
                            : () => _dismissRejectedTaskChange(
                                task,
                                rejectedEdit,
                              ),
                        child: const Text('Dismiss Request'),
                      ),
                      FilledButton.icon(
                        onPressed: isTaskActionBusy
                            ? null
                            : () => _showEditTaskSheet(
                                task,
                                rejectedChange: rejectedEdit,
                              ),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFFFFD54F)
                              : _green,
                          foregroundColor: isDark
                              ? const Color(0xFF041412)
                              : Colors.white,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit & Resubmit'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (rejectedDelete != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task deletion request rejected',
                    style: TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (rejectedDelete.rejectionReason != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Reason: ${rejectedDelete.rejectionReason}',
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: isTaskActionBusy
                        ? null
                        : () =>
                              _dismissRejectedTaskChange(task, rejectedDelete),
                    child: const Text('Dismiss Request'),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: isTaskActionBusy
                      ? null
                      : () => _showEditTaskSheet(task),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFFFFD54F) : _green,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: Text(
                    isRejectedSubmission ? 'Edit & Resubmit' : 'Edit',
                  ),
                ),
                TextButton.icon(
                  onPressed: isTaskActionBusy
                      ? null
                      : () => isRejectedSubmission
                            ? _removeRejectedNewTask(task)
                            : _requestTaskDeletion(task),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: Text(
                    isRejectedSubmission ? 'Remove Request' : 'Delete',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _emptyTasks(bool isDark) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D2825) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE3E6E2),
      ),
    ),
    child: Column(
      children: [
        const Icon(Icons.playlist_add_rounded, color: _gold, size: 38),
        const SizedBox(height: 10),
        Text(
          'No tasks yet.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
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
    required bool isDark,
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
        style: GoogleFonts.dmSerifDisplay(
          color: isDark ? const Color(0xFFFFD54F) : _green,
          fontSize: 24,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
          height: 1.5,
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B211D) : const Color(0xFFF7F5EF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
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
                    color: isDark ? const Color(0xFFFFF8E1) : _green,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The task will be saved as pending and sent for admin approval.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB8CCC6)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressProtectionNotice(isDark: isDark),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF12201D),
                  ),
                  cursorColor: isDark ? const Color(0xFFFFD54F) : _green,
                  decoration: _decoration('Task title', isDark),
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                      _unsupportedControlCharacters,
                    ),
                    LengthLimitingTextInputFormatter(
                      GamificationViewModel.maxTaskTitleLength,
                    ),
                  ],
                  validator: (value) => _boundedRequiredText(
                    value,
                    label: 'Task title',
                    maxLength: GamificationViewModel.maxTaskTitleLength,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Task type',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFE6F1ED)
                        : const Color(0xFF12201D),
                    fontWeight: FontWeight.w700,
                  ),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF12201D),
                  ),
                  cursorColor: isDark ? const Color(0xFFFFD54F) : _green,
                  decoration: _decoration('XP reward', isDark),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _taskXpError,
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFFFFD54F)
                              : _green,
                          side: BorderSide(
                            color: isDark ? const Color(0xFFFFD54F) : _green,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: viewModel.isAddingTask ? null : _add,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF008F78)
                              : _green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? const Color(0xFF31524B)
                              : null,
                          disabledForegroundColor: isDark
                              ? Colors.white60
                              : null,
                        ),
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

  InputDecoration _decoration(String label, bool isDark) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: isDark ? const Color(0xFFB8CCC6) : const Color(0xFF64748B),
    ),
    filled: true,
    fillColor: isDark ? const Color(0xFF12332D) : Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF52756D) : const Color(0xFFB7C5C1),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFFFFD54F) : _green,
        width: 1.5,
      ),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _EditHeritageTaskSheet extends StatefulWidget {
  final HeritageTask task;
  final HeritageTaskChangeRequest? pendingChange;
  final HeritageTaskChangeRequest? rejectedChange;

  const _EditHeritageTaskSheet({
    required this.task,
    this.pendingChange,
    this.rejectedChange,
  }) : assert(pendingChange == null || rejectedChange == null);

  @override
  State<_EditHeritageTaskSheet> createState() => _EditHeritageTaskSheetState();
}

class _EditHeritageTaskSheetState extends State<_EditHeritageTaskSheet> {
  static const _green = Color(0xFF005B4F);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _xp;
  late bool _required;

  bool get _isPendingNewTaskEdit =>
      widget.task.status.toUpperCase() == 'PENDING_APPROVAL';
  bool get _isRejectedNewTaskResubmission =>
      widget.task.status.toUpperCase() == 'REJECTED';
  bool get _isNewTaskSubmission =>
      _isPendingNewTaskEdit || _isRejectedNewTaskResubmission;
  bool get _isRejectedEditResubmission => widget.rejectedChange != null;
  bool get _isPendingEdit => widget.pendingChange != null;
  bool get _isResubmission =>
      _isRejectedNewTaskResubmission || _isRejectedEditResubmission;

  @override
  void initState() {
    super.initState();
    final proposedChange = widget.pendingChange ?? widget.rejectedChange;
    _title = TextEditingController(
      text: proposedChange?.proposedTitle ?? widget.task.title,
    );
    _xp = TextEditingController(
      text: (proposedChange?.proposedXpReward ?? widget.task.xpReward)
          .toString(),
    );
    _required = proposedChange?.proposedIsRequired ?? widget.task.isRequired;
  }

  @override
  void dispose() {
    _title.dispose();
    _xp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final viewModel = context.read<GamificationViewModel>();
    final xpReward = int.parse(_xp.text.trim());
    final success = _isNewTaskSubmission
        ? await viewModel.updateNewTaskSubmission(
            task: widget.task,
            title: _title.text,
            isRequired: _required,
            xpReward: xpReward,
          )
        : _isRejectedEditResubmission
        ? await viewModel.resubmitRejectedTaskEdit(
            task: widget.task,
            request: widget.rejectedChange!,
            title: _title.text,
            isRequired: _required,
            xpReward: xpReward,
          )
        : _isPendingEdit
        ? await viewModel.updatePendingTaskEdit(
            task: widget.task,
            request: widget.pendingChange!,
            title: _title.text,
            isRequired: _required,
            xpReward: xpReward,
          )
        : await viewModel.requestHeritageTaskEdit(
            task: widget.task,
            title: _title.text,
            isRequired: _required,
            xpReward: xpReward,
          );
    if (mounted && success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GamificationViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy = _isNewTaskSubmission
        ? viewModel.isUpdatingNewTask
        : viewModel.isSubmittingTaskChange;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B211D) : const Color(0xFFF7F5EF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
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
                  _isPendingNewTaskEdit
                      ? 'Edit Pending Task Submission'
                      : _isPendingEdit
                      ? 'Edit Pending Task Update'
                      : _isResubmission
                      ? 'Edit & Resubmit Task'
                      : 'Request Task Edit',
                  style: GoogleFonts.dmSerifDisplay(
                    color: isDark ? const Color(0xFFFFF8E1) : _green,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isPendingNewTaskEdit
                      ? 'Update this new task while it is awaiting admin review.'
                      : _isPendingEdit
                      ? 'Revise the pending request. The approved task remains unchanged during admin review.'
                      : _isResubmission
                      ? _isRejectedNewTaskResubmission
                            ? 'Update the rejected new task and submit it for admin review again.'
                            : 'Revise the rejected update and submit it for admin review again. The approved task stays unchanged.'
                      : 'The existing task remains unchanged until an admin approves this request.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB8CCC6)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressProtectionNotice(isDark: isDark),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF12201D),
                  ),
                  cursorColor: isDark ? const Color(0xFFFFD54F) : _green,
                  decoration: _decoration('Task title', isDark),
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                      _unsupportedControlCharacters,
                    ),
                    LengthLimitingTextInputFormatter(
                      GamificationViewModel.maxTaskTitleLength,
                    ),
                  ],
                  validator: (value) => _boundedRequiredText(
                    value,
                    label: 'Task title',
                    maxLength: GamificationViewModel.maxTaskTitleLength,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Task type',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFE6F1ED)
                        : const Color(0xFF12201D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Required')),
                    ButtonSegment(value: false, label: Text('Optional')),
                  ],
                  selected: {_required},
                  onSelectionChanged: isBusy
                      ? null
                      : (selection) =>
                            setState(() => _required = selection.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _xp,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF12201D),
                  ),
                  cursorColor: isDark ? const Color(0xFFFFD54F) : _green,
                  decoration: _decoration('XP reward', isDark),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _taskXpError,
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
                        onPressed: isBusy
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFFFFD54F)
                              : _green,
                          side: BorderSide(
                            color: isDark ? const Color(0xFFFFD54F) : _green,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isBusy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF008F78)
                              : _green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? const Color(0xFF31524B)
                              : null,
                          disabledForegroundColor: isDark
                              ? Colors.white60
                              : null,
                        ),
                        child: isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isPendingNewTaskEdit
                                    ? 'Update Submission'
                                    : _isPendingEdit
                                    ? 'Update Request'
                                    : _isResubmission
                                    ? 'Resubmit Task'
                                    : 'Submit Request',
                              ),
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

  InputDecoration _decoration(String label, bool isDark) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: isDark ? const Color(0xFFB8CCC6) : const Color(0xFF64748B),
    ),
    filled: true,
    fillColor: isDark ? const Color(0xFF12332D) : Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF52756D) : const Color(0xFFB7C5C1),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFFFFD54F) : _green,
        width: 1.5,
      ),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
