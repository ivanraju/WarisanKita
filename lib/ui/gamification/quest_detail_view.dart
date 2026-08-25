import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/viewmodels/map_viewmodel.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

class QuestDetailView extends StatelessWidget {
  final Quest quest;
  final WorkshopLocation workshop;

  const QuestDetailView({
    super.key,
    required this.quest,
    required this.workshop,
  });

  @override
  Widget build(BuildContext context) {
    final gamificationVM = context.watch<GamificationViewModel>();
    final mapViewModel = context.watch<MapViewModel>();
    final tasks = gamificationVM.heritageTasks;
    final distance = mapViewModel.getDistanceToWorkshop(workshop);

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
          _buildActivitiesSection(tasks),
          const SizedBox(height: 20),
          _buildXpSummary(gamificationVM.totalPotentialXp),
          const SizedBox(height: 20),
          _buildStampPreview(),
        ],
      ),
      bottomNavigationBar: _buildStartBar(context, gamificationVM, distance),
    );
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

  Widget _buildActivitiesSection(List<HeritageTask> tasks) {
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
                  _buildTaskRow(index + 1, tasks[index]),
                  if (index != tasks.length - 1)
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                ],
              ],
            ),
    );
  }

  Widget _buildTaskRow(int number, HeritageTask task) {
    final badgeColor = task.isRequired
        ? const Color(0xFF004D40)
        : const Color(0xFF64748B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3C4),
            shape: BoxShape.circle,
          ),
          child: Text(
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
                ],
              ),
            ],
          ),
        ),
      ],
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
    final isCompleted = status == 'COMPLETED';
    final isInProgress = status == 'IN_PROGRESS';
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
                onPressed: canStart
                    ? () => _startQuest(context, viewModel, distance)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  disabledBackgroundColor: isCompleted || isInProgress
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
                            : isInProgress
                            ? Icons.directions_walk_rounded
                            : Icons.play_arrow_rounded,
                      ),
                label: Text(
                  viewModel.isStartingQuest
                      ? 'Starting Quest...'
                      : isCompleted
                      ? 'Quest Completed'
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
