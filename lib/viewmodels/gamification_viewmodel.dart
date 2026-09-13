import 'dart:async';

import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/active_quest.dart';
import 'package:warisan_kita/domain/models/artisan_task_request.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart' as quest_domain;
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/quest_location_validation.dart';
import 'package:warisan_kita/domain/models/quest_participation.dart';
import 'package:warisan_kita/domain/models/task_progress.dart';
import 'package:warisan_kita/domain/models/task_completion_result.dart';
import 'package:warisan_kita/domain/models/artisan_heritage_analytics.dart';

class GamificationViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final GamificationRepository _repository;

  List<Quest> _availableQuests = [];
  List<Quest> get availableQuests => _availableQuests;

  Quest? _selectedQuest;
  Quest? get selectedQuest => _selectedQuest;

  List<quest_domain.HeritageTask> _heritageTasks = [];
  List<quest_domain.HeritageTask> get heritageTasks => _heritageTasks;

  String? _questProgressStatus;
  String? get questProgressStatus => _questProgressStatus;
  QuestParticipation? _questParticipation;
  DateTime? get questStartedAt => _questParticipation?.startedAt;

  ActiveQuestState _activeQuestState = const ActiveQuestState.empty();
  ActiveQuestState get activeQuestState => _activeQuestState;
  ActiveQuestSummary? get activeQuest => _activeQuestState.activeQuest;
  bool get hasActiveQuest => _activeQuestState.hasActiveQuest;
  String? get activeQuestWarning => _activeQuestState.warningMessage;
  QuestStartDisposition? _lastQuestStartDisposition;
  QuestStartDisposition? get lastQuestStartDisposition =>
      _lastQuestStartDisposition;

  bool _isStartingQuest = false;
  bool get isStartingQuest => _isStartingQuest;
  bool _isStoppingQuest = false;
  bool get isStoppingQuest => _isStoppingQuest;

  String? _startQuestError;
  String? get startQuestError => _startQuestError;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _loadRequestId = 0;

  static const int dwellRequiredSeconds = 900;
  static const int maxTaskXpReward = 500;
  static const int maxTaskTitleLength = 80;
  static final RegExp _unsupportedControlCharacters = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );
  Timer? _dwellTimer;
  quest_domain.HeritageTask? _goToWorkshopTask;
  quest_domain.HeritageTask? _stayFifteenMinutesTask;
  final Map<String, TaskProgress> _taskProgress = {};
  final Map<String, int?> _authoritativeTaskAwards = {};
  int? authoritativeXpAwardForTask(String taskId) =>
      _authoritativeTaskAwards[taskId];
  bool _isInsideQuestGeofence = false;
  bool get isInsideQuestGeofence => _isInsideQuestGeofence;
  bool _isDwellTracking = false;
  bool get isDwellTracking => _isDwellTracking;
  int _displayedDwellSeconds = 0;
  int get displayedDwellSeconds => _displayedDwellSeconds;
  bool _isCompletingDwellTask = false;
  bool _isProcessingProximity = false;
  bool? _pendingProximity;
  bool _requiresManualResume = false;
  bool _timerRestorationFailed = false;
  bool get requiresJourneyResume =>
      _questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
      _requiresManualResume;
  bool _isQuestBadgeEarned = false;
  bool get isQuestBadgeEarned => _isQuestBadgeEarned;
  bool _hasPendingQuestCompletionCelebration = false;
  bool get hasPendingQuestCompletionCelebration =>
      _hasPendingQuestCompletionCelebration;

  bool get canResumeDwellTracking {
    return _questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
        _isInsideQuestGeofence &&
        _requiresManualResume &&
        _hasIncompleteDwellTask &&
        !_timerRestorationFailed &&
        !_isDwellTracking;
  }

  bool get _hasIncompleteDwellTask {
    final dwellTask = _stayFifteenMinutesTask;
    return dwellTask != null && !isTaskCompleted(dwellTask);
  }

  Quest? _artisanQuest;
  Quest? get artisanQuest => _artisanQuest;

  List<quest_domain.HeritageTask> _artisanTasks = [];
  List<quest_domain.HeritageTask> get artisanTasks =>
      _artisanTasks.where((task) => !task.isArchived).toList(growable: false);

  bool _isLoadingArtisanQuest = false;
  bool get isLoadingArtisanQuest => _isLoadingArtisanQuest;

  bool _isAddingTask = false;
  bool get isAddingTask => _isAddingTask;

  List<HeritageTaskChangeRequest> _artisanTaskChangeRequests = [];
  List<HeritageTaskChangeRequest> get artisanTaskChangeRequests =>
      _artisanTaskChangeRequests;

  bool _isSubmittingTaskChange = false;
  bool get isSubmittingTaskChange => _isSubmittingTaskChange;

  bool _lastTaskEditReverted = false;
  bool get lastTaskEditReverted => _lastTaskEditReverted;

  bool _isUpdatingNewTask = false;
  bool get isUpdatingNewTask => _isUpdatingNewTask;

  bool _isCancellingTaskRequest = false;
  bool get isCancellingTaskRequest => _isCancellingTaskRequest;

  List<ArtisanTaskRequest> get myRequests {
    final requests = <ArtisanTaskRequest>[
      ..._artisanTasks
          .where(_isUnapprovedCustomTask)
          .map(ArtisanTaskRequest.newTask),
      ..._artisanTaskChangeRequests
          .where((request) {
            final status = request.status.toUpperCase();
            return status == 'PENDING_APPROVAL' || status == 'REJECTED';
          })
          .map((request) {
            final task = artisanTaskById(request.taskId);
            return task == null
                ? null
                : ArtisanTaskRequest.change(task: task, request: request);
          })
          .whereType<ArtisanTaskRequest>(),
    ];
    requests.sort((a, b) {
      final aDate = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return requests;
  }

  String? _artisanTaskError;
  String? get artisanTaskError => _artisanTaskError;

  ArtisanHeritageAnalytics? _artisanHeritageAnalytics;
  ArtisanHeritageAnalytics? get artisanHeritageAnalytics =>
      _artisanHeritageAnalytics;

  bool _isLoadingArtisanHeritageAnalytics = false;
  bool get isLoadingArtisanHeritageAnalytics =>
      _isLoadingArtisanHeritageAnalytics;

  String? _artisanHeritageAnalyticsError;
  String? get artisanHeritageAnalyticsError => _artisanHeritageAnalyticsError;

  List<HeritageStamp> _stamps = [];
  List<HeritageStamp> get stamps => _stamps;
  List<HeritageStamp> get earnedPassportStamps =>
      _stamps.where((stamp) => stamp.isUnlocked).toList(growable: false);

  bool _isLoadingPassport = false;
  bool get isLoadingPassport => _isLoadingPassport;
  bool _passportRefreshRequested = false;

  String? _passportError;
  String? get passportError => _passportError;

  String? _passportWarning;
  String? get passportWarning => _passportWarning;

  int _completedPassportTasks = 0;
  int get completedPassportTasks => _completedPassportTasks;

  int _visitedPassportQuests = 0;
  int get visitedPassportQuests => _visitedPassportQuests;
  bool _hasVisitedPassportStudioData = false;
  bool get hasVisitedPassportStudioData => _hasVisitedPassportStudioData;

  int _completedPassportQuests = 0;
  int get completedPassportQuests => _completedPassportQuests;

  int _availablePassportStamps = 0;
  int get availablePassportStamps => _availablePassportStamps;

  bool _hasPassportXpData = true;
  bool get hasPassportXpData => _hasPassportXpData;

  bool _hasPassportStampData = true;
  bool get hasPassportStampData => _hasPassportStampData;

  bool _hasPassportQuestStatistics = true;
  bool get hasPassportQuestStatistics => _hasPassportQuestStatistics;

  bool _hasAvailablePassportStampData = true;
  bool get hasAvailablePassportStampData => _hasAvailablePassportStampData;

  HeritageProgress _heritageProgress = HeritageProgression.fromXp(0);
  int get totalEarnedXp => _heritageProgress.totalXp;
  HeritageTier get currentTier => _heritageProgress.currentTier;
  HeritageTier? get nextTier => _heritageProgress.nextTier;
  int get currentTierXp => _heritageProgress.currentTierXp;
  int get xpForNextTier => _heritageProgress.xpForNextTier;

  List<HeritageTask> _activeTasks = [];
  List<HeritageTask> get activeTasks => _activeTasks;

  double get rankProgress => _heritageProgress.progress.clamp(0.0, 1.0);

  GamificationViewModel({required GamificationRepository repository})
    : _repository = repository {
    WidgetsBinding.instance.addObserver(this);
    _initializeMockData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(pauseDwellTrackingForInterruption());
    }
  }

  int get totalPotentialXp {
    return _heritageTasks.fold(0, (total, task) => total + task.xpReward);
  }

  int get artisanTotalPotentialXp {
    return _artisanTasks
        .where(
          (task) => task.status.toUpperCase() == 'APPROVED' && !task.isArchived,
        )
        .fold(0, (total, task) => total + task.xpReward);
  }

  bool canStartQuest(String questId) {
    final current = activeQuest;
    return current == null || current.questId == questId;
  }

  bool isActiveQuest(String questId) => activeQuest?.questId == questId;

  String activeQuestConflictMessage() {
    final current = activeQuest;
    if (current == null) return 'Another quest is currently active.';
    return 'You are currently exploring “${current.questTitle}” at '
        '${current.studioName}. Complete that quest before starting a new one.';
  }

  Future<void> loadActiveQuestState() async {
    try {
      _activeQuestState = await _repository.getActiveQuestState();
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel load active quest error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> loadArtisanHeritageAnalytics() async {
    if (_isLoadingArtisanHeritageAnalytics) return;
    _isLoadingArtisanHeritageAnalytics = true;
    _artisanHeritageAnalyticsError = null;
    notifyListeners();
    try {
      _artisanHeritageAnalytics = await _repository
          .getArtisanHeritageAnalytics();
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel artisan analytics error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanHeritageAnalytics = null;
      _artisanHeritageAnalyticsError =
          'Heritage analytics are currently unavailable.';
    } finally {
      _isLoadingArtisanHeritageAnalytics = false;
      notifyListeners();
    }
  }

  Future<void> loadPassport() async {
    if (_isLoadingPassport) {
      _passportRefreshRequested = true;
      return;
    }

    do {
      _passportRefreshRequested = false;
      _isLoadingPassport = true;
      _passportError = null;
      _passportWarning = null;
      notifyListeners();
      try {
        final snapshot = await _repository.getPassportSnapshot();
        _stamps = snapshot.stamps;
        _completedPassportTasks = snapshot.completedTaskCount;
        _visitedPassportQuests = snapshot.visitedQuestCount;
        _hasVisitedPassportStudioData = snapshot.hasVisitedStudioData;
        _completedPassportQuests = snapshot.completedQuestCount;
        _availablePassportStamps = snapshot.availableStampCount;
        _hasPassportXpData = snapshot.hasXpData;
        _hasPassportStampData = snapshot.hasStampData;
        _hasPassportQuestStatistics = snapshot.hasQuestStatistics;
        _hasAvailablePassportStampData = snapshot.hasAvailableStampData;
        _passportWarning = snapshot.warnings.isEmpty
            ? null
            : 'Some Passport information could not be refreshed.';
        _heritageProgress = HeritageProgression.fromXp(snapshot.totalXp);
      } catch (error, stackTrace) {
        debugPrint('GamificationViewModel load passport error: $error');
        debugPrintStack(stackTrace: stackTrace);
        final message = error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Exception: ', '');
        _passportError = message.toLowerCase().contains('signed in')
            ? message
            : 'Unable to load your Heritage Passport. Please try again.';
      } finally {
        _isLoadingPassport = false;
        notifyListeners();
      }
    } while (_passportRefreshRequested);
  }

  Future<void> loadQuestsForArtisan(String artisanProfileId) async {
    final requestId = ++_loadRequestId;
    final runningQuestId =
        _selectedQuest != null &&
            _heritageTasks.isNotEmpty &&
            _questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
            _isDwellTracking
        ? _selectedQuest!.id
        : null;

    _startQuestError = null;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final quests = await _repository.getApprovedQuestsForArtisan(
        artisanProfileId,
      );

      if (requestId != _loadRequestId) {
        return;
      }

      final preserveRunningQuest = runningQuestId != null;
      if (!preserveRunningQuest) {
        _selectedQuest = null;
        _heritageTasks = [];
        _questProgressStatus = null;
        _resetTouristTaskProgress();
      }
      _availableQuests = quests;
    } catch (error, stackTrace) {
      if (requestId != _loadRequestId) {
        return;
      }

      debugPrint('GamificationViewModel load quests error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = 'Unable to load cultural quests right now. Please try again.';
    } finally {
      if (requestId == _loadRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectQuest(Quest quest) async {
    final isReopeningRunningQuest =
        _selectedQuest?.id == quest.id &&
        _heritageTasks.isNotEmpty &&
        _questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
        _isDwellTracking;
    if (isReopeningRunningQuest) {
      _selectedQuest = quest;
      _startQuestError = null;
      _error = null;
      notifyListeners();
      return;
    }

    final requestId = ++_loadRequestId;

    _selectedQuest = quest;
    _heritageTasks = [];
    _questProgressStatus = null;
    _resetTouristTaskProgress();
    _startQuestError = null;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final tasks = await _repository.getHeritageTasks(quest.id);
      QuestParticipation? participation;
      var badgeEarned = false;
      ActiveQuestState? activeState;
      try {
        participation = await _repository.getCurrentQuestParticipation(
          quest.id,
        );
      } catch (error, stackTrace) {
        debugPrint('GamificationViewModel load quest participation: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      try {
        badgeEarned = await _repository.hasEarnedQuestStamp(quest.id);
      } catch (error, stackTrace) {
        debugPrint('GamificationViewModel load quest stamp error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      try {
        activeState = await _repository.getActiveQuestState();
      } catch (error, stackTrace) {
        debugPrint('GamificationViewModel refresh active quest: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (requestId != _loadRequestId) {
        return;
      }

      _heritageTasks = tasks;
      _questParticipation = participation;
      _questProgressStatus = participation?.status;
      _isQuestBadgeEarned = badgeEarned || participation?.isCompleted == true;
      if (activeState != null) _activeQuestState = activeState;
      _identifySystemTasks();

      final progress = await _repository.getTaskProgress(
        tasks.map((task) => task.id).toList(growable: false),
      );
      if (requestId != _loadRequestId) return;
      for (final item in progress) {
        _taskProgress[item.taskId] = item;
      }

      await _restorePersistedDwellAsPaused();
      _syncDisplayedDwellProgress();
      // Only an unfinished dwell task needs an explicit resume after persisted
      // state is restored. Completed dwell time must not lock the remaining QR
      // activities merely because the tourist navigated away and returned.
      _requiresManualResume =
          _questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
          !isQuestPermanentlyCompleted &&
          _hasIncompleteDwellTask;
    } catch (error, stackTrace) {
      if (requestId != _loadRequestId) {
        return;
      }

      debugPrint('GamificationViewModel load heritage tasks error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = 'Unable to load heritage activities. Please try again.';
    } finally {
      if (requestId == _loadRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> startSelectedQuest({
    required QuestLocationValidationResult verifiedLocation,
  }) async {
    if (_isStartingQuest) return false;

    final quest = _selectedQuest;
    if (quest == null) {
      _startQuestError = 'Select a quest before starting it.';
      notifyListeners();
      return false;
    }
    if (_heritageTasks.isEmpty) {
      _startQuestError = 'This quest has no published activities yet.';
      notifyListeners();
      return false;
    }
    if (!verifiedLocation.isValid) {
      _startQuestError =
          verifiedLocation.message ?? 'A fresh location is required.';
      notifyListeners();
      return false;
    }

    final wasStopped = _questProgressStatus?.toUpperCase() == 'STOPPED';
    _isStartingQuest = true;
    _startQuestError = null;
    notifyListeners();
    try {
      _activeQuestState = await _repository.getActiveQuestState();
      if (!canStartQuest(quest.id)) {
        _lastQuestStartDisposition = QuestStartDisposition.blockedByOtherQuest;
        _startQuestError = activeQuestConflictMessage();
        return false;
      }
      _identifySystemTasks();
      final arrivalTask = _goToWorkshopTask;
      final dwellTask = _stayFifteenMinutesTask;
      if (arrivalTask == null || dwellTask == null) {
        throw StateError(
          'The two required system activities are not configured correctly.',
        );
      }
      final startResult = await _repository.startQuest(
        questId: quest.id,
        taskIds: _heritageTasks.map((task) => task.id).toList(growable: false),
      );
      _activeQuestState = startResult.activeState;
      _lastQuestStartDisposition = startResult.disposition;
      if (!startResult.isSuccessful) {
        _startQuestError =
            startResult.disposition ==
                QuestStartDisposition.dataIntegrityConflict
            ? _activeQuestState.warningMessage ??
                  'Multiple active quests were found. Please contact support.'
            : activeQuestConflictMessage();
        return false;
      }
      _questParticipation = startResult.participation;
      _questProgressStatus = _questParticipation?.status;

      if (startResult.wasResumed) {
        final progress = await _repository.getTaskProgress(
          _heritageTasks.map((task) => task.id).toList(growable: false),
        );
        for (final item in progress) {
          _taskProgress[item.taskId] = item;
        }
        await _restorePersistedDwellAsPaused();
        _syncDisplayedDwellProgress();
        _isInsideQuestGeofence = true;
        if (wasStopped && !isTaskCompleted(dwellTask)) {
          final dwellProgress = await _repository.startTimedTask(dwellTask.id);
          _taskProgress[dwellTask.id] = dwellProgress;
          _requiresManualResume = false;
          _beginLocalDwellTimer(dwellProgress);
        } else {
          _requiresManualResume = !wasStopped;
        }
        return true;
      }

      _isInsideQuestGeofence = true;
      final arrivalCompletion = await _repository.completeArrivalTask(
        questId: quest.id,
        taskId: arrivalTask.id,
      );
      _taskProgress[arrivalTask.id] = arrivalCompletion.progress;
      _authoritativeTaskAwards[arrivalTask.id] = arrivalCompletion.xpAwarded;
      final dwellProgress = await _repository.startTimedTask(dwellTask.id);
      _taskProgress[dwellTask.id] = dwellProgress;
      _requiresManualResume = false;
      _beginLocalDwellTimer(dwellProgress);
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel start quest error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (_questProgressStatus?.toUpperCase() == 'IN_PROGRESS') {
        _requiresManualResume = true;
      }
      _startQuestError = _friendlyStartQuestError(error);
      return false;
    } finally {
      _isStartingQuest = false;
      notifyListeners();
    }
  }

  bool isTaskCompleted(quest_domain.HeritageTask task) {
    return _taskProgress[task.id]?.isCompleted ?? false;
  }

  bool get areAllHeritageTasksCompleted {
    if (isQuestPermanentlyCompleted) return true;
    return areAllRequiredHeritageTasksCompleted;
  }

  bool get areAllRequiredHeritageTasksCompleted {
    if (isQuestPermanentlyCompleted) return true;
    final requiredTasks = effectiveRequiredHeritageTasks;
    return requiredTasks.isNotEmpty && requiredTasks.every(isTaskCompleted);
  }

  bool get isQuestPermanentlyCompleted =>
      _questProgressStatus?.toUpperCase() == 'COMPLETED' || _isQuestBadgeEarned;

  bool isBonusTask(quest_domain.HeritageTask task) {
    return _questParticipation?.isBonusTask(task) ?? false;
  }

  List<quest_domain.HeritageTask> get effectiveRequiredHeritageTasks =>
      _heritageTasks
          .where(
            (task) =>
                task.isRequired &&
                !(_questParticipation?.isBonusTask(task) ?? false),
          )
          .toList(growable: false);

  int get completedEffectiveRequiredTaskCount {
    final requiredTasks = effectiveRequiredHeritageTasks;
    if (isQuestPermanentlyCompleted) return requiredTasks.length;
    return requiredTasks.where(isTaskCompleted).length;
  }

  bool consumeQuestCompletionCelebration() {
    if (!_hasPendingQuestCompletionCelebration) return false;
    _hasPendingQuestCompletionCelebration = false;
    return true;
  }

  void _markQuestBadgeEarned() {
    if (!_isQuestBadgeEarned) {
      _hasPendingQuestCompletionCelebration = true;
    }
    _isQuestBadgeEarned = true;
  }

  void _markQuestFullyCompleted() {
    _questProgressStatus = 'COMPLETED';
    if (activeQuest?.questId == _selectedQuest?.id) {
      _activeQuestState = const ActiveQuestState.empty();
    }
    _cancelDwellTimer();
  }

  bool isStayFifteenMinutesTask(quest_domain.HeritageTask task) {
    return task.isSystemTask && task.sortOrder == 2;
  }

  bool canVerifyTaskWithQr(quest_domain.HeritageTask task) {
    if (task.isSystemTask) return false;
    final canCompleteJourneyTask =
        _questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
        !isQuestPermanentlyCompleted;
    final canCompleteAfterBadge =
        isQuestPermanentlyCompleted &&
        (!task.isRequired || isBonusTask(task));
    if (_requiresManualResume ||
        (!canCompleteJourneyTask && !canCompleteAfterBadge) ||
        isTaskCompleted(task)) {
      return false;
    }
    return !isStayFifteenMinutesTask(task) ||
        _displayedDwellSeconds >= dwellRequiredSeconds;
  }

  String qrVerificationLabel(quest_domain.HeritageTask task) {
    if (task.isSystemTask) {
      return 'Completes Automatically';
    }
    final canCompleteJourneyTask =
        _questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
        !isQuestPermanentlyCompleted;
    final canCompleteAfterBadge =
        isQuestPermanentlyCompleted &&
        (!task.isRequired || isBonusTask(task));
    if (!canCompleteJourneyTask && !canCompleteAfterBadge) {
      return 'Start Quest to Scan';
    }
    if (_requiresManualResume) return 'Start Quest to Scan';
    if (isStayFifteenMinutesTask(task) &&
        _displayedDwellSeconds < dwellRequiredSeconds) {
      return 'Complete 15 Minutes First';
    }
    return 'Scan Workshop QR';
  }

  Future<bool> verifyArtisanQrForTask({
    required quest_domain.HeritageTask task,
    required String qrPayload,
  }) async {
    final quest = _selectedQuest;
    if (quest == null || !canVerifyTaskWithQr(task)) return false;

    _startQuestError = null;
    notifyListeners();
    try {
      _activeQuestState = await _repository.getActiveQuestState();
      final currentActiveQuest = activeQuest;
      if (currentActiveQuest != null &&
          currentActiveQuest.questId != quest.id) {
        _startQuestError =
            'Complete your active quest before attempting activities from '
            'another quest.';
        notifyListeners();
        return false;
      }
      final completion = await _repository.completeTaskWithArtisanQr(
        questId: quest.id,
        taskId: task.id,
        qrPayload: qrPayload,
      );
      _taskProgress[task.id] = completion.progress;
      _authoritativeTaskAwards[task.id] = completion.xpAwarded;
      if (areAllRequiredHeritageTasksCompleted) {
        _markQuestBadgeEarned();
      }
      if (areAllHeritageTasksCompleted) {
        _markQuestFullyCompleted();
      }
      notifyListeners();
      unawaited(loadPassport());
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel QR verification error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _startQuestError = error
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resumeSelectedQuest({
    required QuestLocationValidationResult verifiedLocation,
  }) async {
    if (!canResumeDwellTracking || _isStartingQuest) return false;
    if (!verifiedLocation.isValid) {
      _startQuestError =
          verifiedLocation.message ?? 'A fresh location is required.';
      notifyListeners();
      return false;
    }

    _isStartingQuest = true;
    _startQuestError = null;
    notifyListeners();
    try {
      final dwellTask = _stayFifteenMinutesTask;
      if (dwellTask != null && !isTaskCompleted(dwellTask)) {
        final progress = await _repository.startTimedTask(dwellTask.id);
        _taskProgress[dwellTask.id] = progress;
        _requiresManualResume = false;
        _beginLocalDwellTimer(progress);
      } else {
        _requiresManualResume = false;
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel manual resume error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _startQuestError = 'Unable to resume this quest right now.';
      return false;
    } finally {
      _isStartingQuest = false;
      notifyListeners();
    }
  }

  Future<bool> stopSelectedQuest() async {
    if (_isStoppingQuest || _isStartingQuest) return false;
    final quest = _selectedQuest;
    if (quest == null ||
        _questProgressStatus?.toUpperCase() != 'IN_PROGRESS' ||
        isQuestPermanentlyCompleted) {
      return false;
    }

    _isStoppingQuest = true;
    _startQuestError = null;
    notifyListeners();
    try {
      await _pauseDwellTracking();
      if (_startQuestError != null) {
        _requiresManualResume = true;
        return false;
      }
      _questParticipation = await _repository.stopQuest(quest.id);
      _questProgressStatus = _questParticipation?.status ?? 'STOPPED';
      if (activeQuest?.questId == quest.id) {
        _activeQuestState = const ActiveQuestState.empty();
      }
      _requiresManualResume = false;
      _isInsideQuestGeofence = false;
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel stop quest error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _startQuestError = error
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Exception: ', '');
      if (_questProgressStatus?.toUpperCase() == 'IN_PROGRESS') {
        _requiresManualResume = true;
      }
      return false;
    } finally {
      _isStoppingQuest = false;
      notifyListeners();
    }
  }

  Future<void> handleQuestProximityChanged(bool isInside) async {
    _pendingProximity = isInside;
    if (_isProcessingProximity) return;

    _isProcessingProximity = true;
    try {
      while (_pendingProximity != null) {
        final next = _pendingProximity!;
        _pendingProximity = null;
        await _applyQuestProximity(next);
      }
    } finally {
      _isProcessingProximity = false;
    }
  }

  Future<void> _applyQuestProximity(bool isInside) async {
    if (_questProgressStatus?.toUpperCase() != 'IN_PROGRESS') {
      if (_isInsideQuestGeofence != isInside) {
        _isInsideQuestGeofence = isInside;
        notifyListeners();
      }
      return;
    }

    if (isInside) {
      _isInsideQuestGeofence = true;
      notifyListeners();
      return;
    }

    _isInsideQuestGeofence = false;
    await stopSelectedQuest();
    notifyListeners();
  }

  Future<void> pauseDwellTrackingForInterruption() async {
    final dwellTask = _stayFifteenMinutesTask;
    if (_questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
        dwellTask != null &&
        !isTaskCompleted(dwellTask)) {
      _requiresManualResume = true;
      await _pauseDwellTracking();
      notifyListeners();
    }
  }

  Future<void> _pauseDwellTracking() async {
    final dwellTask = _stayFifteenMinutesTask;
    final progress = dwellTask == null ? null : _taskProgress[dwellTask.id];
    if (dwellTask == null || progress == null || progress.isCompleted) {
      _cancelDwellTimer();
      return;
    }

    _refreshDisplayedDwellProgress();
    _cancelDwellTimer();
    if (_displayedDwellSeconds >= dwellRequiredSeconds) {
      await _completeDwellTask();
      return;
    }
    if (progress.trackingStartedAt == null) return;

    try {
      final paused = await _repository.pauseTimedTask(
        taskId: dwellTask.id,
        progressSeconds: _displayedDwellSeconds,
      );
      _taskProgress[dwellTask.id] = paused;
      _displayedDwellSeconds = paused.progressSeconds.clamp(
        0,
        dwellRequiredSeconds,
      );
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel pause dwell error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _startQuestError = 'Unable to save the workshop timer right now.';
    }
    notifyListeners();
  }

  void _beginLocalDwellTimer(TaskProgress progress) {
    _cancelDwellTimer();
    _syncDisplayedDwellProgress();
    if (_requiresManualResume ||
        progress.isCompleted ||
        progress.trackingStartedAt == null) {
      return;
    }

    _isDwellTracking = true;
    _dwellTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshDisplayedDwellProgress();
      if (_displayedDwellSeconds >= dwellRequiredSeconds) {
        unawaited(_completeDwellTask());
      } else {
        notifyListeners();
      }
    });
  }

  void _refreshDisplayedDwellProgress() {
    final dwellTask = _stayFifteenMinutesTask;
    final progress = dwellTask == null ? null : _taskProgress[dwellTask.id];
    if (progress == null) {
      _displayedDwellSeconds = 0;
      return;
    }

    var seconds = progress.progressSeconds;
    final startedAt = progress.trackingStartedAt;
    if (!progress.isCompleted && startedAt != null) {
      final elapsed = DateTime.now().toUtc().difference(startedAt).inSeconds;
      seconds += elapsed < 0 ? 0 : elapsed;
    }
    _displayedDwellSeconds = seconds.clamp(0, dwellRequiredSeconds);
  }

  void _syncDisplayedDwellProgress() {
    final dwellTask = _stayFifteenMinutesTask;
    final progress = dwellTask == null ? null : _taskProgress[dwellTask.id];
    _displayedDwellSeconds = (progress?.progressSeconds ?? 0).clamp(
      0,
      dwellRequiredSeconds,
    );
  }

  Future<void> _completeDwellTask() async {
    if (_isCompletingDwellTask) return;
    final dwellTask = _stayFifteenMinutesTask;
    if (dwellTask == null ||
        isTaskCompleted(dwellTask) ||
        !_isInsideQuestGeofence ||
        _requiresManualResume) {
      return;
    }

    _isCompletingDwellTask = true;
    _cancelDwellTimer();
    try {
      final completion = await _repository.completeTimedTask(dwellTask.id);
      _acceptDwellCompletion(dwellTask.id, completion);
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel complete dwell error: $error');
      debugPrintStack(stackTrace: stackTrace);
      try {
        final latest = await _repository.getTaskProgress([dwellTask.id]);
        final persisted = latest
            .where((item) => item.taskId == dwellTask.id && item.isCompleted)
            .firstOrNull;
        if (persisted == null) {
          _startQuestError = 'Unable to complete the workshop timer right now.';
        } else {
          final recovered = await _repository.completeTimedTask(dwellTask.id);
          _acceptDwellCompletion(dwellTask.id, recovered);
          _startQuestError = null;
        }
      } catch (recoveryError, recoveryStackTrace) {
        debugPrint(
          'GamificationViewModel dwell completion recovery error: '
          '$recoveryError',
        );
        debugPrintStack(stackTrace: recoveryStackTrace);
        _startQuestError = 'Unable to complete the workshop timer right now.';
      }
    } finally {
      _isCompletingDwellTask = false;
      notifyListeners();
    }
  }

  void _acceptDwellCompletion(String taskId, TaskCompletionResult completion) {
    _taskProgress[taskId] = completion.progress;
    _authoritativeTaskAwards[taskId] = completion.xpAwarded;
    _displayedDwellSeconds = dwellRequiredSeconds;
    if (areAllRequiredHeritageTasksCompleted) {
      _markQuestBadgeEarned();
    }
    if (areAllHeritageTasksCompleted) {
      _markQuestFullyCompleted();
    }
    unawaited(loadPassport());
  }

  void _identifySystemTasks() {
    _goToWorkshopTask = _systemTaskAtSortOrder(1);
    _stayFifteenMinutesTask = _systemTaskAtSortOrder(2);
  }

  Future<void> _restorePersistedDwellAsPaused() async {
    _timerRestorationFailed = false;
    final dwellTask = _stayFifteenMinutesTask;
    final progress = dwellTask == null ? null : _taskProgress[dwellTask.id];
    if (dwellTask == null ||
        progress == null ||
        progress.isCompleted ||
        progress.trackingStartedAt == null ||
        _questProgressStatus?.toUpperCase() != 'IN_PROGRESS' ||
        isQuestPermanentlyCompleted) {
      return;
    }
    try {
      _taskProgress[dwellTask.id] = await _repository.restoreTimedTaskAsPaused(
        dwellTask.id,
      );
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel restore dwell timer error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _timerRestorationFailed = true;
      _startQuestError =
          'Unable to safely restore the workshop timer. Refresh and try again.';
    }
  }

  quest_domain.HeritageTask? _systemTaskAtSortOrder(int sortOrder) {
    for (final task in _heritageTasks) {
      if (task.isSystemTask && task.sortOrder == sortOrder) return task;
    }
    return null;
  }

  void _resetTouristTaskProgress() {
    _cancelDwellTimer();
    _goToWorkshopTask = null;
    _stayFifteenMinutesTask = null;
    _questParticipation = null;
    _taskProgress.clear();
    _authoritativeTaskAwards.clear();
    _isInsideQuestGeofence = false;
    _displayedDwellSeconds = 0;
    _pendingProximity = null;
    _requiresManualResume = false;
    _timerRestorationFailed = false;
    _isQuestBadgeEarned = false;
    _hasPendingQuestCompletionCelebration = false;
  }

  void _cancelDwellTimer() {
    _dwellTimer?.cancel();
    _dwellTimer = null;
    _isDwellTracking = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelDwellTimer();
    super.dispose();
  }

  void clearStartQuestError() {
    _startQuestError = null;
  }

  String _friendlyStartQuestError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
    final lower = message.toLowerCase();
    if (lower.contains('signed in') || lower.contains('no published')) {
      return message;
    }
    return 'Unable to start this quest right now. Please try again.';
  }

  Future<void> loadArtisanQuestAndTasks() async {
    if (_isLoadingArtisanQuest) return;

    _artisanQuest = null;
    _artisanTasks = [];
    _artisanTaskChangeRequests = [];
    _artisanTaskError = null;
    _isLoadingArtisanQuest = true;
    notifyListeners();

    try {
      final quest = await _repository.getQuestForCurrentArtisan();
      _artisanQuest = quest;
      if (quest != null) {
        _artisanTasks = await _repository.getArtisanHeritageTasks(quest.id);
        await _loadArtisanTaskChangeRequests();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'GamificationViewModel load artisan task management error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'Unable to load your cultural quest right now.',
      );
    } finally {
      _isLoadingArtisanQuest = false;
      notifyListeners();
    }
  }

  Future<void> refreshArtisanTasks() async {
    final quest = _artisanQuest;
    if (quest == null) return;

    try {
      _artisanTasks = await _repository.getArtisanHeritageTasks(quest.id);
      await _loadArtisanTaskChangeRequests();
      _artisanTaskError = null;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel refresh artisan tasks error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = 'Unable to refresh heritage activities.';
    } finally {
      notifyListeners();
    }
  }

  String _cleanSingleLine(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  String? _boundedTextError({
    required String value,
    required String label,
    required int maxLength,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '$label must not be empty.';
    }
    if (_unsupportedControlCharacters.hasMatch(trimmed)) {
      return '$label contains unsupported control characters.';
    }
    if (trimmed.length > maxLength) {
      return '$label must be $maxLength characters or fewer.';
    }
    return null;
  }

  String? _taskInputError({required String title, required int xpReward}) {
    final titleError = _boundedTextError(
      value: title,
      label: 'Task title',
      maxLength: maxTaskTitleLength,
    );
    if (titleError != null) {
      return titleError;
    }
    if (xpReward < 0 || xpReward > maxTaskXpReward) {
      return 'XP reward must be between 0 and $maxTaskXpReward.';
    }
    return null;
  }

  String _normalizedTaskTitle(String value) =>
      _cleanSingleLine(value).toLowerCase();

  bool _hasDuplicateTaskTitle(String title, {String? excludingTaskId}) {
    final normalized = _normalizedTaskTitle(title);
    final matchesTask = _artisanTasks.any(
      (task) =>
          task.id != excludingTaskId &&
          !task.isArchived &&
          task.status.toUpperCase() != 'REJECTED' &&
          _normalizedTaskTitle(task.title) == normalized,
    );
    if (matchesTask) {
      return true;
    }

    return _artisanTaskChangeRequests.any(
      (request) =>
          request.taskId != excludingTaskId &&
          request.requestType.toUpperCase() == 'EDIT' &&
          request.status.toUpperCase() == 'PENDING_APPROVAL' &&
          request.proposedTitle != null &&
          _normalizedTaskTitle(request.proposedTitle!) == normalized,
    );
  }

  bool _validateTaskInput({
    required String title,
    required int xpReward,
    String? excludingTaskId,
  }) {
    final inputError = _taskInputError(title: title, xpReward: xpReward);
    if (inputError != null) {
      _artisanTaskError = inputError;
      notifyListeners();
      return false;
    }
    if (_hasDuplicateTaskTitle(title, excludingTaskId: excludingTaskId)) {
      _artisanTaskError = 'A task with this title already exists.';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> addHeritageTask({
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    if (_isAddingTask) return false;

    if (!_validateTaskInput(title: title, xpReward: xpReward)) {
      return false;
    }
    final cleanTitle = _cleanSingleLine(title);

    final quest = _artisanQuest;
    if (quest == null) {
      _artisanTaskError = 'No cultural quest is assigned to this artisan.';
      notifyListeners();
      return false;
    }

    _artisanTaskError = null;
    _isAddingTask = true;
    notifyListeners();

    try {
      final highestSortOrder = _artisanTasks.fold<int>(
        0,
        (highest, task) =>
            (task.sortOrder ?? 0) > highest ? task.sortOrder! : highest,
      );
      final newSortOrder = highestSortOrder < 2 ? 3 : highestSortOrder + 1;
      await _repository.addHeritageTask(
        questId: quest.id,
        title: cleanTitle,
        isRequired: isRequired,
        xpReward: xpReward,
        sortOrder: newSortOrder,
      );
      _artisanTasks = await _repository.getArtisanHeritageTasks(quest.id);
      await _loadArtisanTaskChangeRequests();
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel add heritage task error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The heritage activity could not be added. Please try again.',
      );
      return false;
    } finally {
      _isAddingTask = false;
      notifyListeners();
    }
  }

  HeritageTaskChangeRequest? pendingChangeForTask(String taskId) {
    final latestRequest = _artisanTaskChangeRequests
        .where((request) => request.taskId == taskId)
        .firstOrNull;
    return latestRequest?.status.toUpperCase() == 'PENDING_APPROVAL'
        ? latestRequest
        : null;
  }

  HeritageTaskChangeRequest? rejectedEditForTask(String taskId) {
    final latestRequest = _artisanTaskChangeRequests
        .where((request) => request.taskId == taskId)
        .firstOrNull;
    return latestRequest?.requestType.toUpperCase() == 'EDIT' &&
            latestRequest?.status.toUpperCase() == 'REJECTED'
        ? latestRequest
        : null;
  }

  HeritageTaskChangeRequest? rejectedDeleteForTask(String taskId) {
    final latestRequest = _artisanTaskChangeRequests
        .where((request) => request.taskId == taskId)
        .firstOrNull;
    return latestRequest?.requestType.toUpperCase() == 'DELETE' &&
            latestRequest?.status.toUpperCase() == 'REJECTED'
        ? latestRequest
        : null;
  }

  quest_domain.HeritageTask? artisanTaskById(String taskId) {
    for (final task in _artisanTasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  Future<bool> updateNewTaskSubmission({
    required quest_domain.HeritageTask task,
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    if (_isUpdatingNewTask || !_isUnapprovedCustomTask(task)) return false;

    if (!_validateTaskInput(
      title: title,
      xpReward: xpReward,
      excludingTaskId: task.id,
    )) {
      return false;
    }
    final cleanTitle = _cleanSingleLine(title);

    _isUpdatingNewTask = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      final updated = await _repository.updateUnapprovedHeritageTask(
        taskId: task.id,
        title: cleanTitle,
        isRequired: isRequired,
        xpReward: xpReward,
      );
      _artisanTasks = _artisanTasks
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel update new task error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The task submission could not be updated.',
      );
      return false;
    } finally {
      _isUpdatingNewTask = false;
      notifyListeners();
    }
  }

  Future<bool> cancelNewTaskSubmission(quest_domain.HeritageTask task) async {
    if (_isCancellingTaskRequest || !_isUnapprovedCustomTask(task)) {
      return false;
    }

    _isCancellingTaskRequest = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      await _repository.deleteUnapprovedHeritageTask(
        taskId: task.id,
        expectedStatus: task.status,
      );
      _artisanTasks = _artisanTasks
          .where((item) => item.id != task.id)
          .toList(growable: false);
      _artisanTaskChangeRequests = _artisanTaskChangeRequests
          .where((request) => request.taskId != task.id)
          .toList(growable: false);
      await refreshArtisanTasks();
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel cancel new task error: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _handleTaskCancellationFailure(
        error,
        fallback: 'The task submission could not be cancelled. Please retry.',
      );
      return false;
    } finally {
      _isCancellingTaskRequest = false;
      notifyListeners();
    }
  }

  Future<bool> cancelPendingTaskChange(
    quest_domain.HeritageTask task,
    HeritageTaskChangeRequest request,
  ) async {
    if (_isCancellingTaskRequest ||
        !_canRemoveTaskChangeRequest(
          task: task,
          request: request,
          expectedStatus: 'PENDING_APPROVAL',
        )) {
      return false;
    }

    _isCancellingTaskRequest = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      await _repository.deleteHeritageTaskChangeRequest(
        requestId: request.id,
        taskId: task.id,
        expectedRequestType: request.requestType,
        expectedStatus: 'PENDING_APPROVAL',
      );
      _artisanTaskChangeRequests = _artisanTaskChangeRequests
          .where((item) => item.id != request.id)
          .toList(growable: false);
      await refreshArtisanTasks();
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel cancel pending task change: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _handleTaskCancellationFailure(
        error,
        fallback: 'The task request could not be cancelled. Please retry.',
      );
      return false;
    } finally {
      _isCancellingTaskRequest = false;
      notifyListeners();
    }
  }

  Future<bool> dismissRejectedTaskChange(
    quest_domain.HeritageTask task,
    HeritageTaskChangeRequest request,
  ) async {
    if (_isCancellingTaskRequest ||
        !_canRemoveTaskChangeRequest(
          task: task,
          request: request,
          expectedStatus: 'REJECTED',
        )) {
      return false;
    }

    _isCancellingTaskRequest = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      await _repository.deleteHeritageTaskChangeRequest(
        requestId: request.id,
        taskId: task.id,
        expectedRequestType: request.requestType,
        expectedStatus: 'REJECTED',
      );
      _artisanTaskChangeRequests = _artisanTaskChangeRequests
          .where((item) => item.id != request.id)
          .toList(growable: false);
      await refreshArtisanTasks();
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel dismiss rejected task change: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _handleTaskCancellationFailure(
        error,
        fallback: 'The rejected request could not be removed. Please retry.',
      );
      return false;
    } finally {
      _isCancellingTaskRequest = false;
      notifyListeners();
    }
  }

  bool _canRemoveTaskChangeRequest({
    required quest_domain.HeritageTask task,
    required HeritageTaskChangeRequest request,
    required String expectedStatus,
  }) {
    final requestType = request.requestType.toUpperCase();
    return !task.isSystemTask &&
        !task.isArchived &&
        request.taskId == task.id &&
        (requestType == 'EDIT' || requestType == 'DELETE') &&
        request.status.toUpperCase() == expectedStatus;
  }

  Future<void> _handleTaskCancellationFailure(
    Object error, {
    required String fallback,
  }) async {
    final message = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
    final lower = message.toLowerCase();
    if (lower.contains('already been reviewed') ||
        lower.contains('no longer available') ||
        lower.contains('latest status')) {
      await refreshArtisanTasks();
      _artisanTaskError =
          'This request has already been reviewed. Refreshing its latest status.';
      return;
    }
    _artisanTaskError = _friendlyArtisanTaskError(error, fallback: fallback);
  }

  Future<bool> requestHeritageTaskEdit({
    required quest_domain.HeritageTask task,
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    if (_isSubmittingTaskChange) return false;
    if (!_canRequestTaskChange(task)) return false;

    if (!_validateTaskInput(
      title: title,
      xpReward: xpReward,
      excludingTaskId: task.id,
    )) {
      return false;
    }
    final cleanTitle = _cleanSingleLine(title);
    if (_matchesApprovedTask(
      task,
      title: cleanTitle,
      isRequired: isRequired,
      xpReward: xpReward,
    )) {
      _artisanTaskError = 'No changes to submit.';
      notifyListeners();
      return false;
    }

    _isSubmittingTaskChange = true;
    _lastTaskEditReverted = false;
    _artisanTaskError = null;
    notifyListeners();
    try {
      final request = await _repository.requestHeritageTaskEdit(
        taskId: task.id,
        proposedTitle: cleanTitle,
        proposedIsRequired: isRequired,
        proposedXpReward: xpReward,
      );
      _artisanTaskChangeRequests = [request, ..._artisanTaskChangeRequests];
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel request task edit error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The task edit request could not be submitted.',
      );
      return false;
    } finally {
      _isSubmittingTaskChange = false;
      notifyListeners();
    }
  }

  Future<bool> updatePendingTaskEdit({
    required quest_domain.HeritageTask task,
    required HeritageTaskChangeRequest request,
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    if (_isSubmittingTaskChange ||
        task.isSystemTask ||
        task.status.toUpperCase() != 'APPROVED' ||
        task.isArchived ||
        request.taskId != task.id ||
        request.requestType.toUpperCase() != 'EDIT' ||
        request.status.toUpperCase() != 'PENDING_APPROVAL') {
      return false;
    }

    if (!_validateTaskInput(
      title: title,
      xpReward: xpReward,
      excludingTaskId: task.id,
    )) {
      return false;
    }
    final cleanTitle = _cleanSingleLine(title);

    _isSubmittingTaskChange = true;
    _lastTaskEditReverted = false;
    _artisanTaskError = null;
    notifyListeners();
    try {
      if (_matchesApprovedTask(
        task,
        title: cleanTitle,
        isRequired: isRequired,
        xpReward: xpReward,
      )) {
        await _repository.deletePendingHeritageTaskEdit(
          requestId: request.id,
          taskId: task.id,
        );
        _artisanTaskChangeRequests = _artisanTaskChangeRequests
            .where((item) => item.id != request.id)
            .toList(growable: false);
        _lastTaskEditReverted = true;
      } else {
        final updated = await _repository.updatePendingHeritageTaskEdit(
          requestId: request.id,
          taskId: task.id,
          proposedTitle: cleanTitle,
          proposedIsRequired: isRequired,
          proposedXpReward: xpReward,
        );
        _artisanTaskChangeRequests = _artisanTaskChangeRequests
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel update pending task edit: $error');
      debugPrintStack(stackTrace: stackTrace);
      await refreshArtisanTasks();
      _artisanTaskError =
          'This request may already have been reviewed. The latest task status has been reloaded.';
      return false;
    } finally {
      _isSubmittingTaskChange = false;
      notifyListeners();
    }
  }

  Future<bool> requestHeritageTaskDelete(quest_domain.HeritageTask task) async {
    if (_isSubmittingTaskChange) return false;
    if (!_canRequestTaskChange(task)) return false;

    _isSubmittingTaskChange = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      final request = await _repository.requestHeritageTaskDelete(task.id);
      _artisanTaskChangeRequests = [request, ..._artisanTaskChangeRequests];
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel request task delete error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The task deletion request could not be submitted.',
      );
      return false;
    } finally {
      _isSubmittingTaskChange = false;
      notifyListeners();
    }
  }

  bool _canRequestTaskChange(quest_domain.HeritageTask task) {
    if (task.isSystemTask) {
      _artisanTaskError = 'System tasks cannot be edited or deleted.';
      notifyListeners();
      return false;
    }
    if (task.status.toUpperCase() != 'APPROVED' || task.isArchived) {
      _artisanTaskError = 'Only approved active tasks can request changes.';
      notifyListeners();
      return false;
    }
    if (pendingChangeForTask(task.id) != null) {
      _artisanTaskError =
          'This task already has a change request awaiting admin approval.';
      notifyListeners();
      return false;
    }
    return true;
  }

  bool _isUnapprovedCustomTask(quest_domain.HeritageTask task) {
    final status = task.status.toUpperCase();
    return !task.isSystemTask &&
        (status == 'PENDING_APPROVAL' || status == 'REJECTED');
  }

  Future<bool> resubmitRejectedTaskEdit({
    required quest_domain.HeritageTask task,
    required HeritageTaskChangeRequest request,
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    if (_isSubmittingTaskChange ||
        task.isSystemTask ||
        task.status.toUpperCase() != 'APPROVED' ||
        task.isArchived ||
        request.taskId != task.id ||
        request.requestType.toUpperCase() != 'EDIT' ||
        request.status.toUpperCase() != 'REJECTED') {
      return false;
    }

    if (!_validateTaskInput(
      title: title,
      xpReward: xpReward,
      excludingTaskId: task.id,
    )) {
      return false;
    }
    final cleanTitle = _cleanSingleLine(title);

    _isSubmittingTaskChange = true;
    _lastTaskEditReverted = false;
    _artisanTaskError = null;
    notifyListeners();
    try {
      if (_matchesApprovedTask(
        task,
        title: cleanTitle,
        isRequired: isRequired,
        xpReward: xpReward,
      )) {
        await _repository.deleteRejectedHeritageTaskEditRequest(
          requestId: request.id,
          taskId: task.id,
        );
        _artisanTaskChangeRequests = _artisanTaskChangeRequests
            .where((item) => item.id != request.id)
            .toList(growable: false);
        _lastTaskEditReverted = true;
        return true;
      }
      final updatedRequest = await _repository.resubmitRejectedHeritageTaskEdit(
        requestId: request.id,
        taskId: task.id,
        proposedTitle: cleanTitle,
        proposedIsRequired: isRequired,
        proposedXpReward: xpReward,
      );
      _artisanTaskChangeRequests = _artisanTaskChangeRequests
          .map((item) => item.id == updatedRequest.id ? updatedRequest : item)
          .toList(growable: false);
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel resubmit rejected task edit: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The rejected task update could not be resubmitted.',
      );
      return false;
    } finally {
      _isSubmittingTaskChange = false;
      notifyListeners();
    }
  }

  bool _matchesApprovedTask(
    quest_domain.HeritageTask task, {
    required String title,
    required bool isRequired,
    required int xpReward,
  }) {
    return title.trim() == task.title.trim() &&
        isRequired == task.isRequired &&
        xpReward == task.xpReward;
  }

  Future<void> _loadArtisanTaskChangeRequests() async {
    _artisanTaskChangeRequests = await _repository
        .getHeritageTaskChangeRequests(
          _artisanTasks.map((task) => task.id).toList(growable: false),
        );
  }

  void clearArtisanTaskError() {
    _artisanTaskError = null;
    _lastTaskEditReverted = false;
  }

  String _friendlyArtisanTaskError(Object error, {required String fallback}) {
    final message = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
    final lower = message.toLowerCase();

    if (lower.contains('artisan profile') ||
        lower.contains('signed in') ||
        lower.contains('not authorized') ||
        lower.contains('system task') ||
        lower.contains('approved active task') ||
        lower.contains('multiple quests')) {
      return message;
    }
    return fallback;
  }

  void _initializeMockData() {
    _activeTasks = [
      HeritageTask(
        id: '101',
        workshopId: 'w1',
        title: 'Observe Cengal wood selection',
        isCompleted: true,
      ),
      HeritageTask(
        id: '102',
        workshopId: 'w1',
        title: 'Watch the initial carving',
        isCompleted: true,
      ),
      HeritageTask(
        id: '103',
        workshopId: 'w1',
        title: 'Scan Workshop QR Code',
        isCompleted: false,
      ),
      HeritageTask(
        id: '104',
        workshopId: 'w1',
        title: 'Try the carving chisel',
        isCompleted: false,
        isRequired: false,
      ),
    ];
  }

  Future<void> verifyQRCode(String code) async {
    await loadPassport();
  }
}
