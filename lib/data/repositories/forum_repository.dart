import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/forum_post.dart';

class ForumRepository {
  final SupabaseService _service;

  ForumRepository({SupabaseService? service}) : _service = service ?? SupabaseService();

  Future<List<ForumThread>> getThreads() => _service.fetchThreads();

  Future<void> createThread(ForumThread thread) => _service.createThread(thread);

  Future<void> postReply(String threadId, ThreadReply reply) => _service.postReply(threadId, reply);

  Future<void> voteThread(String threadId, int voteDirection) => _service.voteThread(threadId, voteDirection);

  Future<void> voteReply(String threadId, String replyId, int voteDirection) => _service.voteReply(threadId, replyId, voteDirection);

  Future<void> editThread(String threadId, String newTitle) => _service.editThread(threadId, newTitle);

  Future<void> deleteThread(String threadId) => _service.deleteThread(threadId);

  Future<void> editReply(String threadId, String replyId, String newText) => _service.editReply(threadId, replyId, newText);

  Future<void> deleteReply(String threadId, String replyId) => _service.deleteReply(threadId, replyId);

  Future<Map<String, dynamic>> reportThread(
      String threadId,
      String reason,
      String notes,
      ) async {
    return await _service.reportThread(
      threadId,
      reason,
      notes,
    );
  }

  Future<String> adminDeleteForumPost(
      String postId,
      String deletionReason,
      ) async {
    return await _service.adminDeleteForumPost(
      postId,
      deletionReason,
    );
  }

  Future<String> adminDeleteForumReply(
      String threadId,
      String replyId,
      String deletionReason,
      ) async {
    return await _service.adminDeleteForumReply(
      threadId,
      replyId,
      deletionReason,
    );
  }

  Future<List<Map<String, dynamic>>> fetchForumReportQueue() {
    return _service.fetchForumReportQueue();
  }

  Future<List<Map<String, dynamic>>> fetchForumModerationHistory() async {
    return await _service.fetchForumModerationHistory();
  }

  Future<Map<String, dynamic>> reportReply(
      String threadId,
      String replyId,
      String reason,
      String notes,
      ) async {
    return await _service.reportReply(
      threadId,
      replyId,
      reason,
      notes,
    );
  }

  Future<void> dismissReplyReport(
      String threadId,
      String replyId,
      ) =>
      _service.dismissReplyReport(
        threadId,
        replyId,
      );

  Future<void> dismissReport(String threadId) => _service.dismissReport(threadId);

  Future<void> dismissModerationNotice(String reportId) =>
      _service.dismissModerationNotice(reportId);
}
