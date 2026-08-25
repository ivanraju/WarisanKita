import 'package:warisan_kita/domain/models/heritage_task.dart';
import 'package:warisan_kita/domain/models/heritage_task_change_request.dart';

enum ArtisanTaskRequestType { newTask, edit, delete }

class ArtisanTaskRequest {
  final ArtisanTaskRequestType type;
  final HeritageTask task;
  final HeritageTaskChangeRequest? changeRequest;

  const ArtisanTaskRequest._({
    required this.type,
    required this.task,
    required this.changeRequest,
  });

  factory ArtisanTaskRequest.newTask(HeritageTask task) {
    return ArtisanTaskRequest._(
      type: ArtisanTaskRequestType.newTask,
      task: task,
      changeRequest: null,
    );
  }

  factory ArtisanTaskRequest.change({
    required HeritageTask task,
    required HeritageTaskChangeRequest request,
  }) {
    return ArtisanTaskRequest._(
      type: request.requestType.toUpperCase() == 'DELETE'
          ? ArtisanTaskRequestType.delete
          : ArtisanTaskRequestType.edit,
      task: task,
      changeRequest: request,
    );
  }

  String get id => changeRequest?.id ?? task.id;
  String get status => changeRequest?.status ?? task.status;
  String? get rejectionReason =>
      changeRequest?.rejectionReason ?? task.rejectionReason;
  DateTime? get submittedAt => changeRequest?.submittedAt ?? task.createdAt;
}
