class UserModel {
  final String id;
  final String email;
  final String role; // 'Tourist' or 'Artisan'
  final String? displayName;
  final String joinedDate;
  final bool isSuspended;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.joinedDate = 'Jan 2026',
    this.isSuspended = false,
  });

  UserModel copyWith({bool? isSuspended}) {
    return UserModel(
      id: id,
      email: email,
      role: role,
      displayName: displayName,
      joinedDate: joinedDate,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }
}
