import 'package:flutter/foundation.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/domain/models/gamification_moderation_request.dart';

enum GamificationModerationFilter { all, newTasks, taskChanges, deleteRequests }

class GamificationModerationViewModel extends ChangeNotifier {
  final GamificationRepository _repository;

  GamificationModerationViewModel({required GamificationRepository repository})
    : _repository = repository;

  List<GamificationModerationRequest> _requests = [];
  List<GamificationModerationRequest> get requests =>
      List.unmodifiable(_requests);

  GamificationModerationFilter _filter = GamificationModerationFilter.all;
  GamificationModerationFilter get filter => _filter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _reviewingRequestId;
  bool isReviewing(String requestId) => _reviewingRequestId == requestId;

  int get newTaskCount => _requests.where((item) => item.isNewTask).length;
  int get taskChangeCount => _requests
      .where((item) => item.isTaskChange && !item.isDeleteRequest)
      .length;
  int get deleteRequestCount =>
      _requests.where((item) => item.isDeleteRequest).length;
  int get totalCount => newTaskCount + taskChangeCount + deleteRequestCount;

  List<GamificationModerationRequest> get filteredRequests {
    return switch (_filter) {
      GamificationModerationFilter.all => requests,
      GamificationModerationFilter.newTasks =>
        requests.where((item) => item.isNewTask).toList(growable: false),
      GamificationModerationFilter.taskChanges =>
        requests
            .where((item) => item.isTaskChange && !item.isDeleteRequest)
            .toList(growable: false),
      GamificationModerationFilter.deleteRequests =>
        requests.where((item) => item.isDeleteRequest).toList(growable: false),
    };
  }

  void setFilter(GamificationModerationFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<void> loadRequests() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _requests = await _repository.getPendingGamificationModerationRequests();
    } catch (error, stackTrace) {
      debugPrint('Gamification moderation load error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyError(
        error,
        fallback: 'Unable to load gamification moderation requests.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reviewRequest(
    GamificationModerationRequest request, {
    required bool approve,
    String? rejectionReason,
  }) async {
    if (_reviewingRequestId != null) return false;
    if (!approve &&
        (rejectionReason == null || rejectionReason.trim().isEmpty)) {
      _error = 'Enter a reason before rejecting this request.';
      notifyListeners();
      return false;
    }

    _reviewingRequestId = request.id;
    _error = null;
    notifyListeners();
    try {
      switch (request.type) {
        case GamificationModerationRequestType.newTask:
          await _repository.reviewNewHeritageTask(
            taskId: request.id,
            approve: approve,
            rejectionReason: rejectionReason,
          );
        case GamificationModerationRequestType.taskChange:
          await _repository.reviewHeritageTaskChange(
            requestId: request.id,
            approve: approve,
            rejectionReason: rejectionReason,
          );
      }
      _requests = _requests
          .where((item) => item.id != request.id)
          .toList(growable: false);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Gamification moderation review error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = _friendlyError(
        error,
        fallback: 'The moderation decision could not be saved.',
      );
      return false;
    } finally {
      _reviewingRequestId = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _friendlyError(Object error, {required String fallback}) {
    final message = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
    final lower = message.toLowerCase();
    if (lower.contains('pgrst116') ||
        lower.contains('cannot coerce the result to a single json object')) {
      return 'This request is no longer pending. Refresh to load the latest moderation queue.';
    }
    if (lower.contains('postgrestexception')) return fallback;
    return message.isEmpty ? fallback : message;
  }
}
