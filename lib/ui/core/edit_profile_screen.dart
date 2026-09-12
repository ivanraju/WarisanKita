import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _studioNameController;
  String _selectedCraftCategory = 'Pottery & Ceramics';
  String _selectedState = 'Melaka';
  bool _isUploadingAvatar = false;

  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameStatusMessage;
  Timer? _usernameDebounce;
  String? _initialUsername;

  late final List<String> _craftCategories = [
    'Pottery & Ceramics',
    'Batik Weaving',
    'Wood Carving',
    'Songket Weaving',
    'Pewter Craft',
    'Handicraft & Heritage',
    'Woodwork',
    'Songket & Weaving',
    'Batik & Textiles',
    'Metalwork & Pewter',
    'Heritage Food',
    'Wayang Kulit & Puppetry',
    'Rattan & Bamboo Craft',
    'Wau & Kite Making',
    'Metalwork & Kris',
  ];

  late final List<String> _malaysianStates = List<String>.from(
    ProfileValidator.supportedStates,
  );

  @override
  void initState() {
    super.initState();
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    final initialFullName = user?.displayName ?? user?.effectiveUsername ?? '';
    final initialUsername =
        (user?.username ?? user?.effectiveUsername ?? user?.handle ?? '')
            .replaceAll('@', '');
    _initialUsername = initialUsername;
    _fullNameController = TextEditingController(text: initialFullName);
    _usernameController = TextEditingController(text: initialUsername);
    _usernameController.addListener(_onUsernameChanged);
    _bioController = TextEditingController(text: user?.bio ?? '');
    _studioNameController = TextEditingController(
      text: user?.studioName ?? user?.displayName ?? '',
    );

    if (user?.craftCategory != null && user!.craftCategory!.trim().isNotEmpty) {
      final craft = user.craftCategory!.trim();
      if (!_craftCategories.contains(craft)) {
        _craftCategories.add(craft);
      }
      _selectedCraftCategory = craft;
    }
    if (user?.state != null && user!.state!.trim().isNotEmpty) {
      final st = user.state!.trim();
      if (!_malaysianStates.contains(st)) {
        _malaysianStates.add(st);
      }
      _selectedState = st;
    }
  }

  void _onUsernameChanged() {
    _usernameDebounce?.cancel();
    final raw = _usernameController.text.trim().replaceAll('@', '');
    if (raw.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameStatusMessage = null;
      });
      return;
    }

    final validationError = ProfileValidator.validateUsername(raw);
    if (validationError != null) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameStatusMessage = validationError;
      });
      return;
    }

    if (raw.toLowerCase() == _initialUsername?.toLowerCase()) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = true;
        _usernameStatusMessage = '@$raw is your current handle';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 300), () async {
      final authVM = context.read<AuthViewModel>();
      final isAvailable = await authVM.isUsernameAvailable(
        raw,
        excludeEmail: authVM.currentUser?.email,
      );
      if (!mounted) return;
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = isAvailable;
        _usernameStatusMessage = isAvailable
            ? '@$raw is available'
            : '@$raw is already taken';
      });
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _studioNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (!mounted) return;
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please correct the highlighted form errors before saving.',
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _usernameStatusMessage ?? 'Username handle is already taken',
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim().replaceAll('@', '');
    final bio = _bioController.text.trim();
    final studioName = _studioNameController.text.trim();

    final authVM = context.read<AuthViewModel>();

    if (username.isNotEmpty &&
        username.toLowerCase() != _initialUsername?.toLowerCase()) {
      final isAvailable = await authVM.isUsernameAvailable(
        username,
        excludeEmail: authVM.currentUser?.email,
      );
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '@$username is already taken. Please choose another username handle.',
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    final user = authVM.currentUser;
    final phone = user?.phone;
    final isArtisan =
        user?.isArtisan == true ||
        (user?.role.toLowerCase().contains('artisan') ?? false);

    final finalStudioName = isArtisan
        ? (studioName.isNotEmpty
              ? studioName
              : (fullName.isNotEmpty ? fullName : username))
        : null;

    try {
      await authVM.updateProfile(
        username: username,
        displayName: fullName.isNotEmpty ? fullName : username,
        phone: phone,
        bio: bio,
        studioName: finalStudioName,
        craftCategory: isArtisan ? _selectedCraftCategory : null,
        state: isArtisan ? _selectedState : null,
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

    if (!mounted) return;
    try {
      final moderationVM = context.read<ModerationViewModel>();
      if (user?.email != null) {
        moderationVM.updateUserProfileInState(
          email: user!.email,
          username: username,
          displayName: fullName.isNotEmpty ? fullName : username,
          studioName: finalStudioName,
          craftCategory: isArtisan ? _selectedCraftCategory : null,
          state: isArtisan ? _selectedState : null,
          phone: phone,
          bio: bio,
        );
      }
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArtisan
              ? 'Artisan Studio profile synced successfully!'
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
    LanguageViewModel? langVM;
    try {
      langVM = context.watch<LanguageViewModel>();
    } catch (_) {}
    String tr(String text) => langVM?.translate(text) ?? text;

    final user = authVM.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return HeritageBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              tr('Edit Profile'),
              style: GoogleFonts.dmSerifDisplay(
                color: isDark
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFF004D40),
                fontSize: 22,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final initials = user.initials;
    final isArtisan =
        user.isArtisan ||
        user.role == 'Artisan' ||
        user.role.toLowerCase().contains('artisan');

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            tr('Edit Profile'),
            style: GoogleFonts.dmSerifDisplay(
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.transparent,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D2825) : Colors.white,
              border: isDark
                  ? const Border(top: BorderSide(color: Color(0xFF1E3A34)))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1E3A34)
                    : const Color(0xFF004D40),
                foregroundColor: isDark
                    ? const Color(0xFFFFD54F)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                tr('SAVE & SYNC PROFILE'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          onTap: _isUploadingAvatar
                              ? null
                              : _pickAndUploadAvatar,
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: isDark
                                ? const Color(0xFF1E3A34)
                                : const Color(
                                    0xFF004D40,
                                  ).withValues(alpha: 0.1),
                            backgroundImage: user.avatarImageProvider,
                            child: _isUploadingAvatar
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark
                                          ? const Color(0xFFFFD54F)
                                          : const Color(0xFF004D40),
                                    ),
                                  )
                                : (user.avatarImageProvider != null
                                      ? null
                                      : Text(
                                          initials,
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 32,
                                            color: isDark
                                                ? const Color(0xFFFFD54F)
                                                : const Color(0xFF004D40),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingAvatar
                                ? null
                                : _pickAndUploadAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E3A34)
                                    : const Color(0xFF004D40),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: _isUploadingAvatar
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt_rounded,
                                      color: isDark
                                          ? const Color(0xFFFFD54F)
                                          : Colors.white,
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
                    tr('PERSONAL EXPLORER INFORMATION'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Full Name Input Field
                  TextFormField(
                    controller: _fullNameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: ProfileValidator.validateFullName,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: tr('Full Name'),
                      hintText: 'e.g. Siti Nurhaliza',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        color: isDark
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF004D40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Unique Username Handle Input Field
                  TextFormField(
                    controller: _usernameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: ProfileValidator.validateUsername,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: tr('Unique Username Handle'),
                      hintText: 'e.g. siticrafts',
                      prefixText: '@',
                      helperText: _usernameStatusMessage,
                      helperStyle: TextStyle(
                        color: _isUsernameAvailable == true
                            ? const Color(0xFF10B981)
                            : (_isUsernameAvailable == false
                                  ? const Color(0xFFEF4444)
                                  : null),
                        fontSize: 11,
                      ),
                      suffixIcon: _isCheckingUsername
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : (_isUsernameAvailable != null
                                ? Icon(
                                    _isUsernameAvailable!
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: _isUsernameAvailable!
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  )
                                : null),
                      prefixIcon: Icon(
                        Icons.alternate_email_rounded,
                        color: isDark
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF004D40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bio / Explorer Note Field
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => ProfileValidator.validateBio(
                      v,
                      isRequired: false,
                      minLength: 10,
                      maxLength: 500,
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: tr('Heritage Bio / Explorer Note'),
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: isDark ? const Color(0xFFFFD54F) : null,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.keyboard_hide_rounded,
                          color: isDark
                              ? const Color(0xFFFFD54F)
                              : const Color(0xFF004D40),
                        ),
                        tooltip: tr('Done / Exit Keyboard'),
                        onPressed: () => FocusScope.of(context).unfocus(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  if (isArtisan) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF78350F).withValues(alpha: 0.35)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: isDark ? 0.6 : 1.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                color: isDark
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFFB45309),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('DUAL ROLE SYNC: ARTISAN STUDIO'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFFFD54F)
                                      : const Color(0xFFB45309),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(
                              'Changes here update your public Artisan Studio profile across the platform.',
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Studio Name Input
                          TextFormField(
                            controller: _studioNameController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: ProfileValidator.validateStudioName,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              labelText: tr('Artisan Studio Name'),
                              prefixIcon: Icon(
                                Icons.storefront_outlined,
                                color: isDark
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFFB45309),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0D2825)
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Craft Category Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCraftCategory,
                            dropdownColor: isDark
                                ? const Color(0xFF0D2825)
                                : Colors.white,
                            decoration: InputDecoration(
                              labelText: tr('Craft Specialization'),
                              prefixIcon: Icon(
                                Icons.category_outlined,
                                color: isDark
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFFB45309),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0D2825)
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: _craftCategories.map((craft) {
                              return DropdownMenuItem<String>(
                                value: craft,
                                child: Text(
                                  tr(craft),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCraftCategory = val);
                              }
                            },
                          ),

                          const SizedBox(height: 14),

                          // State / Region Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedState,
                            dropdownColor: isDark
                                ? const Color(0xFF0D2825)
                                : Colors.white,
                            decoration: InputDecoration(
                              labelText: tr('Studio State / Location'),
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: isDark
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFFB45309),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0D2825)
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: _malaysianStates.map((st) {
                              return DropdownMenuItem<String>(
                                value: st,
                                child: Text(
                                  tr(st),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedState = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
