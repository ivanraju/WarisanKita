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
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _studioNameController;
  String _selectedCraftCategory = 'Pottery & Ceramics';
  String _selectedState = 'Melaka';

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
    _nameController = TextEditingController(text: user?.effectiveUsername ?? 'Aiman Haziq');
    _phoneController = TextEditingController(text: user?.phone ?? '+60 12-345 6789');
    _bioController = TextEditingController(text: user?.bio ?? 'Passionate Malaysian cultural explorer and craft preserver.');
    _studioNameController = TextEditingController(text: user?.studioName ?? 'Warisan Craft Studio');

    if (user?.craftCategory != null && _craftCategories.contains(user!.craftCategory)) {
      _selectedCraftCategory = user.craftCategory!;
    }
    if (user?.state != null && _malaysianStates.contains(user!.state)) {
      _selectedState = user.state!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _studioNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final bio = _bioController.text.trim();
    final studioName = _studioNameController.text.trim();

    if (name.isEmpty) {
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
        ? (studioName.isNotEmpty ? studioName : name)
        : null;

    try {
      await authVM.updateProfile(
        username: name,
        displayName: name,
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
          username: name,
          displayName: name,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40), fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF004D40)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: FilledButton(
            onPressed: _handleSave,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

            // Avatar Placeholder Image Picker
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFF004D40).withValues(alpha: 0.1),
                    child: Text(
                      initials,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 32,
                        color: const Color(0xFF004D40),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF004D40),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
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
                color: const Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Full Name / Username Input Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Username / Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
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
                prefixIcon: const Icon(Icons.phone_outlined),
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
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            if (isDual) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: Color(0xFFB45309), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'DUAL ROLE SYNC: ARTISAN STUDIO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
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
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Studio Name Input
                    TextField(
                      controller: _studioNameController,
                      decoration: InputDecoration(
                        labelText: 'Artisan Studio Name',
                        prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xFFB45309)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Craft Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCraftCategory,
                      decoration: InputDecoration(
                        labelText: 'Craft Specialization',
                        prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFFB45309)),
                        filled: true,
                        fillColor: Colors.white,
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
                      decoration: InputDecoration(
                        labelText: 'Studio State / Location',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFFB45309)),
                        filled: true,
                        fillColor: Colors.white,
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

