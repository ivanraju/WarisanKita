import 'package:flutter/material.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/artisan_task_request.dart';
import 'package:warisan_kita/domain/models/badge.dart';
import 'package:warisan_kita/domain/models/heritage_task.dart' as quest_domain;
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';
import 'package:warisan_kita/domain/models/quest.dart';

class GamificationViewModel extends ChangeNotifier {
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

  Quest? _artisanQuest;
  Quest? get artisanQuest => _artisanQuest;

  List<quest_domain.HeritageTask> _artisanTasks = [];
  List<quest_domain.HeritageTask> get artisanTasks => _artisanTasks
      .where(
        (task) => task.status.toUpperCase() == 'APPROVED' && !task.isArchived,
      )
      .toList(growable: false);

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
    _initializeMockData();
  }

  int get totalPotentialXp {
    return _heritageTasks.fold(0, (total, task) => total + task.xpReward);
  }

  int get artisanTotalPotentialXp {
    return artisanTasks.fold(0, (total, task) => total + task.xpReward);
  }

  Future<void> loadQuestsForArtisan(String artisanProfileId) async {
    final requestId = ++_loadRequestId;

    _availableQuests = [];
    _selectedQuest = null;
    _heritageTasks = [];
    _questProgressStatus = null;
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
    final requestId = ++_loadRequestId;

    _selectedQuest = quest;
    _heritageTasks = [];
    _questProgressStatus = null;
    _startQuestError = null;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final tasks = await _repository.getHeritageTasks(quest.id);
      String? progressStatus;
      try {
        progressStatus = await _repository.getCurrentQuestProgressStatus(
          quest.id,
        );
      } catch (error, stackTrace) {
        debugPrint('GamificationViewModel load quest progress error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (requestId != _loadRequestId) {
        return;
      }

      _heritageTasks = tasks;
      _questProgressStatus = progressStatus;
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
      return true;
    } catch (error, stackTrace) {
      debugPrint('GamificationViewModel start quest error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _startQuestError = _friendlyStartQuestError(error);
      return false;
    } finally {
      _isStartingQuest = false;
      notifyListeners();
    }
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
      _artisanQuest = await _repository.updateCurrentArtisanQuest(
        questId: quest.id,
        title: cleanTitle,
        description: cleanDescription,
        category: cleanCategory,
      );
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

  HeritageTaskChangeRequest? pendingChangeForTask(String taskId) {
    for (final request in _artisanTaskChangeRequests) {
      if (request.taskId == taskId &&
          request.status.toUpperCase() == 'PENDING_APPROVAL') {
        return request;
      }
    }
    return null;
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
    if (_isUpdatingNewTask || !_isUnapprovedCustomTask(task)) return false;

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
