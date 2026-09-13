import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/data/repositories/artisan_repository.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/viewmodels/map_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/ui/gamification/active_quest_conflict_dialog.dart';
import 'package:warisan_kita/ui/gamification/qr_scanner_view.dart';
import 'package:warisan_kita/ui/gamification/workshop_quest_navigation.dart';

class QuestDetailView extends StatefulWidget {
  final Quest quest;
  final WorkshopLocation workshop;

  const QuestDetailView({
    super.key,
    required this.quest,
    required this.workshop,
  });

  @override
  State<QuestDetailView> createState() => _QuestDetailViewState();
}

class _QuestDetailViewState extends State<QuestDetailView>
    with WidgetsBindingObserver {
  Quest get quest => widget.quest;
  WorkshopLocation get workshop => widget.workshop;

  late GamificationViewModel _viewModel;
  bool? _lastReportedInside;
  String? _lastReportedStatus;
  bool _isShowingCompletionDialog = false;
  bool _workshopClosedDialogScheduled = false;
  bool _hasShownWorkshopClosedDialog = false;
  bool _isShowingWorkshopClosedDialog = false;
  bool _workshopClosureStopScheduled = false;
  bool _hasStoppedForWorkshopClosure = false;
  Timer? _exitConfirmationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_resumeTracking());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<GamificationViewModel>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeTracking());
    }
  }

  Future<void> _resumeTracking() async {
    final mapViewModel = context.read<MapViewModel>();
    if (mapViewModel.userLocation == null) {
      await mapViewModel.startLocationTracking();
    } else if (!await mapViewModel.refreshCurrentLocation()) {
      return;
    }
    if (!mounted) return;
    final distance = mapViewModel.getDistanceToWorkshop(workshop);
    if (distance == null) return;
    _reportProximityAfterBuild(_viewModel, distance);
  }

  @override
  void dispose() {
    _exitConfirmationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamificationVM = context.watch<GamificationViewModel>();
    final mapViewModel = context.watch<MapViewModel>();
    final tasks = gamificationVM.heritageTasks;
    final distance = mapViewModel.getDistanceToWorkshop(workshop);
    final isWorkshopOpen = _isWorkshopCurrentlyOpen(mapViewModel);
    _reportProximityAfterBuild(gamificationVM, distance);
    _scheduleQuestCompletionDialog(gamificationVM);
    _scheduleWorkshopClosedDialog(isWorkshopOpen);
    _stopActiveQuestForWorkshopClosure(isWorkshopOpen, gamificationVM);

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Cultural Quest',
          style: GoogleFonts.dmSerifDisplay(fontSize: 23),
        ),
        backgroundColor: _isDark
            ? const Color(0xFF071613)
            : const Color(0xFFF7F2E8),
        foregroundColor: _isDark
            ? const Color(0xFFFFF8E1)
            : const Color(0xFF004D40),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: _pageBackground,
          image: DecorationImage(
            image: ResizeImage(
              AssetImage(
                _isDark
                    ? 'assets/images/heritage_batik_background.png'
                    : 'assets/images/cultural_quest_journey_background.png',
              ),
              width: 768,
            ),
            fit: _isDark ? BoxFit.fitWidth : BoxFit.fill,
            alignment: Alignment.center,
            repeat: _isDark ? ImageRepeat.repeatY : ImageRepeat.noRepeat,
            opacity: _isDark ? 0.035 : 0.82,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
          children: [
            _buildQuestHeader(gamificationVM),
            const SizedBox(height: 16),
            _buildLocationSection(distance),
            const SizedBox(height: 16),
            _buildActivitiesSection(tasks, gamificationVM),
            const SizedBox(height: 16),
            _buildStampPreview(gamificationVM),
          ],
        ),
      ),
      bottomNavigationBar: _buildStartBar(
        context,
        gamificationVM,
        distance,
        isWorkshopOpen: isWorkshopOpen,
      ),
    );
  }

  bool _isWorkshopCurrentlyOpen(MapViewModel mapViewModel) {
    for (final candidate in mapViewModel.workshops) {
      if (candidate.id == workshop.id) return candidate.isLiveOpen;
    }
    return workshop.isLiveOpen;
  }

  void _scheduleWorkshopClosedDialog(bool isWorkshopOpen) {
    if (isWorkshopOpen ||
        _hasShownWorkshopClosedDialog ||
        _workshopClosedDialogScheduled) {
      return;
    }

    _workshopClosedDialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _workshopClosedDialogScheduled = false;
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
      _hasShownWorkshopClosedDialog = true;
      await _showWorkshopClosedDialog();
    });
  }

  void _stopActiveQuestForWorkshopClosure(
    bool isWorkshopOpen,
    GamificationViewModel viewModel,
  ) {
    if (isWorkshopOpen) {
      _hasStoppedForWorkshopClosure = false;
      return;
    }
    if (_hasStoppedForWorkshopClosure ||
        _workshopClosureStopScheduled ||
        viewModel.questProgressStatus?.toUpperCase() != 'IN_PROGRESS') {
      return;
    }

    _workshopClosureStopScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _workshopClosureStopScheduled = false;
      if (!mounted ||
          _isWorkshopCurrentlyOpen(context.read<MapViewModel>()) ||
          viewModel.questProgressStatus?.toUpperCase() != 'IN_PROGRESS') {
        return;
      }

      _hasStoppedForWorkshopClosure = true;
      final stopped = await viewModel.stopSelectedQuest();
      if (!mounted || !stopped) return;

      await context.read<MapViewModel>().loadJourneyData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quest stopped because the workshop closed. Your progress was '
            'saved, and you can now start another workshop quest.',
            style: TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF00695C),
        ),
      );
    });
  }

  Future<void> _showWorkshopClosedDialog() async {
    if (!mounted || _isShowingWorkshopClosedDialog) return;
    _isShowingWorkshopClosedDialog = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _cardSurface,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: _cardBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Icon(Icons.storefront_rounded, color: _warningText, size: 34),
          title: Text(
            'Workshop Currently Closed',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              color: _primaryText,
              fontSize: 22,
            ),
          ),
          content: Text(
            'This workshop is not accepting educational walk-ins or live '
            'demonstrations right now. Any active quest here is stopped '
            'automatically with its progress saved, allowing you to start a '
            'quest at another open workshop.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: _secondaryText,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      _isShowingWorkshopClosedDialog = false;
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark ? const Color(0xFF071613) : const Color(0xFFF7F2E8);

  Color get _cardSurface =>
      _isDark ? const Color(0xFF102824) : const Color(0xFFFFFCF5);

  Color get _primaryText =>
      _isDark ? const Color(0xFFFFF8E1) : const Color(0xFF172B27);

  Color get _secondaryText =>
      _isDark ? const Color(0xFFB8C9C4) : const Color(0xFF64748B);

  Color get _cardBorder =>
      _isDark ? const Color(0xFF28483F) : const Color(0xFFE7DDCB);

  Color get _successText =>
      _isDark ? const Color(0xFF6EE7B7) : const Color(0xFF087F5B);

  Color get _warningText =>
      _isDark ? const Color(0xFFFFD98A) : const Color(0xFFB45309);

  Color get _xpText =>
      _isDark ? const Color(0xFFFFD166) : const Color(0xFFD97706);

  Color get _dangerText =>
      _isDark ? const Color(0xFFFF9B93) : const Color(0xFFB42318);

  void _reportProximityAfterBuild(
    GamificationViewModel viewModel,
    double? distance,
  ) {
    if (distance == null) return;
    final inside = distance <= quest.geofenceRadiusMeters;
    final status = viewModel.questProgressStatus?.toUpperCase();
    if (_lastReportedInside == inside && _lastReportedStatus == status) return;

    _lastReportedInside = inside;
    _lastReportedStatus = status;
    if (!inside && status == 'IN_PROGRESS') {
      _exitConfirmationTimer ??= Timer(const Duration(seconds: 3), () async {
        _exitConfirmationTimer = null;
        if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
        final latestDistance = context
            .read<MapViewModel>()
            .getDistanceToWorkshop(workshop);
        if (latestDistance != null &&
            latestDistance > quest.geofenceRadiusMeters) {
          await viewModel.handleQuestProximityChanged(false);
          if (!mounted || viewModel.questProgressStatus != 'STOPPED') return;
          unawaited(context.read<MapViewModel>().loadJourneyData());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Quest stopped because you left the workshop area. '
                'Your progress has been saved.',
                style: TextStyle(
                  color: Color(0xFFFFF8E1),
                  fontWeight: FontWeight.w600,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF00695C),
            ),
          );
        }
      });
      return;
    }
    _exitConfirmationTimer?.cancel();
    _exitConfirmationTimer = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(viewModel.handleQuestProximityChanged(inside));
    });
  }

  void _scheduleQuestCompletionDialog(GamificationViewModel viewModel) {
    if (!viewModel.hasPendingQuestCompletionCelebration ||
        _isShowingCompletionDialog ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          _isShowingCompletionDialog ||
          !(ModalRoute.of(context)?.isCurrent ?? false) ||
          !viewModel.consumeQuestCompletionCelebration()) {
        return;
      }
      _isShowingCompletionDialog = true;
      await _showQuestCompletionDialog();
      _isShowingCompletionDialog = false;
    });
  }

  Widget _buildQuestHeader(GamificationViewModel viewModel) {
    final requiredTasks = viewModel.effectiveRequiredHeritageTasks;
    final completedRequired = viewModel.completedEffectiveRequiredTaskCount;
    final isPermanentlyCompleted = viewModel.isQuestPermanentlyCompleted;
    final progress = requiredTasks.isEmpty
        ? (isPermanentlyCompleted ? 1.0 : 0.0)
        : (completedRequired / requiredTasks.length).clamp(0.0, 1.0);
    final requiredLabel =
        '$completedRequired / ${requiredTasks.length} Required';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workshop.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.white,
              fontSize: 25,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${viewModel.totalPotentialXp} Potential XP',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFFFD54F),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  requiredLabel,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Semantics(
            label: 'Required quest progress: $requiredLabel',
            value: '${(progress * 100).round()} percent',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                color: const Color(0xFFFFD54F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(double? distance) {
    final isWithinRange =
        distance != null && distance <= quest.geofenceRadiusMeters;
    final stateColor = distance == null
        ? _secondaryText
        : isWithinRange
        ? _successText
        : _warningText;
    final stateIcon = distance == null
        ? Icons.location_searching_rounded
        : isWithinRange
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;
    final stateLabel = distance == null
        ? 'Location required to confirm the quest zone'
        : isWithinRange
        ? 'Within quest zone'
        : 'Outside quest zone';

    return _buildSectionCard(
      title: 'Quest Location',
      icon: Icons.location_on_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, color: stateColor, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.name,
                      style: GoogleFonts.plusJakartaSans(
                        color: _primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      workshop.locationName,
                      style: GoogleFonts.plusJakartaSans(
                        color: _secondaryText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            'Quest starts within ${quest.geofenceRadiusMeters} m',
            style: GoogleFonts.plusJakartaSans(
              color: _primaryText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            distance == null
                ? 'Live distance unavailable'
                : 'You are ${distance.toStringAsFixed(0)} m away',
            style: GoogleFonts.plusJakartaSans(
              color: _secondaryText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(stateIcon, color: stateColor, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stateLabel,
                  style: GoogleFonts.plusJakartaSans(
                    color: stateColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(
    List<HeritageTask> tasks,
    GamificationViewModel viewModel,
  ) {
    final indexedTasks = tasks.indexed.toList(growable: false);
    final journeyTasks = indexedTasks
        .where((entry) => !viewModel.isBonusTask(entry.$2))
        .toList(growable: false);
    final bonusTasks = indexedTasks
        .where((entry) => viewModel.isBonusTask(entry.$2))
        .toList(growable: false);
    return _buildSectionCard(
      title: 'Heritage Quest',
      icon: Icons.auto_awesome_rounded,
      child: tasks.isEmpty
          ? Text(
              'No heritage activities have been published for this quest.',
              style: GoogleFonts.plusJakartaSans(
                color: _secondaryText,
                fontSize: 13,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < journeyTasks.length; index++) ...[
                  _buildTaskRow(
                    journeyTasks[index].$1 + 1,
                    journeyTasks[index].$2,
                    viewModel,
                  ),
                  if (index != journeyTasks.length - 1)
                    Divider(height: 24, color: _cardBorder),
                ],
                if (bonusTasks.isNotEmpty) ...[
                  if (journeyTasks.isNotEmpty)
                    Divider(height: 32, color: _cardBorder),
                  Text(
                    'BONUS ACTIVITIES',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFD97706),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Optional additions that do not change your original quest progress.',
                    style: GoogleFonts.plusJakartaSans(
                      color: _secondaryText,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var index = 0; index < bonusTasks.length; index++) ...[
                    _buildTaskRow(
                      bonusTasks[index].$1 + 1,
                      bonusTasks[index].$2,
                      viewModel,
                      isBonus: true,
                    ),
                    if (index != bonusTasks.length - 1)
                      Divider(height: 24, color: _cardBorder),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _buildTaskRow(
    int number,
    HeritageTask task,
    GamificationViewModel viewModel, {
    bool isBonus = false,
  }) {
    final badgeColor = isBonus
        ? const Color(0xFFD97706)
        : task.isRequired
        ? (_isDark ? const Color(0xFF6EE7B7) : const Color(0xFF004D40))
        : _secondaryText;
    final isCompleted = viewModel.isTaskCompleted(task);
    final isDwellTask = viewModel.isStayFifteenMinutesTask(task);
    final taskState = _taskDisplayState(
      task,
      viewModel,
      isCompleted: isCompleted,
      isBonus: isBonus,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFDDF5EC)
                : const Color(0xFFFFF3C4),
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Color(0xFF087F5B),
                )
              : Text(
                  '$number',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF92400E),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: GoogleFonts.plusJakartaSans(
                  color: _primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBonus
                          ? 'BONUS ACTIVITY'
                          : task.isRequired
                          ? 'REQUIRED'
                          : 'OPTIONAL',
                      style: GoogleFonts.plusJakartaSans(
                        color: badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    '+${task.xpReward} XP',
                    style: GoogleFonts.plusJakartaSans(
                      color: _xpText,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _buildTaskStatusBadge(taskState.$1, taskState.$2),
                ],
              ),
              if (isBonus) ...[
                const SizedBox(height: 6),
                Text(
                  'Added after you began this quest',
                  style: GoogleFonts.plusJakartaSans(
                    color: _isDark
                        ? const Color(0xFFFFD98A)
                        : const Color(0xFF92400E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (isDwellTask &&
                  !isCompleted &&
                  viewModel.questProgressStatus?.toUpperCase() ==
                      'IN_PROGRESS') ...[
                const SizedBox(height: 10),
                Text(
                  '${_formatDuration(viewModel.displayedDwellSeconds)} / 15:00',
                  style: GoogleFonts.plusJakartaSans(
                    color: _successText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.displayedDwellSeconds >=
                          GamificationViewModel.dwellRequiredSeconds
                      ? '15 minutes complete • Saving completion'
                      : viewModel.isInsideQuestGeofence
                      ? viewModel.isDwellTracking
                            ? 'Inside quest area • Timer running'
                            : viewModel.canResumeDwellTracking
                            ? 'Inside quest area • Tap Start Quest to continue'
                            : 'Inside quest area • Timer paused'
                      : 'Outside quest area • Timer paused',
                  style: GoogleFonts.plusJakartaSans(
                    color: viewModel.isInsideQuestGeofence
                        ? (_isDark
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFF087F5B))
                        : (_isDark
                              ? const Color(0xFFFFD98A)
                              : const Color(0xFFB45309)),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (!isCompleted && !task.isSystemTask) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: viewModel.canVerifyTaskWithQr(task)
                        ? () => _openTaskScanner(task)
                        : null,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 17),
                    label: Text(viewModel.qrVerificationLabel(task)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF005B4F),
                      disabledForegroundColor: _isDark
                          ? const Color(0xFF86EFAC).withValues(alpha: 0.75)
                          : const Color(0xFF64748B),
                      side: BorderSide(
                        color: viewModel.canVerifyTaskWithQr(task)
                            ? (_isDark
                                  ? const Color(0xFF3FAE91)
                                  : const Color(0xFF005B4F))
                            : (_isDark
                                  ? const Color(
                                      0xFF6EE7B7,
                                    ).withValues(alpha: 0.5)
                                  : const Color(0xFFCBD5E1)),
                        width: 1.2,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  (String, Color) _taskDisplayState(
    HeritageTask task,
    GamificationViewModel viewModel, {
    required bool isCompleted,
    required bool isBonus,
  }) {
    if (isCompleted) return ('COMPLETED', _successText);
    if (viewModel.requiresJourneyResume) {
      return ('PAUSED', _warningText);
    }
    if (isBonus) return ('BONUS', _xpText);

    final inProgress =
        viewModel.questProgressStatus?.toUpperCase() == 'IN_PROGRESS';
    if (!inProgress) return ('AVAILABLE', _successText);

    if (viewModel.isStayFifteenMinutesTask(task)) {
      if (!viewModel.isInsideQuestGeofence) {
        return ('WAITING FOR ARRIVAL', _warningText);
      }
      if (viewModel.isDwellTracking) {
        return ('IN PROGRESS', _successText);
      }
      return ('PAUSED', _warningText);
    }
    if (task.isSystemTask) {
      return ('WAITING FOR ARRIVAL', _warningText);
    }
    return ('QR REQUIRED', _successText);
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _openTaskScanner(HeritageTask task) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(quest: quest, task: task),
      ),
    );
    if (!mounted) return;
    _scheduleQuestCompletionDialog(context.read<GamificationViewModel>());
  }

  Future<void> _showQuestCompletionDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDark ? _cardSurface : null,
        surfaceTintColor: _isDark ? Colors.transparent : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: _isDark ? BorderSide(color: _cardBorder) : BorderSide.none,
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3C4),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 92,
                  child: Image.network(
                    quest.stampImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildStampFallback(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Congratulations!',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                color: _isDark
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFF004D40),
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You completed every required activity for this heritage quest.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: _isDark
                    ? const Color(0xFFB8C9C4)
                    : const Color(0xFF475569),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF153B35)
                    : const Color(0xFFE8F5F1),
                borderRadius: BorderRadius.circular(14),
                border: _isDark ? Border.all(color: _cardBorder) : null,
              ),
              child: Column(
                children: [
                  Text(
                    'BADGE AWARDED',
                    style: TextStyle(
                      color: _isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF087F5B),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.stampTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: _isDark
                          ? const Color(0xFFFFF8E1)
                          : const Color(0xFF004D40),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Close'),
                style: FilledButton.styleFrom(
                  backgroundColor: _isDark
                      ? const Color(0xFF087F5B)
                      : const Color(0xFF005B4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampPreview(GamificationViewModel viewModel) {
    final isEarned = viewModel.isQuestBadgeEarned;
    final stamp = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 78,
        height: 78,
        child: quest.stampImageUrl.trim().isEmpty
            ? _buildStampFallback()
            : Image.network(
                quest.stampImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildStampFallback(),
              ),
      ),
    );

    return _buildSectionCard(
      title: 'Quest Reward',
      icon: Icons.workspace_premium_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              isEarned
                  ? stamp
                  : Opacity(
                      opacity: 0.48,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.33,
                          0.33,
                          0.33,
                          0,
                          0,
                          0.33,
                          0.33,
                          0.33,
                          0,
                          0,
                          0.33,
                          0.33,
                          0.33,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: stamp,
                      ),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.stampTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSerifDisplay(
                        color: _primaryText,
                        fontSize: 19,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${workshop.name} passport stamp',
                      style: GoogleFonts.plusJakartaSans(
                        color: _secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Total Quest XP: ${viewModel.totalPotentialXp} XP',
            style: GoogleFonts.plusJakartaSans(
              color: _xpText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isEarned ? Icons.verified_rounded : Icons.lock_outline_rounded,
                color: isEarned ? _successText : _secondaryText,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  isEarned
                      ? 'UNLOCKED · ADDED TO PASSPORT'
                      : 'Complete all required activities to unlock',
                  style: GoogleFonts.plusJakartaSans(
                    color: isEarned ? _successText : _secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStampFallback() {
    return Container(
      color: const Color(0xFFFFF3C4),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: Color(0xFFD97706),
        size: 38,
      ),
    );
  }

  Widget _buildStartBar(
    BuildContext context,
    GamificationViewModel viewModel,
    double? distance, {
    required bool isWorkshopOpen,
  }) {
    final status = viewModel.questProgressStatus?.toUpperCase();
    final isCompleted =
        status == 'COMPLETED' || viewModel.areAllHeritageTasksCompleted;
    final isInProgress = status == 'IN_PROGRESS';
    final isBlockedByAnotherQuest =
        !isCompleted &&
        viewModel.hasActiveQuest &&
        !viewModel.isActiveQuest(quest.id);
    final isOutOfRange =
        isInProgress &&
        !isCompleted &&
        distance != null &&
        distance > quest.geofenceRadiusMeters;
    final isOutsideBeforeStart =
        !isInProgress &&
        !isCompleted &&
        distance != null &&
        distance > quest.geofenceRadiusMeters;
    final canResume = isWorkshopOpen && viewModel.canResumeDwellTracking;
    final canStart =
        isWorkshopOpen &&
        viewModel.heritageTasks.isNotEmpty &&
        !isCompleted &&
        !isInProgress &&
        !isBlockedByAnotherQuest &&
        !isOutsideBeforeStart &&
        !viewModel.isStartingQuest;
    final canStop =
        isWorkshopOpen &&
        isInProgress &&
        !isCompleted &&
        !isOutOfRange &&
        !viewModel.isStartingQuest &&
        !viewModel.isStoppingQuest;
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0B211D) : const Color(0xFFFFFCF5),
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isWorkshopOpen && !isCompleted) ...[
              Text(
                'This workshop is currently closed. Quest participation is '
                'unavailable, and any active progress is stopped and saved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: _warningText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (viewModel.startQuestError != null) ...[
              Text(
                viewModel.startQuestError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: _dangerText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isBlockedByAnotherQuest) ...[
              Text(
                viewModel.activeQuestConflictMessage(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: _isDark
                      ? const Color(0xFFFFD98A)
                      : const Color(0xFF92400E),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (viewModel.activeQuestWarning != null) ...[
              Text(
                viewModel.activeQuestWarning!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: _dangerText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: !isWorkshopOpen && !isCompleted
                    ? null
                    : isBlockedByAnotherQuest
                    ? () => _showActiveQuestConflict(context, viewModel)
                    : canResume
                    ? () => _resumeQuest(context, viewModel)
                    : canStop
                    ? () => _confirmStopQuest(context, viewModel)
                    : canStart
                    ? () => _startQuest(context, viewModel)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: canStop
                      ? (_isDark
                            ? const Color(0xFF991B1B)
                            : const Color(0xFFDC2626))
                      : canResume
                      ? const Color(0xFF087F5B)
                      : (_isDark
                            ? const Color(0xFF00695C)
                            : const Color(0xFF004D40)),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: viewModel.isStartingQuest
                      ? (_isDark
                            ? const Color(0xFF0F766E)
                            : const Color(0xFF004D40))
                      : viewModel.isStoppingQuest
                      ? (_isDark
                            ? const Color(0xFF991B1B)
                            : const Color(0xFFDC2626))
                      : !isWorkshopOpen && !canStop && !isCompleted
                      ? const Color(0xFF64748B)
                      : isOutOfRange || isOutsideBeforeStart
                      ? const Color(0xFFB45309)
                      : isCompleted || isInProgress
                      ? const Color(0xFF087F5B)
                      : const Color(0xFFCBD5E1),
                  disabledForegroundColor: const Color(0xFFFFF8E1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: viewModel.isStartingQuest
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : viewModel.isStoppingQuest
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isCompleted
                            ? Icons.workspace_premium_rounded
                            : !isWorkshopOpen
                            ? Icons.storefront_rounded
                            : canResume
                            ? Icons.play_arrow_rounded
                            : canStop
                            ? Icons.stop_circle_outlined
                            : isOutOfRange || isOutsideBeforeStart
                            ? Icons.location_off_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                label: Text(
                  viewModel.isStartingQuest
                      ? 'Starting Quest...'
                      : viewModel.isStoppingQuest
                      ? 'Stopping Quest...'
                      : isCompleted
                      ? 'Quest Completed'
                      : !isWorkshopOpen
                      ? 'Workshop Closed'
                      : isBlockedByAnotherQuest
                      ? 'Another Quest Active'
                      : canResume
                      ? 'Resume Quest'
                      : canStop
                      ? 'Stop Quest'
                      : isOutOfRange
                      ? 'Return to Quest Area'
                      : isOutsideBeforeStart
                      ? 'Move Within Quest Zone'
                      : isInProgress
                      ? 'Quest In Progress'
                      : 'Start Quest',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (canResume) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: viewModel.isStoppingQuest
                    ? null
                    : () => _confirmStopQuest(context, viewModel),
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Stop Quest'),
                style: TextButton.styleFrom(
                  foregroundColor: _isDark
                      ? const Color(0xFFF87171)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStopQuest(
    BuildContext context,
    GamificationViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Stop this quest?',
          style: GoogleFonts.dmSerifDisplay(
            color: _isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            fontSize: 20,
          ),
        ),
        content: Text(
          'Your completed activities, XP, and timer progress will be saved. '
          'You can start another workshop quest after stopping.',
          style: GoogleFonts.plusJakartaSans(
            color: _isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Keep Quest Active',
              style: TextStyle(
                color: _isDark ? Colors.white70 : const Color(0xFF004D40),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _isDark
                  ? const Color(0xFF991B1B)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop Quest'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final stopped = await viewModel.stopSelectedQuest();
    if (!context.mounted || !stopped) return;
    unawaited(context.read<MapViewModel>().loadJourneyData());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Quest stopped. Your progress has been saved.',
          style: TextStyle(
            color: Color(0xFFFFF8E1),
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF00695C),
      ),
    );
  }

  Future<void> _resumeQuest(
    BuildContext context,
    GamificationViewModel viewModel,
  ) async {
    if (!await _confirmWorkshopAvailable(context)) return;
    if (!context.mounted) return;
    final location = await context
        .read<MapViewModel>()
        .validateFreshQuestLocation(
          workshop: workshop,
          radiusMeters: quest.geofenceRadiusMeters.toDouble(),
        );
    if (!context.mounted) return;
    if (!location.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(location.message ?? 'Unable to verify your location.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB42318),
        ),
      );
      return;
    }
    final resumed = await viewModel.resumeSelectedQuest(
      verifiedLocation: location,
    );
    if (!context.mounted || !resumed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Quest started. The workshop timer is running.',
          style: TextStyle(
            color: Color(0xFFFFF8E1),
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF00695C),
      ),
    );
  }

  Future<void> _startQuest(
    BuildContext context,
    GamificationViewModel viewModel,
  ) async {
    if (!viewModel.canStartQuest(quest.id)) {
      await _showActiveQuestConflict(context, viewModel);
      return;
    }
    if (!await _confirmWorkshopAvailable(context)) return;
    if (!context.mounted) return;
    final mapViewModel = context.read<MapViewModel>();
    final location = await mapViewModel.validateFreshQuestLocation(
      workshop: workshop,
      radiusMeters: quest.geofenceRadiusMeters.toDouble(),
    );
    if (!context.mounted) return;
    if (!location.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(location.message ?? 'Unable to verify your location.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB42318),
        ),
      );
      return;
    }

    viewModel.clearStartQuestError();
    final started = await viewModel.startSelectedQuest(
      verifiedLocation: location,
    );
    if (!context.mounted) return;
    if (started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quest started. Your progress has been saved.',
            style: TextStyle(
              color: Color(0xFFFFF8E1),
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF00695C),
        ),
      );
    } else if (!viewModel.canStartQuest(quest.id)) {
      await _showActiveQuestConflict(context, viewModel);
    }
  }

  Future<bool> _confirmWorkshopAvailable(BuildContext context) async {
    try {
      final isOpen = await context
          .read<ArtisanRepository>()
          .getWorkshopLiveStatus(workshop.id);
      if (!context.mounted) return false;
      if (isOpen) return true;

      unawaited(context.read<MapViewModel>().loadWorkshops());
      _hasShownWorkshopClosedDialog = true;
      await _showWorkshopClosedDialog();
      return false;
    } catch (error) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to confirm workshop availability. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFB42318),
        ),
      );
      return false;
    }
  }

  Future<void> _showActiveQuestConflict(
    BuildContext context,
    GamificationViewModel viewModel,
  ) async {
    final active = viewModel.activeQuest;
    if (active == null) return;
    final shouldContinue = await showActiveQuestConflictDialog(
      context,
      activeQuest: active,
      integrityWarning: viewModel.activeQuestWarning,
    );
    if (!context.mounted || !shouldContinue) return;

    final mapViewModel = context.read<MapViewModel>();
    WorkshopLocation? activeWorkshop;
    for (final candidate in mapViewModel.workshops) {
      if (candidate.id == active.artisanId) {
        activeWorkshop = candidate;
        break;
      }
    }
    if (activeWorkshop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The active workshop could not be opened right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future<void>.delayed(Duration.zero);
    if (!navigator.mounted) return;
    await openWorkshopQuest(navigator.context, activeWorkshop);
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: _isDark
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: _isDark
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFF004D40),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
