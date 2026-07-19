class UserModel {
  final String id;
  final String email;
  final String role; // 'Tourist' or 'Artisan'
  final String? displayName;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
  });

  // TODO: Add fromMap and toMap for Supabase integration
}
