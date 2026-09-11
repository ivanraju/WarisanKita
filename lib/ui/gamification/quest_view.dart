import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';
import 'package:warisan_kita/ui/gamification/quest_detail_view.dart';
import 'package:warisan_kita/viewmodels/gamification_viewmodel.dart';

class QuestView extends StatefulWidget {
  final WorkshopLocation workshop;
  final bool questsAlreadyLoaded;
  final Future<void> Function(BuildContext context, Quest quest)?
  onQuestSelected;

  const QuestView({
    super.key,
    required this.workshop,
    this.questsAlreadyLoaded = false,
    this.onQuestSelected,
  });

  @override
  State<QuestView> createState() => _QuestViewState();
}

class _QuestViewState extends State<QuestView> {
  Quest? _pendingQuest;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    if (!widget.questsAlreadyLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadQuests();
      });
    }
  }

  Future<void> _loadQuests() async {
    _pendingQuest = null;

    final gamificationVM = context.read<GamificationViewModel>();
    await gamificationVM.loadActiveQuestState();
    await gamificationVM.loadQuestsForArtisan(widget.workshop.id);

    if (!mounted || gamificationVM.error != null) {
      return;
    }

    if (gamificationVM.availableQuests.length == 1) {
      await _openQuest(gamificationVM.availableQuests.single);
    }
  }

  Future<void> _openQuest(Quest quest) async {
    final gamificationVM = context.read<GamificationViewModel>();

    if (_isNavigating || gamificationVM.isLoading) {
      return;
    }

    setState(() {
      _pendingQuest = quest;
    });

    final onQuestSelected = widget.onQuestSelected;
    if (onQuestSelected != null) {
      _isNavigating = true;
      await onQuestSelected(context, quest);
      if (mounted) {
        setState(() {
          _isNavigating = false;
          _pendingQuest = null;
        });
      }
      return;
    }

    await gamificationVM.selectQuest(quest);

    if (!mounted || gamificationVM.error != null) {
      return;
    }

    _isNavigating = true;

    final detailRoute = MaterialPageRoute(
      builder: (_) => QuestDetailView(quest: quest, workshop: widget.workshop),
    );

    await Navigator.of(context).push(detailRoute);

    if (mounted) {
      setState(() {
        _isNavigating = false;
        _pendingQuest = null;
      });
    }
  }

  void _retry() {
    final pendingQuest = _pendingQuest;

    if (pendingQuest != null) {
      _openQuest(pendingQuest);
    } else {
      _loadQuests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamificationVM = context.watch<GamificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.workshop.name),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(gamificationVM),
      ),
    );
  }

  Widget _buildBody(GamificationViewModel gamificationVM) {
    if (gamificationVM.isLoading) {
      return _buildLoadingState(
        _pendingQuest == null
            ? 'Loading cultural quests...'
            : 'Loading heritage activities...',
      );
    }

    if (gamificationVM.error != null) {
      return _buildMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Quest unavailable',
        message: gamificationVM.error!,
        actionLabel: 'Try Again',
        onAction: _retry,
      );
    }

    final quests = gamificationVM.availableQuests;

    if (quests.isEmpty) {
      return _buildMessageState(
        icon: Icons.explore_off_rounded,
        title: 'No Active Quest',
        message:
            'This artisan studio does not currently have an approved cultural quest.',
        actionLabel: 'Back to Map',
        onAction: () => Navigator.of(context).pop(),
      );
    }

    if (quests.length == 1) {
      return _buildLoadingState('Preparing quest details...');
    }

    return ListView(
      key: const ValueKey('quest-list'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        Text(
          'Available Cultural Quests',
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF004D40),
            fontSize: 27,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a quest from ${widget.workshop.name}.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 22),
        for (final quest in quests) _buildQuestCard(quest, gamificationVM),
      ],
    );
  }

  Widget _buildQuestCard(
    Quest quest,
    GamificationViewModel gamificationViewModel,
  ) {
    final isActive = gamificationViewModel.isActiveQuest(quest.id);
    final isBlocked = gamificationViewModel.hasActiveQuest && !isActive;
    final stateLabel = isActive
        ? 'Continue Quest'
        : isBlocked
        ? 'Another Quest Active'
        : 'Start Quest';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _openQuest(quest),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3C4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: GoogleFonts.dmSerifDisplay(
                          color: const Color(0xFF0F172A),
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.category,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stateLabel,
                        style: GoogleFonts.plusJakartaSans(
                          color: isBlocked
                              ? const Color(0xFFB45309)
                              : const Color(0xFF00695C),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF004D40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      key: ValueKey(message),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF004D40)),
          const SizedBox(height: 18),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      key: ValueKey(title),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF64748B), size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                color: const Color(0xFF004D40),
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
