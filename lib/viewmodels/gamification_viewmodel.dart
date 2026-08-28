import 'dart:async';

import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/artisan_task_request.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart' as quest_domain;
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';
import 'package:warisan_kita/domain/models/quest_change_request.dart';
import 'package:warisan_kita/domain/models/task_progress.dart';

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

  bool _isStartingQuest = false;
  bool get isStartingQuest => _isStartingQuest;

  String? _startQuestError;
  String? get startQuestError => _startQuestError;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _loadRequestId = 0;

  static const int dwellRequiredSeconds = 900;
  Timer? _dwellTimer;
  quest_domain.HeritageTask? _goToWorkshopTask;
  quest_domain.HeritageTask? _stayFifteenMinutesTask;
  final Map<String, TaskProgress> _taskProgress = {};
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
  bool _isQuestBadgeEarned = false;
  bool get isQuestBadgeEarned => _isQuestBadgeEarned;
  bool _hasPendingQuestCompletionCelebration = false;
  bool get hasPendingQuestCompletionCelebration =>
      _hasPendingQuestCompletionCelebration;

  bool get canResumeDwellTracking {
    final dwellTask = _stayFifteenMinutesTask;
    return _questProgressStatus?.toUpperCase() == 'IN_PROGRESS' &&
        _isInsideQuestGeofence &&
        _requiresManualResume &&
        !_isDwellTracking &&
        dwellTask != null &&
        !isTaskCompleted(dwellTask);
  }

  Quest? _artisanQuest;
  Quest? get artisanQuest => _artisanQuest;

  QuestChangeRequest? _pendingArtisanQuestChange;
  QuestChangeRequest? get pendingArtisanQuestChange =>
      _pendingArtisanQuestChange;

  QuestChangeRequest? _rejectedArtisanQuestChange;
  QuestChangeRequest? get rejectedArtisanQuestChange =>
      _rejectedArtisanQuestChange;

  List<quest_domain.HeritageTask> _artisanTasks = [];
  List<quest_domain.HeritageTask> get artisanTasks =>
      _artisanTasks.where((task) => !task.isArchived).toList(growable: false);

  bool _isLoadingArtisanQuest = false;
  bool get isLoadingArtisanQuest => _isLoadingArtisanQuest;

  bool _isAddingTask = false;
  bool get isAddingTask => _isAddingTask;

  bool _isUpdatingArtisanQuest = false;
  bool get isUpdatingArtisanQuest => _isUpdatingArtisanQuest;

  List<HeritageTaskChangeRequest> _artisanTaskChangeRequests = [];
  List<HeritageTaskChangeRequest> get artisanTaskChangeRequests =>
      _artisanTaskChangeRequests;

  bool _isSubmittingTaskChange = false;
  bool get isSubmittingTaskChange => _isSubmittingTaskChange;

  bool _isUpdatingNewTask = false;
  bool get isUpdatingNewTask => _isUpdatingNewTask;

  List<ArtisanTaskRequest> get myRequests {
    final requests = <ArtisanTaskRequest>[
      ..._artisanTasks
          .where(_isUnapprovedCustomTask)
          .map(ArtisanTaskRequest.newTask),
      ..._artisanTaskChangeRequests.map((request) {
        final task = artisanTaskById(request.taskId);
        return task == null
            ? null
            : ArtisanTaskRequest.change(task: task, request: request);
      }).whereType<ArtisanTaskRequest>(),
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

  List<HeritageStamp> _stamps = [];
  List<HeritageStamp> get stamps => _stamps;

  List<HeritageTask> _activeTasks = [];
  List<HeritageTask> get activeTasks => _activeTasks;

  double _rankProgress = 0.65;
  double get rankProgress => _rankProgress;

  final TierStatus _currentTier = TierStatus.apprentice;
  TierStatus get currentTier => _currentTier;

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

      final preserveRunningQuest =
          runningQuestId != null &&
          quests.any((quest) => quest.id == runningQuestId);
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
      String? progressStatus;
      var badgeEarned = false;
      try {
        progressStatus = await _repository.getCurrentQuestProgressStatus(
          quest.id,
        );
        badgeEarned = await _repository.hasEarnedQuestStamp(quest.id);
      } catch (error, stackTrace) {
        debugPrint('GamificationViewModel load quest progress error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (requestId != _loadRequestId) {
        return;
      }

      _heritageTasks = tasks;
      _questProgressStatus = progressStatus;
      _isQuestBadgeEarned = badgeEarned;
      _identifySystemTasks();

      final progress = await _repository.getTaskProgress(
        tasks.map((task) => task.id).toList(growable: false),
      );
      if (requestId != _loadRequestId) return;
      for (final item in progress) {
        _taskProgress[item.taskId] = item;
      }

      final dwellTask = _stayFifteenMinutesTask;
      final dwellProgress = dwellTask == null
          ? null
          : _taskProgress[dwellTask.id];
      if (dwellTask != null &&
          dwellProgress != null &&
          !dwellProgress.isCompleted &&
          dwellProgress.trackingStartedAt != null) {
        final paused = await _repository.pauseTimedTask(
          taskId: dwellTask.id,
          progressSeconds: dwellProgress.progressSeconds,
        );
        if (requestId != _loadRequestId) return;
        _taskProgress[dwellTask.id] = paused;
      }
      _syncDisplayedDwellProgress();
      _requiresManualResume =
          progressStatus?.toUpperCase() == 'IN_PROGRESS' &&
          dwellTask != null &&
          !(dwellProgress?.isCompleted ?? false);
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

  Future<bool> startSelectedQuest() async {
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

    _isStartingQuest = true;
    _startQuestError = null;
    notifyListeners();
    try {
      _questProgressStatus = await _repository.startQuest(
        questId: quest.id,
        taskIds: _heritageTasks.map((task) => task.id).toList(growable: false),
      );
      _identifySystemTasks();
      final arrivalTask = _goToWorkshopTask;
      final dwellTask = _stayFifteenMinutesTask;
      if (arrivalTask == null || dwellTask == null) {
        throw StateError(
          'The two required system activities are not configured correctly.',
        );
      }

      _isInsideQuestGeofence = true;
      _taskProgress[arrivalTask.id] = await _repository.completeTask(
        arrivalTask.id,
      );
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
    return _heritageTasks.isNotEmpty && _heritageTasks.every(isTaskCompleted);
  }

  bool get areAllRequiredHeritageTasksCompleted {
    final requiredTasks = _heritageTasks
        .where((task) => task.isRequired)
        .toList(growable: false);
    return requiredTasks.isNotEmpty && requiredTasks.every(isTaskCompleted);
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
    _cancelDwellTimer();
  }

  bool isStayFifteenMinutesTask(quest_domain.HeritageTask task) {
    return task.isSystemTask && task.sortOrder == 2;
  }

  bool canVerifyTaskWithQr(quest_domain.HeritageTask task) {
    if (task.isSystemTask) return false;
    if (_questProgressStatus?.toUpperCase() != 'IN_PROGRESS' ||
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
    if (_questProgressStatus?.toUpperCase() != 'IN_PROGRESS') {
      return 'Start Quest to Scan';
    }
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
      _taskProgress[task.id] = await _repository.completeTaskWithArtisanQr(
        questId: quest.id,
        artisanId: quest.artisanId,
        taskId: task.id,
        qrPayload: qrPayload,
      );
      if (areAllRequiredHeritageTasksCompleted) {
        _markQuestBadgeEarned();
      }
      if (areAllHeritageTasksCompleted) {
        _markQuestFullyCompleted();
      }
      notifyListeners();
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

  Future<bool> resumeSelectedQuest() async {
    if (!canResumeDwellTracking || _isStartingQuest) return false;
    final dwellTask = _stayFifteenMinutesTask!;

    _isStartingQuest = true;
    _startQuestError = null;
    notifyListeners();
    try {
      final progress = await _repository.startTimedTask(dwellTask.id);
      _taskProgress[dwellTask.id] = progress;
      _requiresManualResume = false;
      _beginLocalDwellTimer(progress);
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

    final dwellTask = _stayFifteenMinutesTask;

    if (isInside) {
      _isInsideQuestGeofence = true;
      notifyListeners();
      return;
    }

    _isInsideQuestGeofence = false;
    if (dwellTask != null && !isTaskCompleted(dwellTask)) {
      _requiresManualResume = true;
    }
    await _pauseDwellTracking();
    notifyListeners();
  }

  Future<void> pauseDwellTrackingForInterruption() async {
    await handleQuestProximityChanged(false);
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
    if (progress.isCompleted || progress.trackingStartedAt == null) return;

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
    if (!progress.isCompleted && _isDwellTracking && startedAt != null) {
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
    if (dwellTask == null || isTaskCompleted(dwellTask)) return;

    _isCompletingDwellTask = true;
    _cancelDwellTimer();
    try {
      _taskProgress[dwellTask.id] = await _repository.completeTimedTask(
        dwellTask.id,
      );
      _displayedDwellSeconds = dwellRequiredSeconds;
      if (areAllRequiredHeritageTasksCompleted) {
        _markQuestBadgeEarned();
      }
      if (areAllHeritageTasksCompleted) {
        _markQuestFullyCompleted();
      }
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel complete dwell error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _startQuestError = 'Unable to complete the workshop timer right now.';
    } finally {
      _isCompletingDwellTask = false;
      notifyListeners();
    }
  }

  void _identifySystemTasks() {
    _goToWorkshopTask = _systemTaskAtSortOrder(1);
    _stayFifteenMinutesTask = _systemTaskAtSortOrder(2);
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
    _taskProgress.clear();
    _isInsideQuestGeofence = false;
    _displayedDwellSeconds = 0;
    _pendingProximity = null;
    _requiresManualResume = false;
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
    _pendingArtisanQuestChange = null;
    _rejectedArtisanQuestChange = null;
    _artisanTaskChangeRequests = [];
    _artisanTaskError = null;
    _isLoadingArtisanQuest = true;
    notifyListeners();

    try {
      final quest = await _repository.getQuestForCurrentArtisan();
      _artisanQuest = quest;
      if (quest != null) {
        await _loadArtisanQuestChangeRequest(quest.id);
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

  Future<bool> addHeritageTask({
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    if (_isAddingTask) return false;

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      _artisanTaskError = 'Task title must not be empty.';
      notifyListeners();
      return false;
    }
    if (xpReward < 0) {
      _artisanTaskError = 'XP reward must be 0 or more.';
      notifyListeners();
      return false;
    }

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
      await _repository.addHeritageTask(
        questId: quest.id,
        title: cleanTitle,
        isRequired: isRequired,
        xpReward: xpReward,
        sortOrder: highestSortOrder + 1,
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

  Future<bool> updateArtisanQuest({
    required String title,
    required String description,
    required String category,
  }) async {
    if (_isUpdatingArtisanQuest) return false;

    final quest = _artisanQuest;
    if (quest == null) {
      _artisanTaskError = 'No cultural quest is assigned to this artisan.';
      notifyListeners();
      return false;
    }

    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanCategory = category.trim();
    if (cleanTitle.isEmpty ||
        cleanDescription.isEmpty ||
        cleanCategory.isEmpty) {
      _artisanTaskError =
          'Quest title, description, and category are required.';
      notifyListeners();
      return false;
    }

    _artisanTaskError = null;
    _isUpdatingArtisanQuest = true;
    notifyListeners();

    try {
      _pendingArtisanQuestChange = await _repository.requestQuestUpdate(
        questId: quest.id,
        proposedTitle: cleanTitle,
        proposedDescription: cleanDescription,
        proposedCategory: cleanCategory,
      );
      _rejectedArtisanQuestChange = null;
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel update artisan quest error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The cultural quest could not be updated. Please try again.',
      );
      return false;
    } finally {
      _isUpdatingArtisanQuest = false;
      notifyListeners();
    }
  }

  Future<void> _loadArtisanQuestChangeRequest(String questId) async {
    final requests = await _repository.getQuestChangeRequests(questId);
    final latestRequest = requests.firstOrNull;
    _pendingArtisanQuestChange = latestRequest?.isPending == true
        ? latestRequest
        : null;
    _rejectedArtisanQuestChange =
        latestRequest?.status.toUpperCase() == 'REJECTED'
        ? latestRequest
        : null;
  }

  Future<bool> resubmitRejectedQuestUpdate({
    required QuestChangeRequest request,
    required String title,
    required String description,
    required String category,
  }) async {
    if (_isUpdatingArtisanQuest || request.status.toUpperCase() != 'REJECTED') {
      return false;
    }

    final quest = _artisanQuest;
    if (quest == null || request.questId != quest.id) return false;

    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanCategory = category.trim();
    if (cleanTitle.isEmpty ||
        cleanDescription.isEmpty ||
        cleanCategory.isEmpty) {
      _artisanTaskError =
          'Quest title, description, and category are required.';
      notifyListeners();
      return false;
    }

    _isUpdatingArtisanQuest = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      _pendingArtisanQuestChange = await _repository
          .resubmitRejectedQuestUpdate(
            requestId: request.id,
            questId: quest.id,
            proposedTitle: cleanTitle,
            proposedDescription: cleanDescription,
            proposedCategory: cleanCategory,
          );
      _rejectedArtisanQuestChange = null;
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel resubmit rejected quest: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The rejected quest update could not be resubmitted.',
      );
      return false;
    } finally {
      _isUpdatingArtisanQuest = false;
      notifyListeners();
    }
  }

  Future<bool> dismissRejectedQuestUpdate(QuestChangeRequest request) async {
    if (_isUpdatingArtisanQuest || request.status.toUpperCase() != 'REJECTED') {
      return false;
    }

    final quest = _artisanQuest;
    if (quest == null || request.questId != quest.id) return false;

    _isUpdatingArtisanQuest = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      await _repository.deleteRejectedQuestUpdate(
        requestId: request.id,
        questId: quest.id,
      );
      _rejectedArtisanQuestChange = null;
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel dismiss rejected quest: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The rejected quest update could not be dismissed.',
      );
      return false;
    } finally {
      _isUpdatingArtisanQuest = false;
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

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || xpReward < 0) {
      _artisanTaskError = cleanTitle.isEmpty
          ? 'Task title must not be empty.'
          : 'XP reward must be 0 or more.';
      notifyListeners();
      return false;
    }

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
    if (_isUpdatingNewTask || !_isRejectedCustomTask(task)) return false;

    _isUpdatingNewTask = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      await _repository.deleteUnapprovedHeritageTask(task.id);
      _artisanTasks = _artisanTasks
          .where((item) => item.id != task.id)
          .toList(growable: false);
      _artisanTaskChangeRequests = _artisanTaskChangeRequests
          .where((request) => request.taskId != task.id)
          .toList(growable: false);
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel cancel new task error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The task submission could not be cancelled.',
      );
      return false;
    } finally {
      _isUpdatingNewTask = false;
      notifyListeners();
    }
  }

  Future<bool> dismissRejectedTaskEdit(
    HeritageTaskChangeRequest request,
  ) async {
    if (_isSubmittingTaskChange ||
        request.requestType.toUpperCase() != 'EDIT' ||
        request.status.toUpperCase() != 'REJECTED') {
      return false;
    }

    _isSubmittingTaskChange = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
      await _repository.deleteRejectedHeritageTaskEditRequest(request.id);
      _artisanTaskChangeRequests = _artisanTaskChangeRequests
          .where((item) => item.id != request.id)
          .toList(growable: false);
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel dismiss rejected task edit: $error');
      debugPrintStack(stackTrace: stackTrace);
      _artisanTaskError = _friendlyArtisanTaskError(
        error,
        fallback: 'The rejected task update could not be dismissed.',
      );
      return false;
    } finally {
      _isSubmittingTaskChange = false;
      notifyListeners();
    }
  }

  Future<bool> requestHeritageTaskEdit({
    required quest_domain.HeritageTask task,
    required String title,
    required bool isRequired,
    required int xpReward,
  }) async {
    if (_isSubmittingTaskChange) return false;
    if (!_canRequestTaskChange(task)) return false;

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      _artisanTaskError = 'Task title must not be empty.';
      notifyListeners();
      return false;
    }
    if (xpReward < 0) {
      _artisanTaskError = 'XP reward must be 0 or more.';
      notifyListeners();
      return false;
    }

    _isSubmittingTaskChange = true;
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

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || xpReward < 0) {
      _artisanTaskError = cleanTitle.isEmpty
          ? 'Task title must not be empty.'
          : 'XP reward must be 0 or more.';
      notifyListeners();
      return false;
    }

    _isSubmittingTaskChange = true;
    _artisanTaskError = null;
    notifyListeners();
    try {
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

  bool _isRejectedCustomTask(quest_domain.HeritageTask task) {
    return !task.isSystemTask && task.status.toUpperCase() == 'REJECTED';
  }

  Future<void> _loadArtisanTaskChangeRequests() async {
    _artisanTaskChangeRequests = await _repository
        .getHeritageTaskChangeRequests(
          _artisanTasks.map((task) => task.id).toList(growable: false),
        );
  }

  void clearArtisanTaskError() {
    _artisanTaskError = null;
  }

  String _friendlyArtisanTaskError(Object error, {required String fallback}) {
    final message = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
    final lower = message.toLowerCase();

    if (lower.contains('artisan profile') ||
        lower.contains('signed in') ||
        lower.contains('multiple quests')) {
      return message;
    }
    return fallback;
  }

  void _initializeMockData() {
    _stamps = [
      HeritageStamp(
        id: '1',
        title: 'Batik Master',
        iconUrl:
            'https://images.unsplash.com/photo-1590739225287-bd31519780c3?w=200',
        isUnlocked: true,
      ),
      HeritageStamp(
        id: '2',
        title: 'Songket Weaver',
        iconUrl:
            'https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=200',
        isUnlocked: true,
      ),
      HeritageStamp(
        id: '3',
        title: 'Wood Carver',
        iconUrl:
            'https://images.unsplash.com/photo-1605721911519-3dfeb3be25e7?w=200',
        isUnlocked: true,
      ),
      HeritageStamp(
        id: '4',
        title: 'Metal Smith',
        iconUrl:
            'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?w=200',
        isUnlocked: true,
      ),
      HeritageStamp(
        id: '5',
        title: 'Wau Maker',
        iconUrl:
            'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=200',
        isUnlocked: false,
      ),
      HeritageStamp(
        id: '6',
        title: 'Pottery Artist',
        iconUrl:
            'https://images.unsplash.com/photo-1565193998771-e64b81bd957d?w=200',
        isUnlocked: false,
      ),
    ];

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
    await Future.delayed(const Duration(seconds: 1));
    for (int i = 0; i < _stamps.length; i++) {
      if (!_stamps[i].isUnlocked) {
        _stamps[i] = HeritageStamp(
          id: _stamps[i].id,
          title: _stamps[i].title,
          iconUrl: _stamps[i].iconUrl,
          isUnlocked: true,
        );
        break;
      }
    }
    _rankProgress = 0.85;
    notifyListeners();
  }
}
