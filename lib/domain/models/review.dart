/// A visitor's feedback for an artisan or workshop.
class Review {
  final String id;
  final String artisanId;
  final String authorId;
  final String comment;
  final double rating;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.artisanId,
    required this.authorId,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });
}
