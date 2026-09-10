import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../tourist/widgets/workshop_map_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';

class ProfileBuilderTab extends StatefulWidget {
  const ProfileBuilderTab({super.key});

  @override
  State<ProfileBuilderTab> createState() => _ProfileBuilderTabState();
}

class _ProfileBuilderTabState extends State<ProfileBuilderTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _studioNameController;
  late final TextEditingController _craftCategoryController;
  late final TextEditingController _stateController;
  late final TextEditingController _experienceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameStatusMessage;
  Timer? _usernameDebounce;
  String? _initialUsername;

  GoogleMapController? _workshopMapController;
  LatLng? _selectedWorkshopPin;
  String? _workshopAddress;
  LatLng? _lastAnimatedPin;

  static const Map<String, LatLng> _stateCenters = {
    'Johor': LatLng(1.4927, 103.7414),
    'Kedah': LatLng(6.1184, 100.3685),
    'Kelantan': LatLng(6.1254, 102.2381),
    'Melaka': LatLng(2.1896, 102.2501),
    'Negeri Sembilan': LatLng(2.7258, 101.9424),
    'Pahang': LatLng(3.8077, 103.3260),
    'Penang': LatLng(5.4141, 100.3288),
    'Perak': LatLng(4.5975, 101.0901),
    'Perlis': LatLng(6.4414, 100.1986),
    'Sabah': LatLng(5.9804, 116.0735),
    'Sarawak': LatLng(1.5533, 110.3592),
    'Selangor': LatLng(3.0738, 101.5183),
    'Terengganu': LatLng(5.3296, 103.1370),
    'Kuala Lumpur': LatLng(3.1390, 101.6869),
  };

  static LatLng _resolveStateCenter(String? stateName) {
    if (stateName == null || stateName.trim().isEmpty) {
      return const LatLng(3.1390, 101.6869);
    }
    final lower = stateName.trim().toLowerCase();
    for (final entry in _stateCenters.entries) {
      if (lower.contains(entry.key.toLowerCase()) || entry.key.toLowerCase().contains(lower)) {
        return entry.value;
      }
    }
    return const LatLng(3.1390, 101.6869);
  }

  LatLng get _selectedStateCenter {
    final state = _stateController.text.trim();
    return _resolveStateCenter(state);
  }

  bool _isOpenForDemos = true;

  List<String> _toolsAndMaterials = [];

  List<String> _portfolioImages = [];
  Map<String, String> _documents = {};

  @override
  void initState() {
    super.initState();
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    final initialHandle = (user?.username ?? user?.effectiveUsername ?? '').replaceAll('@', '');
    _initialUsername = initialHandle;
    _usernameController = TextEditingController(text: initialHandle);
    _usernameController.addListener(_onUsernameChanged);
    _studioNameController = TextEditingController(
      text: user?.studioName ?? user?.displayName ?? '',
    );
    _craftCategoryController = TextEditingController(
      text: user?.craftCategory ?? '',
    );
    _stateController = TextEditingController(text: user?.state ?? '');
    _workshopAddress = user?.address;
    if (user != null && user.latitude != null && user.longitude != null && user.latitude != 0.0) {
      _selectedWorkshopPin = LatLng(user.latitude!, user.longitude!);
    } else if (user?.state != null && user!.state!.isNotEmpty) {
      _selectedWorkshopPin = _resolveStateCenter(user.state);
    }
    _experienceController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(
      text: user?.bio ?? '',
    );
    
    _syncFromUser(user, force: true);

    Future.microtask(() {
      if (mounted) {
        context.read<AuthViewModel>().refreshCurrentUser();
      }
    });
  }

  void _syncFromUser(UserModel? user, {bool force = false}) {
    if (user == null) return;

    if (force || (_bioController.text.isEmpty && (user.bio?.isNotEmpty ?? false))) {
      _bioController.text = user.bio ?? '';
    }

    if (force || (_studioNameController.text.isEmpty && ((user.studioName ?? user.displayName)?.isNotEmpty ?? false))) {
      _studioNameController.text = user.studioName ?? user.displayName ?? '';
    }

    if (force || (_craftCategoryController.text.isEmpty && (user.craftCategory?.isNotEmpty ?? false))) {
      _craftCategoryController.text = user.craftCategory ?? '';
    }

    if (force || (_stateController.text.isEmpty && (user.state?.isNotEmpty ?? false))) {
      _stateController.text = user.state ?? '';
    }

    if (force || (_phoneController.text.isEmpty && (user.phone?.isNotEmpty ?? false))) {
      _phoneController.text = user.phone ?? '';
    }

    if (force || _workshopAddress == null) {
      if (user.address != null && user.address!.isNotEmpty) {
        _workshopAddress = user.address;
      }
    }

    if (force || _selectedWorkshopPin == null) {
      if (user.latitude != null && user.longitude != null && user.latitude != 0.0) {
        _selectedWorkshopPin = LatLng(user.latitude!, user.longitude!);
      } else if (user.state != null && user.state!.isNotEmpty) {
        _selectedWorkshopPin = _resolveStateCenter(user.state);
      }
    }

    if (force || _portfolioImages.isEmpty) {
      final newImages = <String>[];
      final newDocs = <String, String>{};
      for (var doc in user.artisanDocuments) {
        final type = doc['doc_type'] as String?;
        final url = doc['file_url'] as String?;
        if (type != null && url != null) {
          if (type == 'PORTFOLIO_IMAGE' || type == 'STUDIO_PHOTO') {
            newImages.add(url);
          } else {
            newDocs[type] = url;
          }
        }
      }
      if (newImages.isNotEmpty) {
        _portfolioImages = newImages;
      }
      if (newDocs.isNotEmpty) {
        _documents = newDocs;
      }
    }

    if (force || _toolsAndMaterials.isEmpty) {
      if (user.tags.isNotEmpty) {
        _toolsAndMaterials = List<String>.from(user.tags);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthViewModel>().currentUser;
    if (user != null) {
      _syncFromUser(user);
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
        _usernameStatusMessage = isAvailable ? '@$raw is available' : '@$raw is already taken';
      });
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _studioNameController.dispose();
    _craftCategoryController.dispose();
    _stateController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _workshopMapController?.dispose();
    super.dispose();
  }



  Future<void> _handleCancelRelocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Relocation Request?'),
        content: const Text('Are you sure you want to cancel your pending premise relocation review? Your current verified location will remain unchanged.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Pending')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Withdraw Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authVM = context.read<AuthViewModel>();
      await authVM.cancelRelocationRequest();
      if (mounted) {
        setState(() {});
        final verifiedPin = _selectedWorkshopPin ??
            (authVM.currentUser?.latitude != null && authVM.currentUser?.longitude != null
                ? LatLng(authVM.currentUser!.latitude!, authVM.currentUser!.longitude!)
                : _selectedStateCenter);
        _workshopMapController?.animateCamera(
          CameraUpdate.newLatLngZoom(verifiedPin, 15),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relocation request withdrawn successfully.'),
            backgroundColor: Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openRelocationDialog() async {
    final authVM = context.read<AuthViewModel>();
    final currentUser = authVM.currentUser;
    if (currentUser == null) return;

    LatLng? proposedPin;
    String? proposedAddress;
    String? proposedState;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(
                    'Request Premise Relocation',
                    style: GoogleFonts.dmSerifDisplay(fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workshop locations are legally verified by Kraftangan Malaysia officers. Moving premises requires formal administrative re-verification.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Current Accredited Address:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser.address ?? 'Registered Accredited Workshop',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Proposed New Premise:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final effectivePin = _selectedWorkshopPin ??
                                (currentUser.latitude != null && currentUser.longitude != null && currentUser.latitude != 0.0
                                    ? LatLng(currentUser.latitude!, currentUser.longitude!)
                                    : (currentUser.state != null ? _resolveStateCenter(currentUser.state) : null));
                            final effectiveAddr = _workshopAddress ?? currentUser.address ?? '';
                            final effectiveState = currentUser.state ?? '';

                            final result = await Navigator.of(context).push<WorkshopPlaceResult>(
                              MaterialPageRoute(
                                builder: (_) => WorkshopMapPickerPage(
                                  initialState: proposedState ?? effectiveState,
                                  initialLocation: proposedPin ?? effectivePin,
                                  initialAddress: proposedAddress ?? effectiveAddr,
                                  stateCenters: _stateCenters,
                                ),
                              ),
                            );
                            if (result != null) {
                              setDialogState(() {
                                proposedPin = result.position;
                                proposedAddress = result.displayName;
                                proposedState = result.malaysiaState;
                                if (reasonController.text.trim().isEmpty) {
                                  reasonController.text = 'Premise relocation to ${result.displayName}';
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.place_outlined),
                          label: Text(
                            proposedAddress == null ? 'Pin New Location on Map' : 'Change Selected Location',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          ),
                        ),
                        if (proposedAddress != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFFD97706), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    proposedAddress!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: reasonController,
                          maxLines: 3,
                          validator: (v) => ProfileValidator.validateNotEmpty(v, 'Justification reason'),
                          decoration: InputDecoration(
                            labelText: 'Relocation Reason / Justification',
                            hintText: 'e.g., Relocated to larger studio lot to support traditional weaving loom capacity',
                            labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (proposedAddress == null || proposedPin == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select the proposed new workshop location on the map.'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final reason = reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : 'Premise relocation to $proposedAddress';
                    await authVM.submitRelocationRequest(
                      address: proposedAddress!,
                      state: proposedState ?? currentUser.state ?? 'Melaka',
                      latitude: proposedPin!.latitude,
                      longitude: proposedPin!.longitude,
                      reason: reason,
                    );

                    if (mounted) {
                      try {
                        context.read<ModerationViewModel>().addRelocationRequest(
                          PendingArtisanProfile(
                            id: 'reloc_${currentUser.id}',
                            name: currentUser.studioName ?? currentUser.displayName ?? 'Artisan Studio',
                            craftCategory: currentUser.craftCategory ?? 'Handicraft & Heritage',
                            state: currentUser.state ?? _stateController.text.trim(),
                            dateSubmitted: 'Today',
                            imageUrl: currentUser.avatarUrl ?? '',
                            email: currentUser.email,
                            experience: _experienceController.text.trim(),
                            phone: currentUser.phone ?? _phoneController.text.trim(),
                            ssmNumber: currentUser.ssmNumber,
                            bio: currentUser.bio ?? _bioController.text.trim(),
                            isUpgradeFromTourist: false,
                            isRelocationRequest: true,
                            currentAddress: currentUser.address,
                            proposedAddress: proposedAddress,
                            proposedLatitude: proposedPin!.latitude,
                            proposedLongitude: proposedPin!.longitude,
                            proposedState: proposedState ?? currentUser.state,
                            relocationReason: reason,
                          ),
                        );
                      } catch (_) {}

                      setState(() {});
                      if (_workshopMapController != null && proposedPin != null) {
                        _workshopMapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(proposedPin!, 15),
                        );
                      }

                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Relocation request submitted for Administrative Review.'),
                          backgroundColor: Color(0xFF047857),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted form errors before saving.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_usernameStatusMessage ?? 'Username handle is already taken'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedWorkshopPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pin your workshop location on the map before saving.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final username = _usernameController.text.trim().replaceAll('@', '');
    final studio = _studioNameController.text.trim();
    final craft = _craftCategoryController.text.trim();
    final bio = _bioController.text.trim();
    final state = _stateController.text.trim();
    final phone = _phoneController.text.trim();

    final authVM = context.read<AuthViewModel>();
    try {
      await authVM.updateProfile(
        username: username,
        displayName: studio.isNotEmpty ? studio : username,
        studioName: studio,
        craftCategory: craft,
        bio: bio,
        state: state,
        address: _workshopAddress,
        latitude: _selectedWorkshopPin?.latitude,
        longitude: _selectedWorkshopPin?.longitude,
        phone: phone,
        toolsAndMaterials: _toolsAndMaterials,
      );

      if (mounted) {
        final updatedUser = authVM.currentUser;
        if (updatedUser != null) {
          setState(() {
            _initialUsername = (updatedUser.username ?? updatedUser.effectiveUsername).replaceAll('@', '');
            _usernameController.text = _initialUsername!;
            _studioNameController.text = updatedUser.studioName ?? updatedUser.displayName ?? updatedUser.effectiveUsername;
          });
        }
      }

      try {
        final moderationVM = context.read<ModerationViewModel>();
        final email = authVM.currentUser?.email;
        if (email != null) {
          moderationVM.updateUserProfileInState(
            email: email,
            username: username,
            studioName: studio,
          );
        }
      } catch (_) {}
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

    // Refresh the directory so changes appear immediately for tourists
    context.read<DirectoryViewModel>().fetchArtisans();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Artisan Studio Profile & Tourist handle synced successfully!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _previewTouristView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtisanDetailScreen(
          artisanName: _studioNameController.text.trim().isEmpty ? 'Artisan Studio' : _studioNameController.text.trim(),
          craftCategory: _craftCategoryController.text.trim().isEmpty ? 'Heritage Craft' : _craftCategoryController.text.trim(),
          state: _stateController.text.trim().isEmpty ? 'Malaysia' : _stateController.text.trim(),
          bio: _bioController.text.trim(),
          experience: _experienceController.text.trim(),
          imageUrl: _portfolioImages.isNotEmpty
              ? _portfolioImages.first
              : (context.read<AuthViewModel>().currentUser?.avatarUrl ?? ''),
          tags: _toolsAndMaterials,
          address: _workshopAddress,
          latitude: _selectedWorkshopPin?.latitude,
          longitude: _selectedWorkshopPin?.longitude,
        ),
      ),
    );
  }

  Future<void> _uploadDocument(String docType) async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result.isNotEmpty) {
      final file = result.first;
      final authVM = context.read<AuthViewModel>();
      final user = authVM.currentUser;
      if (user == null || user.artisanProfileId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find artisan profile ID.')));
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading document...')));
      final uploadRes = await context.read<SupabaseService>().uploadArtisanDocument(user.artisanProfileId!, file, docType);
      
      if (uploadRes != null) {
        setState(() {
          if (docType == 'PORTFOLIO_IMAGE' || docType == 'STUDIO_PHOTO') {
            _portfolioImages.add(uploadRes['url']!);
          } else {
            _documents[docType] = uploadRes['url']!;
          }
        });
        unawaited(context.read<AuthViewModel>().refreshCurrentUser());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed.')));
      }
    }
  }

  void _viewDocument(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file.')));
      }
    }
  }
  
  InputDecoration _inputDecoration(
    bool isDark, {
    required String labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
    Color? helperColor,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : const Color(0xFF475569),
      ),
      helperText: helperText,
      helperStyle: TextStyle(
        color: helperColor ?? (isDark ? Colors.white54 : Colors.grey[600]),
        fontSize: 11,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            )
          : null,
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorMaxLines: 2,
      filled: true,
      fillColor: isDark ? const Color(0xFF0D2825) : Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
    final currentUser = authVM.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Artisan Profile Builder',
          style: GoogleFonts.dmSerifDisplay(
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            fontSize: 22,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF041412) : Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _previewTouristView,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              ),
              icon: Icon(
                Icons.visibility_rounded,
                size: 18,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              ),
              label: Text(
                'Preview Tourist View',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final refreshed = await context.read<AuthViewModel>().refreshCurrentUser();
          if (mounted && refreshed != null) {
            setState(() {
              _syncFromUser(refreshed, force: true);
            });
          }
        },
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 🛡️ VERIFIED MASTER LICENSE BADGE BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D2825) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3A34) : const Color(0xFF10B981),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Master Artisan Profile (Approved)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                          ),
                        ),
                        Text(
                          'Your studio license is active & verified by Kraftangan Malaysia Officers. Profile edits sync live to tourists.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (context.watch<AuthViewModel>().currentUser?.isDualRole == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2825) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E3A34) : const Color(0xFF38BDF8),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(isDark ? 0.25 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.explore_rounded, color: Color(0xFF38BDF8), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dual Role: Cultural Explorer Mode',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                            ),
                          ),
                          Text(
                            'Switch to explore craft heritage, visit artisan workshops, and earn passport stamps.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        context.read<AuthViewModel>().selectActiveRole('Cultural Tourist');
                        Navigator.of(context).pushReplacementNamed('/tourist');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Studio Information',
                    softWrap: true,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _previewTouristView,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: BorderSide(
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                  ),
                  icon: Icon(
                    Icons.remove_red_eye_rounded,
                    size: 14,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  ),
                  label: Text(
                    'Preview Tourist Page',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Cultural Demo Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isOpenForDemos
                    ? (isDark ? const Color(0xFF0D2825) : const Color(0xFFECFDF5))
                    : (isDark ? const Color(0xFF2A1215) : const Color(0xFFFEF2F2)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOpenForDemos
                      ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFF10B981))
                      : (isDark ? const Color(0xFF5C1D24) : const Color(0xFFEF4444)),
                ),
              ),
              child: SwitchListTile(
                value: _isOpenForDemos,
                onChanged: (val) => setState(() => _isOpenForDemos = val),
                activeColor: const Color(0xFF10B981),
                title: Text(
                  _isOpenForDemos ? '🟢 STUDIO STATUS: OPEN FOR EDUCATIONAL DEMOS' : '🔴 STUDIO STATUS: IN KILN SESSION / CLOSED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isOpenForDemos
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                        : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                  ),
                ),
                subtitle: Text(
                  'Toggling this updates your live availability banner on the Tourist Studio detail page.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.grey[700],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Account Username / Handle Input
            TextFormField(
              controller: _usernameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: ProfileValidator.validateUsername,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: _inputDecoration(
                isDark,
                labelText: 'Account Username / Handle (@username)',
                prefixIcon: Icons.person_outline_rounded,
                helperText: _usernameStatusMessage ?? 'Unified account handle synced across Tourist & Master Artisan roles',
                helperColor: _isUsernameAvailable == true
                    ? const Color(0xFF10B981)
                    : (_isUsernameAvailable == false ? const Color(0xFFEF4444) : null),
                suffixIcon: _isCheckingUsername
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_isUsernameAvailable != null
                        ? Icon(
                            _isUsernameAvailable! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: _isUsernameAvailable! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          )
                        : null),
              ),
            ),

            const SizedBox(height: 14),

            // Studio Name Input
            TextFormField(
              controller: _studioNameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: ProfileValidator.validateStudioName,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: _inputDecoration(
                isDark,
                labelText: 'Artisan Studio Name',
                prefixIcon: Icons.storefront_outlined,
                helperText: 'Public workshop or studio brand name displayed on the directory',
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                // Craft Category Input
                Expanded(
                  child: TextFormField(
                    controller: _craftCategoryController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: ProfileValidator.validateCraftCategory,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: _inputDecoration(
                      isDark,
                      labelText: 'Craft Category',
                      prefixIcon: Icons.palette_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Phone Number Input
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => ProfileValidator.validatePhone(v, isRequired: true),
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: _inputDecoration(
                      isDark,
                      labelText: 'Phone / WhatsApp',
                      prefixIcon: Icons.phone_outlined,
                      helperText: 'e.g. +60 12-345 6789',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🗺️ Workshop Map Location - Verified Premise & Relocation Flow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workshop Location',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Premise',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your workshop premise is verified and locked to protect consumers. Official relocation requests require Administrative Review.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D2825) : const Color(0xFFE8EFEC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: (currentUser != null &&
                                  currentUser.latitude != null &&
                                  currentUser.longitude != null &&
                                  currentUser.latitude != 0.0)
                              ? LatLng(currentUser.latitude!, currentUser.longitude!)
                              : (_selectedWorkshopPin ?? _selectedStateCenter),
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          _workshopMapController = controller;
                          final pin = (currentUser != null &&
                                  currentUser.latitude != null &&
                                  currentUser.longitude != null &&
                                  currentUser.latitude != 0.0)
                              ? LatLng(currentUser.latitude!, currentUser.longitude!)
                              : (_selectedWorkshopPin ?? _selectedStateCenter);
                          controller.animateCamera(CameraUpdate.newLatLngZoom(pin, 15));
                        },
                        markers: () {
                          final user = currentUser;
                          final set = <Marker>{};
                          final currentPremisePin = (user != null &&
                                  user.latitude != null &&
                                  user.longitude != null &&
                                  user.latitude != 0.0)
                              ? LatLng(user.latitude!, user.longitude!)
                              : (_selectedWorkshopPin ?? _selectedStateCenter);

                          if (_workshopMapController != null && currentPremisePin != _lastAnimatedPin) {
                            _lastAnimatedPin = currentPremisePin;
                            Future.microtask(() {
                              _workshopMapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(currentPremisePin, 15),
                              );
                            });
                          }

                          set.add(
                            Marker(
                              markerId: const MarkerId('workshop-location'),
                              position: currentPremisePin,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                              infoWindow: InfoWindow(
                                title: _studioNameController.text.trim().isNotEmpty
                                    ? _studioNameController.text.trim()
                                    : (user?.studioName ?? 'Verified Workshop'),
                                snippet: (user?.address != null && user!.address!.trim().isNotEmpty)
                                    ? user.address!
                                    : (_workshopAddress ?? 'Accredited Workshop Premise'),
                              ),
                            ),
                          );
                          if (user != null &&
                              user.hasPendingRelocation &&
                              user.pendingRelocationLatitude != null &&
                              user.pendingRelocationLongitude != null) {
                            set.add(
                              Marker(
                                markerId: const MarkerId('proposed-relocation-pin'),
                                position: LatLng(
                                  user.pendingRelocationLatitude!,
                                  user.pendingRelocationLongitude!,
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueOrange,
                                ),
                                infoWindow: InfoWindow(
                                  title: 'Proposed Premise (Pending Review)',
                                  snippet: user.pendingRelocationAddress ?? '',
                                ),
                              ),
                            );
                          }
                          return set;
                        }(),
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Location Locked',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    (currentUser?.address != null && currentUser!.address!.trim().isNotEmpty)
                        ? currentUser.address!
                        : (_workshopAddress ?? 'Accredited Heritage Workshop Premise'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (authVM.relocationResolutionNotice == 'APPROVED') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Workshop Relocation Approved & Active!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Color(0xFF065F46)),
                          onPressed: () => authVM.clearRelocationResolutionNotice(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your accredited workshop location is now officially updated to ${currentUser?.address ?? ""}. Tourist maps and discovery directions now lead to your new workshop premise.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (authVM.relocationResolutionNotice == 'REJECTED') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Relocation Request Not Approved',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Color(0xFF991B1B)),
                          onPressed: () => authVM.clearRelocationResolutionNotice(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your proposed relocation premise was not approved by administration. Your workshop location remains at your current accredited address. You may submit a new relocation request anytime.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (currentUser?.hasPendingRelocation == true) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Relocation Request Pending Administrative Review',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Proposed Premise: ${currentUser?.pendingRelocationAddress ?? ""}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF78350F),
                      ),
                    ),
                    if (currentUser?.pendingRelocationReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Justification: "${currentUser!.pendingRelocationReason}"',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Public directory shows current verified address until approved.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (currentUser != null &&
                            currentUser.pendingRelocationLatitude != null &&
                            currentUser.pendingRelocationLongitude != null) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              final pLat = currentUser.pendingRelocationLatitude;
                              final pLng = currentUser.pendingRelocationLongitude;
                              if (pLat != null && pLng != null) {
                                _workshopMapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    LatLng(pLat, pLng),
                                    15,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFFD97706)),
                            label: const Text('View on Map', style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        OutlinedButton(
                          onPressed: _handleCancelRelocation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Withdraw Request', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _openRelocationDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFD97706)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                label: Text(
                  'Request Workshop Relocation',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),

            // Experience Input
            TextFormField(
              controller: _experienceController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => ProfileValidator.validateExperience(v, isRequired: true),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: _inputDecoration(
                isDark,
                labelText: 'Years of Experience & Rank Title',
                prefixIcon: Icons.workspace_premium_outlined,
                helperText: 'e.g. 25+ Years Experience • Adiguru Kraf',
              ),
            ),

            const SizedBox(height: 14),

            // Bio Input
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => ProfileValidator.validateBio(
                v,
                isRequired: true,
                minLength: 15,
                maxLength: 1000,
              ),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: 'Biography & Heritage Craft Story',
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
                alignLabelWithHint: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    width: 1.8,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 🛠️ TRADITIONAL MATERIALS & TOOLS BUILDER SECTION
            Text(
              'Traditional Materials & Tools Used',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Displayed on your tourist profile page to highlight authentic crafting methods.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._toolsAndMaterials.map((tool) => Chip(
                      backgroundColor: isDark ? const Color(0xFF0D2825) : null,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1),
                      ),
                      avatar: Icon(
                        Icons.build_circle_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      ),
                      label: Text(
                        tool,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                      deleteIconColor: isDark ? Colors.white70 : null,
                      onDeleted: () {
                        setState(() => _toolsAndMaterials.remove(tool));
                      },
                    )),
                ActionChip(
                  backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                  side: const BorderSide(color: Color(0xFFD97706)),
                  avatar: const Icon(Icons.add, size: 16, color: Color(0xFFD97706)),
                  label: Text('Add Tool/Material', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                  onPressed: () {
                    final dialogFormKey = GlobalKey<FormState>();
                    final textController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                        title: Text(
                          'Add Traditional Tool or Material',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                        content: Form(
                          key: dialogFormKey,
                          child: TextFormField(
                            controller: textController,
                            autofocus: true,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (v) => ProfileValidator.validateTag(v, _toolsAndMaterials),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'e.g., Paddy Husk Kiln Ash',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : null,
                              ),
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                            ),
                            onPressed: () {
                              if (dialogFormKey.currentState?.validate() ?? false) {
                                setState(() => _toolsAndMaterials.add(textController.text.trim()));
                                Navigator.pop(dialogCtx);
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Unlimited Portfolio Image Manager Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Portfolio Gallery Manager',
                    softWrap: true,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_portfolioImages.length} Uploaded (Unlimited)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Images uploaded here populate the top gallery slider on the Tourist Profile page.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic Unlimited Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _portfolioImages.length + 1,
              itemBuilder: (context, index) {
                if (index < _portfolioImages.length) {
                  final image = _portfolioImages[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          image,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () async {
                            final deletedImage = _portfolioImages[index];
                            setState(() => _portfolioImages.removeAt(index));
                            await context.read<SupabaseService>().deleteArtisanDocumentByUrl(deletedImage);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Add Image Tile
                return GestureDetector(
                  onTap: () => _uploadDocument('PORTFOLIO_IMAGE'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D2825) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E3A34) : Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: Color(0xFFD97706), size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'Add Image',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // 📜 VERIFICATION DOCUMENTS & PROOF OF AUTHENTICITY SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Proof of Authenticity & Credentials',
                    softWrap: true,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D2825) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
                  ),
                  child: Text(
                    '3 / 3 Uploaded',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Upload official certificates to populate master credentials on the Tourist Profile view.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            _buildDocumentUploadTile(
              isDark: isDark,
              title: 'Business Registration (SSM) Certificate',
              subtitle: _documents['SSM_BUSINESS_CERT'] != null ? 'Uploaded Document' : 'Required',
              icon: Icons.article_rounded,
              isUploaded: _documents['SSM_BUSINESS_CERT'] != null,
              onTap: () => _uploadDocument('SSM_BUSINESS_CERT'),
              onView: _documents['SSM_BUSINESS_CERT'] != null ? () => _viewDocument(_documents['SSM_BUSINESS_CERT']!) : null,
            ),
            _buildDocumentUploadTile(
              isDark: isDark,
              title: 'Kraftangan Malaysia Master Certification',
              subtitle: _documents['KRAFTANGAN_MASTER_CERT'] != null ? 'Uploaded Document' : 'Optional',
              icon: Icons.workspace_premium_rounded,
              isUploaded: _documents['KRAFTANGAN_MASTER_CERT'] != null,
              onTap: () => _uploadDocument('KRAFTANGAN_MASTER_CERT'),
              onView: _documents['KRAFTANGAN_MASTER_CERT'] != null ? () => _viewDocument(_documents['KRAFTANGAN_MASTER_CERT']!) : null,
            ),

            const SizedBox(height: 36),

            // Save & Preview Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previewTouristView,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(
                      Icons.visibility_rounded,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                    label: Text(
                      'PREVIEW TOURIST VIEW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'SAVE PROFILE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildDocumentUploadTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUploaded,
    VoidCallback? onTap,
    VoidCallback? onView,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D2825)
            : (isUploaded ? const Color(0xFFF8FAFC) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A34)
              : (isUploaded ? const Color(0xFFCBD5E1) : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF041412)
                  : (isUploaded ? const Color(0xFF004D40).withValues(alpha: 0.1) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isUploaded
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF004D40))
                  : (isDark ? Colors.white54 : Colors.grey[500]),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                if (isUploaded && onView != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onView,
                    child: Text(
                      'View File',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark
                    ? (isUploaded ? const Color(0xFF34D399) : const Color(0xFF1E3A34))
                    : (isUploaded ? const Color(0xFF10B981) : Colors.grey),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(
              isUploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              size: 14,
              color: isUploaded
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981))
                  : (isDark ? Colors.white60 : Colors.grey),
            ),
            label: Text(
              isUploaded ? 'UPLOADED' : 'UPLOAD',
              style: TextStyle(
                fontSize: 10,
                color: isUploaded
                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981))
                    : (isDark ? Colors.white60 : Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}