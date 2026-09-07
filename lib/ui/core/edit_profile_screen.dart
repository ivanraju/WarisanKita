import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _studioNameController;
  String _selectedCraftCategory = 'Pottery & Ceramics';
  String _selectedState = 'Melaka';
  bool _isUploadingAvatar = false;

  final List<String> _craftCategories = const [
    'Pottery & Ceramics',
    'Batik Weaving',
    'Wood Carving',
    'Songket Weaving',
    'Pewter Craft',
    'Handicraft & Heritage',
  ];

  final List<String> _malaysianStates = const [
    'Melaka',
    'Terengganu',
    'Kelantan',
    'Perak',
    'Selangor',
    'Johor',
    'Penang',
    'Kedah',
    'Pahang',
    'Sabah',
    'Sarawak',
    'Kuala Lumpur',
  ];

  @override
  void initState() {
    super.initState();
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    final initialFullName = user?.displayName ?? user?.effectiveUsername ?? 'Aiman Haziq';
    final initialUsername = (user?.username ?? user?.effectiveUsername ?? 'aiman_haziq').replaceAll('@', '');
    _fullNameController = TextEditingController(text: initialFullName);
    _usernameController = TextEditingController(text: initialUsername);
    _phoneController = TextEditingController(text: user?.phone ?? '+60 12-345 6789');
    _bioController = TextEditingController(text: user?.bio ?? 'Passionate Malaysian cultural explorer and craft preserver.');
    _studioNameController = TextEditingController(text: user?.studioName ?? user?.displayName ?? 'Warisan Craft Studio');

    if (user?.craftCategory != null && _craftCategories.contains(user!.craftCategory)) {
      _selectedCraftCategory = user.craftCategory!;
    }
    if (user?.state != null && _malaysianStates.contains(user!.state)) {
      _selectedState = user.state!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _studioNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isNotEmpty) {
        final file = files.first;
        setState(() => _isUploadingAvatar = true);
        final authVM = context.read<AuthViewModel>();
        final url = await authVM.uploadAvatar(file);
        if (!mounted) return;
        setState(() => _isUploadingAvatar = false);

        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile avatar updated successfully!'),
              backgroundColor: Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile avatar.'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avatar selection failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim().replaceAll('@', '');
    final phone = _phoneController.text.trim();
    final bio = _bioController.text.trim();
    final studioName = _studioNameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty!'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    final isDualOrArtisan = user?.isDualRole == true || user?.isArtisan == true || (user?.role.toLowerCase().contains('artisan') ?? false);

    final finalStudioName = isDualOrArtisan
        ? (studioName.isNotEmpty ? studioName : (fullName.isNotEmpty ? fullName : username))
        : null;

    try {
      await authVM.updateProfile(
        username: username,
        displayName: fullName.isNotEmpty ? fullName : username,
        phone: phone,
        bio: bio,
        studioName: finalStudioName,
        craftCategory: isDualOrArtisan ? _selectedCraftCategory : null,
        state: isDualOrArtisan ? _selectedState : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final moderationVM = context.read<ModerationViewModel>();
      if (user?.email != null) {
        moderationVM.updateUserProfileInState(
          email: user!.email,
          username: username,
          displayName: fullName.isNotEmpty ? fullName : username,
          studioName: finalStudioName,
          craftCategory: isDualOrArtisan ? _selectedCraftCategory : null,
          state: isDualOrArtisan ? _selectedState : null,
          phone: phone,
          bio: bio,
        );
      }
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDualOrArtisan
              ? 'Tourist Profile & Artisan Studio synced successfully!'
              : 'Explorer profile updated successfully!',
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final initials = user?.initials ?? 'AH';
    final isDual = user?.isDualRole ?? false || user?.role == 'Artisan';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.dmSerifDisplay(
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            fontSize: 22,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D2825) : Colors.white,
            border: isDark ? const Border(top: BorderSide(color: Color(0xFF1E3A34))) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
              foregroundColor: isDark ? const Color(0xFFFFD54F) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'SAVE & SYNC PROFILE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Avatar Image Picker
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: isDark
                          ? const Color(0xFF1E3A34)
                          : const Color(0xFF004D40).withValues(alpha: 0.1),
                      backgroundImage: user?.avatarImageProvider,
                      child: _isUploadingAvatar
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              ),
                            )
                          : (user?.avatarImageProvider != null
                              ? null
                              : Text(
                                  initials,
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 32,
                                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                Icons.camera_alt_rounded,
                                color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'PERSONAL EXPLORER INFORMATION',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Full Name Input Field
            TextField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g. Siti Nurhaliza',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 16),

            // Unique Username Handle Input Field
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Unique Username Handle',
                hintText: 'e.g. siticrafts',
                prefixText: '@',
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 16),

            // Phone Number Input Field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: isDark ? const Color(0xFFFFD54F) : null,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 16),

            // Bio / Explorer Note Field
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Heritage Bio / Explorer Note',
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: isDark ? const Color(0xFFFFD54F) : null,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            if (isDual) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.6 : 1.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DUAL ROLE SYNC: ARTISAN STUDIO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Changes here update your public Artisan Studio profile across the platform.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Studio Name Input
                    TextField(
                      controller: _studioNameController,
                      decoration: InputDecoration(
                        labelText: 'Artisan Studio Name',
                        prefixIcon: Icon(
                          Icons.storefront_outlined,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Craft Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCraftCategory,
                      dropdownColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Craft Specialization',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: _craftCategories.map((craft) {
                        return DropdownMenuItem<String>(
                          value: craft,
                          child: Text(craft, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCraftCategory = val);
                      },
                    ),

                    const SizedBox(height: 14),

                    // State / Region Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      dropdownColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Studio State / Location',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: _malaysianStates.map((st) {
                        return DropdownMenuItem<String>(
                          value: st,
                          child: Text(st, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedState = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

