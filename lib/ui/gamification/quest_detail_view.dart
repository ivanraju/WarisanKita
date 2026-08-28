import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/viewmodels/map_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';
import 'package:warisan_kita/ui/gamification/qr_scanner_view.dart';

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
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _lastReportedInside = null;
      unawaited(_viewModel.pauseDwellTrackingForInterruption());
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
    final inside = distance <= quest.geofenceRadiusMeters;
    _lastReportedInside = inside;
    await _viewModel.handleQuestProximityChanged(inside);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_viewModel.pauseDwellTrackingForInterruption());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamificationVM = context.watch<GamificationViewModel>();
    final mapViewModel = context.watch<MapViewModel>();
    final tasks = gamificationVM.heritageTasks;
    final distance = mapViewModel.getDistanceToWorkshop(workshop);
    _reportProximityAfterBuild(gamificationVM, distance);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cultural Quest'),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _buildQuestHeader(),
          const SizedBox(height: 20),
          _buildLocationSection(distance),
          const SizedBox(height: 20),
          _buildActivitiesSection(tasks, gamificationVM),
          const SizedBox(height: 20),
          _buildXpSummary(gamificationVM.totalPotentialXp),
          const SizedBox(height: 20),
          _buildStampPreview(),
        ],
      ),
      bottomNavigationBar: _buildStartBar(context, gamificationVM, distance),
    );
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(viewModel.handleQuestProximityChanged(inside));
    });
  }

  Widget _buildQuestHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CULTURAL QUEST',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFFFD54F),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            quest.title,
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.white,
              fontSize: 30,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            workshop.name,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quest.category,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            quest.description,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(double? distance) {
    final isWithinRange =
        distance != null && distance <= quest.geofenceRadiusMeters;
    return _buildSectionCard(
      title: 'Quest Location',
      icon: Icons.location_on_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workshop.name,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            workshop.locationName,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFFD97706),
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Quest can be started within '
                    '${quest.geofenceRadiusMeters} m of this artisan studio.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF92400E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            distance == null
                ? 'Current location is required before starting this quest.'
                : isWithinRange
                ? 'You are ${distance.toStringAsFixed(0)} m away and can start this quest.'
                : 'You are ${distance.toStringAsFixed(0)} m away. Move within ${quest.geofenceRadiusMeters} m to start.',
            style: GoogleFonts.plusJakartaSans(
              color: isWithinRange
                  ? const Color(0xFF087F5B)
                  : const Color(0xFFB45309),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(
    List<HeritageTask> tasks,
    GamificationViewModel viewModel,
  ) {
    return _buildSectionCard(
      title: 'Heritage Activities',
      icon: Icons.auto_awesome_rounded,
      child: tasks.isEmpty
          ? Text(
              'No heritage activities have been published for this quest.',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < tasks.length; index++) ...[
                  _buildTaskRow(index + 1, tasks[index], viewModel),
                  if (index != tasks.length - 1)
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                ],
              ],
            ),
    );
  }

  Widget _buildTaskRow(
    int number,
    HeritageTask task,
    GamificationViewModel viewModel,
  ) {
    final badgeColor = task.isRequired
        ? const Color(0xFF004D40)
        : const Color(0xFF64748B);
    final isCompleted = viewModel.isTaskCompleted(task);
    final isDwellTask = viewModel.isStayFifteenMinutesTask(task);

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
                  color: const Color(0xFF1E293B),
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
                      task.isRequired ? 'REQUIRED' : 'OPTIONAL',
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
                      color: const Color(0xFFD97706),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (isCompleted)
                    _buildTaskStatusBadge('COMPLETED', const Color(0xFF087F5B)),
                ],
              ),
              if (isDwellTask &&
                  !isCompleted &&
                  viewModel.questProgressStatus?.toUpperCase() ==
                      'IN_PROGRESS') ...[
                const SizedBox(height: 10),
                Text(
                  '${_formatDuration(viewModel.displayedDwellSeconds)} / 15:00',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF004D40),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.displayedDwellSeconds >=
                          GamificationViewModel.dwellRequiredSeconds
                      ? '15 minutes complete • Scan the workshop QR to verify'
                      : viewModel.isInsideQuestGeofence
                      ? viewModel.isDwellTracking
                            ? 'Inside quest area • Timer running'
                            : viewModel.canResumeDwellTracking
                            ? 'Inside quest area • Tap Resume Quest to continue'
                            : 'Inside quest area • Timer paused'
                      : 'Outside quest area • Timer paused',
                  style: GoogleFonts.plusJakartaSans(
                    color: viewModel.isInsideQuestGeofence
                        ? const Color(0xFF087F5B)
                        : const Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (!isCompleted) ...[
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
                      foregroundColor: const Color(0xFF005B4F),
                      side: const BorderSide(color: Color(0xFF005B4F)),
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
        color: color.withValues(alpha: 0.1),
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
  }

  Widget _buildXpSummary(int totalXp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Potential Task XP',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '$totalXp XP',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFFFD54F),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampPreview() {
    return _buildSectionCard(
      title: 'Quest Reward Preview',
      icon: Icons.workspace_premium_rounded,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 78,
              height: 78,
              child: quest.stampImageUrl.isEmpty
                  ? _buildStampFallback()
                  : Image.network(
                      quest.stampImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildStampFallback(),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.stampTitle,
                  style: GoogleFonts.dmSerifDisplay(
                    color: const Color(0xFF004D40),
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Preview only — this stamp has not been earned.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
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
    double? distance,
  ) {
    final status = viewModel.questProgressStatus?.toUpperCase();
    final isCompleted =
        status == 'COMPLETED' || viewModel.areAllHeritageTasksCompleted;
    final isInProgress = status == 'IN_PROGRESS';
    final isOutOfRange =
        isInProgress &&
        !isCompleted &&
        distance != null &&
        distance > quest.geofenceRadiusMeters;
    final canResume = viewModel.canResumeDwellTracking;
    final canStart =
        viewModel.heritageTasks.isNotEmpty &&
        !isCompleted &&
        !isInProgress &&
        !viewModel.isStartingQuest;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (viewModel.startQuestError != null) ...[
              Text(
                viewModel.startQuestError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFB42318),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canResume
                    ? () => _resumeQuest(context, viewModel)
                    : canStart
                    ? () => _startQuest(context, viewModel, distance)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: canResume
                      ? const Color(0xFF087F5B)
                      : const Color(0xFF004D40),
                  disabledBackgroundColor: isOutOfRange
                      ? const Color(0xFFB45309)
                      : isCompleted || isInProgress
                      ? const Color(0xFF087F5B)
                      : const Color(0xFFCBD5E1),
                  disabledForegroundColor: Colors.white,
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
                    : Icon(
                        isCompleted
                            ? Icons.workspace_premium_rounded
                            : isOutOfRange
                            ? Icons.location_off_rounded
                            : canResume
                            ? Icons.play_arrow_rounded
                            : isInProgress
                            ? Icons.directions_walk_rounded
                            : Icons.play_arrow_rounded,
                      ),
                label: Text(
                  viewModel.isStartingQuest
                      ? 'Starting Quest...'
                      : isCompleted
                      ? 'Quest Completed'
                      : isOutOfRange
                      ? 'Out of Range'
                      : canResume
                      ? 'Resume Quest'
                      : isInProgress
                      ? 'Quest In Progress'
                      : 'Start Quest',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resumeQuest(
    BuildContext context,
    GamificationViewModel viewModel,
  ) async {
    final resumed = await viewModel.resumeSelectedQuest();
    if (!context.mounted || !resumed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quest resumed. The workshop timer is running.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF005B4F),
      ),
    );
  }

  Future<void> _startQuest(
    BuildContext context,
    GamificationViewModel viewModel,
    double? currentDistance,
  ) async {
    var distance = currentDistance;
    final mapViewModel = context.read<MapViewModel>();
    if (distance == null) {
      await mapViewModel.startLocationTracking();
      if (!context.mounted) return;
      distance = mapViewModel.getDistanceToWorkshop(workshop);
    }

    if (distance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current location is unavailable. Enable location access and try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (distance > quest.geofenceRadiusMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Move within ${quest.geofenceRadiusMeters} m of the workshop to start this quest.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB42318),
        ),
      );
      return;
    }

    viewModel.clearStartQuestError();
    final started = await viewModel.startSelectedQuest();
    if (!context.mounted) return;
    if (started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quest started. Your progress has been saved.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF005B4F),
        ),
      );
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              Icon(icon, color: const Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF004D40),
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
