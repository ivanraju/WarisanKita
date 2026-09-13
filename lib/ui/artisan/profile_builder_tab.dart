import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:warisan_kita/domain/validators/document_validator.dart';
import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/viewmodels/directory_viewmodel.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';

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

  List<String> _toolsAndMaterials = [];

  List<String> _portfolioImages = [];
  Map<String, String> _documents = {};
  bool _isSaving = false;

  void _onFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasUnsavedChanges {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return false;

    // 1. Username / Handle
    final initialHandle = (user.username ?? user.effectiveUsername).replaceAll('@', '').trim();
    final currentHandle = _usernameController.text.replaceAll('@', '').trim();
    if (currentHandle != initialHandle) return true;

    // 2. Studio Name
    final initialStudio = (user.studioName ?? user.displayName ?? '').trim();
    final currentStudio = _studioNameController.text.trim();
    if (currentStudio != initialStudio) return true;

    // 3. Craft Category
    final initialCraft = (user.craftCategory ?? '').trim();
    final currentCraft = _craftCategoryController.text.trim();
    if (currentCraft != initialCraft) return true;

    // 4. Experience
    final initialExpDigits = _extractExperienceNumber(user.experience);
    final currentExpDigits = _experienceController.text.trim();
    if (currentExpDigits != initialExpDigits) return true;

    // 5. Bio
    final initialBio = (user.bio ?? '').trim();
    final currentBio = _bioController.text.trim();
    if (currentBio != initialBio) return true;

    // 6. State
    final initialState = (user.state ?? '').trim();
    final currentState = _stateController.text.trim();
    if (currentState != initialState) return true;

    // 7. Phone
    final initialPhone = (user.phone ?? '').trim();
    final currentPhone = _phoneController.text.trim();
    if (currentPhone != initialPhone) return true;

    // 8. Workshop Address
    final initialAddress = (user.address ?? '').trim();
    final currentAddress = (_workshopAddress ?? '').trim();
    if (currentAddress != initialAddress) return true;

    // 9. Workshop Pin (lat / lng)
    if (user.latitude != null && user.longitude != null && user.latitude != 0.0) {
      if (_selectedWorkshopPin == null) return true;
      final latDiff = (_selectedWorkshopPin!.latitude - user.latitude!).abs();
      final lngDiff = (_selectedWorkshopPin!.longitude - user.longitude!).abs();
      if (latDiff > 0.0001 || lngDiff > 0.0001) return true;
    } else if (_selectedWorkshopPin != null) {
      final defaultCenter = _resolveStateCenter(user.state);
      final latDiff = (_selectedWorkshopPin!.latitude - defaultCenter.latitude).abs();
      final lngDiff = (_selectedWorkshopPin!.longitude - defaultCenter.longitude).abs();
      if (latDiff > 0.0001 || lngDiff > 0.0001) return true;
    }

    // 10. Tools & Materials Tags
    final userTags = user.tags;
    if (_toolsAndMaterials.length != userTags.length) return true;
    for (final tag in _toolsAndMaterials) {
      if (!userTags.contains(tag)) return true;
    }

    return false;
  }

  static bool _isDefaultOrEmptyExperience(String? exp) {
    if (exp == null) return true;
    final trimmed = exp.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    if (trimmed == 'master artisan applicant' ||
        trimmed == 'craft artisan') {
      return true;
    }
    return false;
  }

  static String _extractExperienceNumber(String? exp) {
    if (exp == null) return '';
    if (_isDefaultOrEmptyExperience(exp)) return '';
    final digits = exp.replaceAll(RegExp(r'[^0-9]'), '');
    return digits;
  }

  @override
  void initState() {
    super.initState();
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    final initialHandle = (user?.username ?? user?.effectiveUsername ?? '').replaceAll('@', '');
    _initialUsername = initialHandle;
    _usernameController = TextEditingController(text: initialHandle);
    _usernameController.addListener(_onUsernameChanged);
    _usernameController.addListener(_onFormChanged);
    _studioNameController = TextEditingController(
      text: user?.studioName ?? user?.displayName ?? '',
    );
    _studioNameController.addListener(_onFormChanged);
    _craftCategoryController = TextEditingController(
      text: user?.craftCategory ?? '',
    );
    _craftCategoryController.addListener(_onFormChanged);
    _stateController = TextEditingController(text: user?.state ?? '');
    _stateController.addListener(_onFormChanged);
    _workshopAddress = user?.address;
    if (user != null && user.latitude != null && user.longitude != null && user.latitude != 0.0) {
      _selectedWorkshopPin = LatLng(user.latitude!, user.longitude!);
    } else if (user?.state != null && user!.state!.isNotEmpty) {
      _selectedWorkshopPin = _resolveStateCenter(user.state);
    }
    _experienceController = TextEditingController(
      text: _extractExperienceNumber(user?.experience),
    );
    _experienceController.addListener(_onFormChanged);
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _phoneController.addListener(_onFormChanged);
    _bioController = TextEditingController(
      text: user?.bio ?? '',
    );
    _bioController.addListener(_onFormChanged);
    
    _syncFromUser(user, force: true);

    Future.microtask(() {
      if (mounted) {
        context.read<AuthViewModel>().refreshCurrentUser();
      }
    });
  }

  void _syncFromUser(UserModel? user, {bool force = false}) {
    if (user == null) return;

    if (force || _experienceController.text.isEmpty) {
      if (!_isDefaultOrEmptyExperience(user.experience)) {
        _experienceController.text = _extractExperienceNumber(user.experience);
      } else if (force) {
        _experienceController.text = '';
      }
    }

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

    if (force || _workshopAddress == null || (user.address != null && _workshopAddress != user.address)) {
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
    } else if (user.latitude != null &&
        user.longitude != null &&
        user.latitude != 0.0 &&
        (_selectedWorkshopPin?.latitude != user.latitude || _selectedWorkshopPin?.longitude != user.longitude)) {
      _selectedWorkshopPin = LatLng(user.latitude!, user.longitude!);
    }

    if (force || _portfolioImages.isEmpty) {
      final newImages = <String>[];
      final newDocs = <String, String>{};
      for (var doc in user.artisanDocuments) {
        final type = doc['doc_type'] as String?;
        final url = doc['file_url'] as String?;
        if (type != null && url != null) {
          if (type == 'PORTFOLIO_IMAGE') {
            newImages.add(url);
          } else if (type == 'STUDIO_PHOTO' ||
              type == 'CRAFTING_PHOTO' ||
              type == 'VILLAGE_CRAFTING_PHOTO') {
            newImages.add(url);
            newDocs['CRAFTING_PHOTO'] = url;
            newDocs[type] = url;
          } else {
            newDocs[type] = url;
          }
        }
      }
      if (user.isVillageWorkshop && newDocs['CRAFTING_PHOTO'] == null) {
        final fallbackCraft = user.craftingPhotoUrl ?? user.ssmFileUrl;
        if (fallbackCraft != null && fallbackCraft.isNotEmpty) {
          newDocs['CRAFTING_PHOTO'] = fallbackCraft;
        }
      }
      if (!user.isVillageWorkshop && newDocs['SSM_BUSINESS_CERT'] == null) {
        final fallbackSsm = user.ssmFileUrl;
        if (fallbackSsm != null && fallbackSsm.isNotEmpty) {
          newDocs['SSM_BUSINESS_CERT'] = fallbackSsm;
        }
      }
      if (newDocs['KRAFTANGAN_MASTER_CERT'] == null) {
        final fallbackCert = user.certFileUrl;
        if (fallbackCert != null && fallbackCert.isNotEmpty) {
          newDocs['KRAFTANGAN_MASTER_CERT'] = fallbackCert;
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
    _usernameController.removeListener(_onFormChanged);
    _usernameController.dispose();
    _studioNameController.removeListener(_onFormChanged);
    _studioNameController.dispose();
    _craftCategoryController.removeListener(_onFormChanged);
    _craftCategoryController.dispose();
    _stateController.removeListener(_onFormChanged);
    _stateController.dispose();
    _experienceController.removeListener(_onFormChanged);
    _experienceController.dispose();
    _phoneController.removeListener(_onFormChanged);
    _phoneController.dispose();
    _bioController.removeListener(_onFormChanged);
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

    final isUpdating = currentUser.hasPendingRelocation;

    LatLng? proposedPin = isUpdating &&
            currentUser.pendingRelocationLatitude != null &&
            currentUser.pendingRelocationLongitude != null
        ? LatLng(currentUser.pendingRelocationLatitude!, currentUser.pendingRelocationLongitude!)
        : null;
    String? proposedAddress = isUpdating ? currentUser.pendingRelocationAddress : null;
    String? proposedState = isUpdating ? currentUser.pendingRelocationState : null;
    final reasonController = TextEditingController(
      text: isUpdating ? (currentUser.pendingRelocationReason ?? '') : '',
    );
    fp.PlatformFile? attachedCertFile;
    String? certFileName = isUpdating ? currentUser.pendingRelocationCertName : null;
    String? certFileUrl = isUpdating ? currentUser.pendingRelocationCertUrl : null;
    String? certFileSizeLabel;
    bool isUploadingCert = false;
    bool showCertError = false;
    String? dialogErrorMessage;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: StatefulBuilder(
              builder: (dialogContentCtx, setDialogState) {
                final isDark = Theme.of(dialogContentCtx).brightness == Brightness.dark;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isUploadingCert ? null : () => Navigator.pop(dialogCtx),
                      ),
                    ),
                    Center(
                      child: AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(
                    isUpdating ? 'Update Relocation Request' : 'Request Premise Relocation',
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
                                dialogErrorMessage = null;
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
                        const SizedBox(height: 16),
                        Text.rich(
                          TextSpan(
                            text: 'Updated Premise Certificate / License (Required):',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Attach updated SSM business registration, council premise license, or tenancy agreement so administrators can verify premise legitimacy.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (attachedCertFile != null || (certFileName != null && certFileName!.isNotEmpty)) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attachedCertFile?.name ?? certFileName ?? 'Premise Certificate',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF14532D),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (certFileSizeLabel != null)
                                        Text(
                                          certFileSizeLabel!,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: const Color(0xFF15803D),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      attachedCertFile = null;
                                      certFileName = null;
                                      certFileUrl = null;
                                      certFileSizeLabel = null;
                                    });
                                  },
                                  child: const Text('Remove', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: isUploadingCert
                                ? null
                                : () async {
                                    try {
                                      final picked = await fp.FilePicker.pickFiles(
                                        type: fp.FileType.custom,
                                        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                                      );
                                      if (picked.isNotEmpty) {
                                        final file = picked.first;
                                        final error = await DocumentValidator.validateDocument(
                                          file,
                                          documentTitle: 'Premise Verification Certificate',
                                        );
                                         if (error != null) {
                                           if (dialogContentCtx.mounted) {
                                             ScaffoldMessenger.of(dialogContentCtx).hideCurrentSnackBar();
                                             ScaffoldMessenger.of(dialogContentCtx).showSnackBar(
                                               SnackBar(
                                                 content: Text(error),
                                                 backgroundColor: const Color(0xFFEF4444),
                                                 behavior: SnackBarBehavior.floating,
                                               ),
                                             );
                                           }
                                           return;
                                         }
                                         final sizeLabel = DocumentValidator.formatFileSize(
                                           await file.length(),
                                         );
                                         setDialogState(() {
                                           attachedCertFile = file;
                                           certFileName = file.name;
                                           certFileSizeLabel = sizeLabel;
                                           showCertError = false;
                                           dialogErrorMessage = null;
                                         });
                                       }
                                     } catch (_) {}
                                   },
                             icon: const Icon(Icons.upload_file_rounded, size: 18),
                             label: Text(
                               'Attach Updated Certificate / License (PDF/Image)',
                               style: GoogleFonts.plusJakartaSans(fontSize: 12),
                             ),
                           ),
                         ],
                         if (showCertError && attachedCertFile == null && (certFileName == null || certFileName!.isEmpty)) ...[
                           const SizedBox(height: 8),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             decoration: BoxDecoration(
                               color: const Color(0xFFFEF2F2),
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(color: const Color(0xFFFCA5A5)),
                             ),
                             child: Row(
                               children: [
                                 const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     'Supporting relocation evidence document is required.',
                                     style: GoogleFonts.plusJakartaSans(
                                       fontSize: 11,
                                       fontWeight: FontWeight.w600,
                                       color: const Color(0xFFDC2626),
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
                         if (dialogErrorMessage != null &&
                             !(showCertError && attachedCertFile == null && (certFileName == null || certFileName!.isEmpty))) ...[
                           const SizedBox(height: 8),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             decoration: BoxDecoration(
                               color: const Color(0xFFFEF2F2),
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(color: const Color(0xFFFCA5A5)),
                             ),
                             child: Row(
                               children: [
                                 const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     dialogErrorMessage!,
                                     style: GoogleFonts.plusJakartaSans(
                                       fontSize: 11,
                                       fontWeight: FontWeight.w600,
                                       color: const Color(0xFFDC2626),
                                     ),
                                   ),
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
              actions: [
                 TextButton(
                   onPressed: isUploadingCert ? null : () => Navigator.pop(dialogCtx),
                   child: const Text('Cancel'),
                 ),
                 FilledButton(
                   onPressed: isUploadingCert
                       ? null
                       : () async {
                           if (proposedAddress == null || proposedPin == null) {
                             setDialogState(() {
                               dialogErrorMessage = 'Please select the proposed new workshop location on the map.';
                             });
                             ScaffoldMessenger.of(dialogContentCtx).hideCurrentSnackBar();
                             ScaffoldMessenger.of(dialogContentCtx).showSnackBar(
                               const SnackBar(
                                 content: Text('Please select the proposed new workshop location on the map.'),
                                 backgroundColor: Color(0xFFEF4444),
                                 behavior: SnackBarBehavior.floating,
                               ),
                             );
                             return;
                           }
                           final formValid = formKey.currentState?.validate() ?? false;
                           final hasCert = attachedCertFile != null ||
                               (certFileName != null && certFileName!.isNotEmpty) ||
                               (certFileUrl != null && certFileUrl!.isNotEmpty);

                           if (!hasCert) {
                             setDialogState(() {
                               showCertError = true;
                               dialogErrorMessage = 'Please attach supporting evidence (e.g. updated SSM registration or council permit) for premise relocation.';
                             });
                           }

                           if (!formValid || !hasCert) {
                             if (!hasCert) {
                               ScaffoldMessenger.of(dialogContentCtx).hideCurrentSnackBar();
                               ScaffoldMessenger.of(dialogContentCtx).showSnackBar(
                                 const SnackBar(
                                   content: Text('Please attach supporting evidence (e.g. updated SSM registration or council permit) for premise relocation.'),
                                   backgroundColor: Color(0xFFEF4444),
                                   behavior: SnackBarBehavior.floating,
                                 ),
                               );
                             }
                             return;
                           }

                          setDialogState(() => isUploadingCert = true);
                          final supabaseService = context.read<SupabaseService>();
                          if (attachedCertFile != null) {
                            try {
                              String? profileId = currentUser.artisanProfileId;
                              if (profileId != null && profileId.isNotEmpty) {
                                final uploadRes = await supabaseService.uploadArtisanDocument(
                                  profileId,
                                  attachedCertFile!,
                                  'RELOCATION_CERT',
                                );
                                if (uploadRes != null) {
                                  certFileUrl = uploadRes['url'];
                                  certFileName = uploadRes['name'] ?? attachedCertFile!.name;
                                } else {
                                  certFileName = attachedCertFile!.name;
                                }
                              } else {
                                certFileName = attachedCertFile!.name;
                              }
                            } catch (_) {
                              certFileName = attachedCertFile!.name;
                            }
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
                            certUrl: certFileUrl,
                            certName: certFileName,
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
                                  relocationCertFileName: certFileName,
                                  relocationCertFileUrl: certFileUrl,
                                  certFileName: certFileName,
                                  certFileUrl: certFileUrl,
                                  ssmFileName: certFileName,
                                  ssmFileUrl: certFileUrl,
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
                              SnackBar(
                                content: Text(isUpdating
                                    ? 'Relocation request updated for Administrative Review.'
                                    : 'Relocation request submitted for Administrative Review.'),
                                backgroundColor: const Color(0xFF047857),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: isUploadingCert
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isUpdating ? 'Update Request' : 'Submit Request'),
                ),
              ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

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
    final rawExp = _experienceController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final experience = rawExp.isNotEmpty ? '$rawExp Years' : null;
    final bio = _bioController.text.trim();
    final state = _stateController.text.trim();
    final phone = _phoneController.text.trim();

    final authVM = context.read<AuthViewModel>();

    if (username.isNotEmpty && username.toLowerCase() != _initialUsername?.toLowerCase()) {
      final isAvailable = await authVM.isUsernameAvailable(
        username,
        excludeEmail: authVM.currentUser?.email,
      );
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('@$username is already taken. Please choose another username handle.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      await authVM.updateProfile(
        username: username,
        displayName: studio.isNotEmpty ? studio : username,
        studioName: studio,
        craftCategory: craft,
        experience: experience,
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
            _experienceController.text = _isDefaultOrEmptyExperience(updatedUser.experience)
                ? ''
                : (updatedUser.experience ?? '');
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
            craftCategory: craft,
            state: state,
            phone: phone,
            bio: bio,
            experience: experience,
          );
        }
      } catch (_) {}

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _previewTouristView() {
    final user = context.read<AuthViewModel>().currentUser;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtisanDetailScreen(
          artisanName: _studioNameController.text.trim().isEmpty ? 'Artisan Studio' : _studioNameController.text.trim(),
          craftCategory: _craftCategoryController.text.trim().isEmpty ? 'Heritage Craft' : _craftCategoryController.text.trim(),
          state: _stateController.text.trim().isEmpty ? 'Malaysia' : _stateController.text.trim(),
          bio: _bioController.text.trim(),
          experience: _experienceController.text.trim().isNotEmpty
              ? '${_experienceController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')} Years'
              : '10+ Years',
          ssmNumber: user?.ssmNumber,
          documents: user?.artisanDocuments ?? const [],
          imageUrl: _portfolioImages.isNotEmpty
              ? _portfolioImages.first
              : (user?.avatarUrl ?? ''),
          imageUrls: _portfolioImages.isNotEmpty ? _portfolioImages : null,
          tags: _toolsAndMaterials,
          address: _workshopAddress,
          latitude: _selectedWorkshopPin?.latitude,
          longitude: _selectedWorkshopPin?.longitude,
          isLiveOpen: user?.isLiveOpen ?? true,
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : user?.phone,
          premiseType: user?.isVillageWorkshop == true
              ? 'Home / Village Workshop (Bengkel Kediaman / Desa)'
              : (user?.premiseType ?? 'Commercial Studio'),
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
      if (!mounted) return;
      final authVM = context.read<AuthViewModel>();
      final supabaseService = context.read<SupabaseService>();
      final user = authVM.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session not found. Please log in again.')),
        );
        return;
      }

      String? artisanProfileId = user.artisanProfileId;
      if (artisanProfileId == null || artisanProfileId.trim().isEmpty) {
        artisanProfileId = await supabaseService.ensureArtisanProfileId(
          user.id,
          email: user.email,
        );
        if (artisanProfileId != null && mounted) {
          unawaited(authVM.refreshCurrentUser());
        }
      }

      if (artisanProfileId == null || artisanProfileId.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find or initialize artisan profile ID.')),
          );
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading document...')),
        );
      }
      final uploadRes = await supabaseService.uploadArtisanDocument(
        artisanProfileId,
        file,
        docType,
      );
      
      if (!mounted) return;

      if (uploadRes != null) {
        setState(() {
          if (docType == 'PORTFOLIO_IMAGE') {
            _portfolioImages.add(uploadRes['url']!);
          } else if (docType == 'STUDIO_PHOTO') {
            _portfolioImages.add(uploadRes['url']!);
            _documents['CRAFTING_PHOTO'] = uploadRes['url']!;
            _documents[docType] = uploadRes['url']!;
          } else if (docType == 'CRAFTING_PHOTO') {
            _documents['CRAFTING_PHOTO'] = uploadRes['url']!;
            _documents[docType] = uploadRes['url']!;
          } else {
            _documents[docType] = uploadRes['url']!;
          }
        });
        unawaited(authVM.refreshCurrentUser());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed.')),
        );
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
    String? hintText,
    String? suffixText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
    Color? helperColor,
    String? errorText,
    Color? fillColor,
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : const Color(0xFF475569),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        fontSize: 13,
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: isDark ? Colors.white70 : const Color(0xFF475569),
        fontWeight: FontWeight.w600,
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
      fillColor: fillColor ??
          (readOnly
              ? (isDark ? const Color(0xFF0B1F1C) : const Color(0xFFF1F5F9))
              : (isDark ? const Color(0xFF0D2825) : Colors.white)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: readOnly
              ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0))
              : (isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1)),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: readOnly
              ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFFCBD5E1))
              : (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
          width: readOnly ? 1.0 : 1.8,
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
    final bool isVillage = currentUser?.isVillageWorkshop ?? false;
    final int ssmUploaded = _documents['SSM_BUSINESS_CERT'] != null ? 1 : 0;
    final int certUploaded = _documents['KRAFTANGAN_MASTER_CERT'] != null ? 1 : 0;
    final int craftingPhotoUploaded = _documents['CRAFTING_PHOTO'] != null ? 1 : 0;
    final int totalUploadedDocs = isVillage
        ? (craftingPhotoUploaded + certUploaded)
        : (ssmUploaded + certUploaded);
    final String docCounterText = isVillage
        ? (craftingPhotoUploaded > 0 ? '$totalUploadedDocs / 2 Uploaded' : '0 / 1 Required')
        : '$totalUploadedDocs / 2 Uploaded';
    final bool hasUploadedDocs = totalUploadedDocs > 0;

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Artisan Profile Builder',
            style: GoogleFonts.dmSerifDisplay(
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.transparent,
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
                'Preview',
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    decoration: BoxDecoration(
                      color: isVillage ? const Color(0xFF059669) : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVillage ? Icons.cottage_rounded : Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isVillage
                                    ? 'Verified Heritage Village Crafter (Approved)'
                                    : 'Verified Commercial Studio (Approved)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isVillage
                                    ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFFD1FAE5))
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVillage ? Icons.cottage_outlined : Icons.store_outlined,
                                    size: 11,
                                    color: isVillage ? const Color(0xFF047857) : const Color(0xFF0369A1),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isVillage ? 'VILLAGE' : 'COMMERCIAL',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isVillage ? const Color(0xFF047857) : const Color(0xFF0369A1),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isVillage
                              ? 'Premise: Home / Village Workshop (Bengkel Kediaman / Desa) • Legally exempted from SSM registration under the National Heritage Preservation Scheme.'
                              : 'Premise: Commercial Studio (Premis Komersial) • Active studio license verified by Kraftangan Malaysia Officers. Profile edits sync live.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : const Color(0xFF047857),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),



            const SizedBox(height: 24),

            Text(
              'Studio Information',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
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

            // Accredited Heritage Craft Category (Full-Width, Locked / Read-Only)
            TextFormField(
              controller: _craftCategoryController,
              readOnly: true,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              decoration: _inputDecoration(
                isDark,
                readOnly: true,
                labelText: 'Accredited Heritage Craft Category',
                prefixIcon: Icons.palette_outlined,
                suffixIcon: Tooltip(
                  message: 'Kraftangan Malaysia Accredited Craft Category (Locked)',
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  ),
                ),
                helperText: 'Official Kraftangan Malaysia accredited craft category (Locked)',
                helperColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
              ),
            ),

            const SizedBox(height: 14),

            // Phone Number Input (Full-Width)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => ProfileValidator.validatePhone(v, isRequired: true),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: _inputDecoration(
                isDark,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                helperText: 'Public workshop contact for tourist inquiries (e.g. +60 12-345 6789)',
              ),
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
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
                        color: Colors.black.withValues(alpha: 0.7),
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
                    Text(
                      'Public directory shows current verified address until approved.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _openRelocationDialog,
                          icon: const Icon(Icons.edit_location_alt_rounded, size: 14),
                          label: const Text(
                            'Change Location',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                        if (currentUser != null &&
                            currentUser.pendingRelocationLatitude != null &&
                            currentUser.pendingRelocationLongitude != null)
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => ProfileValidator.validateExperience(v, isRequired: false),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: _inputDecoration(
                isDark,
                labelText: 'Years of Craft Experience',
                hintText: 'e.g. 15',
                suffixText: 'Years',
                prefixIcon: Icons.workspace_premium_outlined,
                helperText: 'Enter your years of craft heritage experience in numbers (e.g. 15)',
              ),
            ),

            const SizedBox(height: 14),

            // Bio Input
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.keyboard_hide_rounded,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  ),
                  tooltip: 'Done / Exit Keyboard',
                  onPressed: () => FocusScope.of(context).unfocus(),
                ),
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
                    color: isDark
                        ? (hasUploadedDocs ? const Color(0xFF0D2825) : const Color(0xFF1E293B))
                        : (hasUploadedDocs ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: isDark
                        ? Border.all(color: hasUploadedDocs ? const Color(0xFF1E3A34) : const Color(0xFF334155))
                        : null,
                  ),
                  child: Text(
                    docCounterText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? (hasUploadedDocs ? const Color(0xFF34D399) : const Color(0xFF94A3B8))
                          : (hasUploadedDocs ? const Color(0xFF047857) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isVillage
                  ? 'Village crafters are recognized under the National Heritage Preservation Scheme. Verification relies on your authentic craft proof photos.'
                  : 'Upload official certificates to populate master credentials on the Tourist Profile view.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            if (isVillage) ...[
              // Dedicated SSM Exemption Notice Card
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2825) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF059669),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Business Registration (SSM)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'EXEMPTED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Exempted (Village Crafter) • Traditional Home / Village Crafters are legally exempted from SSM registration under the National Heritage Preservation Scheme. Verification relies on your authentic craft proof photos.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF047857),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Crafting Proof Photo Tile
              _buildDocumentUploadTile(
                isDark: isDark,
                title: 'Traditional Crafting Proof Photo',
                subtitle: _documents['CRAFTING_PHOTO'] != null
                    ? 'Uploaded & Verified Proof'
                    : 'Required for Village Crafters',
                icon: Icons.photo_camera_rounded,
                isUploaded: _documents['CRAFTING_PHOTO'] != null,
                onTap: () => _uploadDocument('CRAFTING_PHOTO'),
                onView: _documents['CRAFTING_PHOTO'] != null
                    ? () => _viewDocument(_documents['CRAFTING_PHOTO']!)
                    : null,
              ),

              // Optional Kraftangan Master Certification
              _buildDocumentUploadTile(
                isDark: isDark,
                title: 'Kraftangan Malaysia Master Certification',
                subtitle: _documents['KRAFTANGAN_MASTER_CERT'] != null
                    ? 'Uploaded Document'
                    : 'Optional',
                icon: Icons.workspace_premium_rounded,
                isUploaded: _documents['KRAFTANGAN_MASTER_CERT'] != null,
                onTap: () => _uploadDocument('KRAFTANGAN_MASTER_CERT'),
                onView: _documents['KRAFTANGAN_MASTER_CERT'] != null
                    ? () => _viewDocument(_documents['KRAFTANGAN_MASTER_CERT']!)
                    : null,
              ),
            ] else ...[
              // Commercial Studio SSM Certificate Tile
              _buildDocumentUploadTile(
                isDark: isDark,
                title: 'Business Registration (SSM) Certificate',
                subtitle: _documents['SSM_BUSINESS_CERT'] != null
                    ? 'Uploaded Document'
                    : 'Required',
                icon: Icons.article_rounded,
                isUploaded: _documents['SSM_BUSINESS_CERT'] != null,
                onTap: () => _uploadDocument('SSM_BUSINESS_CERT'),
                onView: _documents['SSM_BUSINESS_CERT'] != null
                    ? () => _viewDocument(_documents['SSM_BUSINESS_CERT']!)
                    : null,
              ),

              // Commercial Studio Kraftangan Master Certification
              _buildDocumentUploadTile(
                isDark: isDark,
                title: 'Kraftangan Malaysia Master Certification',
                subtitle: _documents['KRAFTANGAN_MASTER_CERT'] != null
                    ? 'Uploaded Document'
                    : 'Optional',
                icon: Icons.workspace_premium_rounded,
                isUploaded: _documents['KRAFTANGAN_MASTER_CERT'] != null,
                onTap: () => _uploadDocument('KRAFTANGAN_MASTER_CERT'),
                onView: _documents['KRAFTANGAN_MASTER_CERT'] != null
                    ? () => _viewDocument(_documents['KRAFTANGAN_MASTER_CERT']!)
                    : null,
              ),
            ],

            const SizedBox(height: 36),

            // Save & Preview Buttons Section
            if (_hasUnsavedChanges) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                    disabledBackgroundColor: isDark
                        ? const Color(0xFFFFD54F).withValues(alpha: 0.5)
                        : const Color(0xFF004D40).withValues(alpha: 0.5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? const Color(0xFF041412) : Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Saving Changes...' : 'Save Profile Changes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _previewTouristView,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    width: 1.5,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFFFFD54F).withValues(alpha: 0.05)
                      : const Color(0xFF004D40).withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(
                  Icons.visibility_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                ),
                label: Text(
                  'Preview Tourist View',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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