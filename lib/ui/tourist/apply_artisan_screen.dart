import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/validators/profile_validator.dart';
import 'package:warisan_kita/domain/validators/ssm_validator.dart';
import 'package:warisan_kita/domain/validators/document_validator.dart';
import 'package:warisan_kita/domain/models/user.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'widgets/workshop_map_picker.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';

class ApplyArtisanScreen extends StatefulWidget {
  const ApplyArtisanScreen({super.key});

  @override
  State<ApplyArtisanScreen> createState() => _ApplyArtisanScreenState();
}

class _ApplyArtisanScreenState extends State<ApplyArtisanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studioNameController = TextEditingController();
  final _ssmController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationSearchController = TextEditingController();

  static const String premiseCommercial = 'Commercial Studio (Premis Perniagaan)';
  static const String premiseVillage = 'Home / Village Workshop (Bengkel Kediaman / Desa)';

  String _selectedPremiseType = premiseCommercial;
  bool get _isVillageWorkshop => _selectedPremiseType == premiseVillage;

  final List<String> _premiseTypes = const [
    premiseCommercial,
    premiseVillage,
  ];

  String _selectedCraftCategory = 'Woodwork';
  String _selectedState = 'Melaka';
  bool _isSubmitting = false;

  Timer? _ssmDebounce;
  bool _isCheckingSsm = false;
  bool? _isSsmAvailable;
  String? _ssmStatusMessage;

  Timer? _phoneDebounce;
  bool _isCheckingPhone = false;
  bool? _isPhoneAvailable;
  String? _phoneStatusMessage;

  @override
  void initState() {
    super.initState();
    _ssmController.addListener(_onSsmChanged);
    _phoneController.addListener(_onPhoneChanged);

    Future.microtask(() async {
      if (!mounted) return;
      await context.read<AuthViewModel>().refreshCurrentUser();
    });
  }

  @override
  void dispose() {
    _ssmDebounce?.cancel();
    _ssmController.removeListener(_onSsmChanged);
    _phoneDebounce?.cancel();
    _phoneController.removeListener(_onPhoneChanged);
    _studioNameController.dispose();
    _ssmController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationSearchController.dispose();
    _workshopMapController?.dispose();
    super.dispose();
  }

  void _onSsmChanged() {
    _ssmDebounce?.cancel();
    final raw = _ssmController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _isCheckingSsm = false;
        _isSsmAvailable = null;
        _ssmStatusMessage = null;
      });
      return;
    }

    final formatErr = SsmValidator.validate(raw);
    if (formatErr != null) {
      setState(() {
        _isCheckingSsm = false;
        _isSsmAvailable = false;
        _ssmStatusMessage = formatErr;
      });
      return;
    }

    setState(() {
      _isCheckingSsm = true;
      _ssmStatusMessage = 'Validating SSM availability...';
    });

    _ssmDebounce = Timer(const Duration(milliseconds: 350), () async {
      final authVM = context.read<AuthViewModel>();
      final isAvailable = await authVM.isSsmAvailable(raw);
      if (!mounted) return;
      setState(() {
        _isCheckingSsm = false;
        _isSsmAvailable = isAvailable;
        _ssmStatusMessage = isAvailable
            ? '✓ Validated & Available SSM Registration ID'
            : '⚠️ This SSM is already registered by another artisan studio';
      });
    });
  }

  void _onPhoneChanged() {
    _phoneDebounce?.cancel();
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _isCheckingPhone = false;
        _isPhoneAvailable = null;
        _phoneStatusMessage = null;
      });
      return;
    }

    final formatErr = ProfileValidator.validatePhone(raw, isRequired: false);
    if (formatErr != null) {
      setState(() {
        _isCheckingPhone = false;
        _isPhoneAvailable = false;
        _phoneStatusMessage = formatErr;
      });
      return;
    }

    setState(() {
      _isCheckingPhone = true;
      _phoneStatusMessage = 'Checking whether this phone number is registered…';
    });

    _phoneDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final authVM = context.read<AuthViewModel>();
        final isAvailable = await authVM.isPhoneAvailable(
          raw,
          excludeEmail: authVM.currentUser?.email,
          excludeUserId: authVM.currentUser?.id,
        );
        if (!mounted || _phoneController.text.trim() != raw) return;
        setState(() {
          _isCheckingPhone = false;
          _isPhoneAvailable = isAvailable;
          _phoneStatusMessage = isAvailable
              ? '✓ This contact phone number is available'
              : '⚠️ This phone number is already registered by another account';
        });
      } catch (_) {
        if (!mounted || _phoneController.text.trim() != raw) return;
        setState(() {
          _isCheckingPhone = false;
          _isPhoneAvailable = null;
          _phoneStatusMessage = 'Unable to check phone number availability right now.';
        });
      }
    });
  }
  
  final List<String> _toolsAndMaterials = [];

  PlatformFile? _ssmFile;
  PlatformFile? _kraftanganFile;
  final List<PlatformFile> _uploadedPhotos = [];
  String? _ssmFileSizeLabel;
  String? _kraftanganFileSizeLabel;
  String? _documentError;
  GoogleMapController? _workshopMapController;
  LatLng? _workshopLocation;
  String? _workshopAddress;
  String? _locationError;
  bool _isSearchingLocation = false;

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

  final List<String> _craftCategories = const [
    'Woodwork',
    'Songket & Weaving',
    'Batik & Textiles',
    'Pottery & Ceramics',
    'Metalwork & Pewter',
    'Heritage Food',
    'Wayang Kulit & Puppetry',
    'Rattan & Bamboo Craft',
  ];

  final List<String> _malaysiaStates = const [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
  ];

  LatLng get _selectedStateCenter =>
      _stateCenters[_selectedState] ?? _stateCenters['Melaka']!;

  Future<void> _searchWorkshopLocation() async {
    final query = _locationSearchController.text.trim();
    if (query.isEmpty) {
      setState(() => _locationError = 'Enter a workshop name or address.');
      return;
    }

    setState(() {
      _isSearchingLocation = true;
      _locationError = null;
    });

    try {
      final matches = await WorkshopPlaceSearch.search(
        query: query,
        targetState: _selectedState,
      );
      if (matches.isEmpty) {
        throw StateError('No matching place was found.');
      }

      if (!mounted) return;
      final match = matches.length == 1
          ? matches.first
          : await _chooseWorkshopPlace(matches);
      if (match == null || !mounted) return;

      if (match.malaysiaState != null &&
          match.malaysiaState!.toLowerCase() != _selectedState.toLowerCase()) {
        setState(() {
          _locationError =
              'Selected location is in ${match.malaysiaState}, but workshop state is $_selectedState. Please select a location within $_selectedState.';
        });
        return;
      }

      _applyWorkshopPlace(match);
      await _workshopMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(match.position, 17),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError =
            'Place not found in $_selectedState. Try a more complete address.';
      });
    } finally {
      if (mounted) setState(() => _isSearchingLocation = false);
    }
  }

  void _applyWorkshopPlace(WorkshopPlaceResult place) {
    if (place.malaysiaState != null &&
        place.malaysiaState!.toLowerCase() != _selectedState.toLowerCase()) {
      setState(() {
        _locationError =
            'Selected location is in ${place.malaysiaState}, but workshop state is $_selectedState. Please select a location in $_selectedState.';
      });
      return;
    }
    setState(() {
      _workshopLocation = place.position;
      _workshopAddress = place.displayName;
      _locationSearchController.text = place.displayName;
      _locationError = null;
    });
  }

  Future<WorkshopPlaceResult?> _chooseWorkshopPlace(
    List<WorkshopPlaceResult> matches,
  ) {
    return showModalBottomSheet<WorkshopPlaceResult>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Choose Workshop Location',
                style: GoogleFonts.dmSerifDisplay(
                  color: const Color(0xFF004D40),
                  fontSize: 21,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: matches.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final place = matches[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3D6),
                      foregroundColor: Color(0xFFD97706),
                      child: Icon(Icons.location_on_rounded),
                    ),
                    title: Text(
                      place.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(place),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveMapToSelectedState(String state) async {
    final center = _stateCenters[state];
    if (center == null) return;
    await _workshopMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(center, 12),
    );
  }

  Future<void> _openWorkshopMapPicker() async {
    final selected = await Navigator.of(context).push<WorkshopPlaceResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorkshopMapPickerPage(
          initialState: _selectedState,
          initialLocation: _workshopLocation,
          initialAddress: _workshopAddress,
          stateCenters: _stateCenters,
          lockedState: _selectedState,
        ),
      ),
    );
    if (selected == null || !mounted) return;

    _applyWorkshopPlace(selected);
    await _workshopMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(selected.position, 17),
    );
  }

  Future<void> _pickSsmDocument() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (file != null) {
        final error = await DocumentValidator.validateDocument(
          file,
          documentTitle: _isVillageWorkshop
              ? 'Crafting Photo Evidence'
              : 'SSM Business Registration Document',
        );
        if (error != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final sizeLabel = DocumentValidator.formatFileSize(
          await file.length(),
        );
        if (!mounted) return;
        setState(() {
          _ssmFile = file;
          _ssmFileSizeLabel = sizeLabel;
          _documentError = null;
        });
        if (mounted) {
          final docLabel = _isVillageWorkshop
              ? 'Crafting photo attached'
              : 'SSM Document validated & attached';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isVillageWorkshop
                    ? '📸 $docLabel: ${_ssmFile!.name}'
                    : '📄 $docLabel: ${_ssmFile!.name}',
              ),
              backgroundColor: const Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _pickKraftanganCertificate() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (file != null) {
        final error = await DocumentValidator.validateDocument(
          file,
          documentTitle: 'Kraftangan Master Certificate',
        );
        if (error != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final sizeLabel = DocumentValidator.formatFileSize(
          await file.length(),
        );
        if (!mounted) return;
        setState(() {
          _kraftanganFile = file;
          _kraftanganFileSizeLabel = sizeLabel;
          _documentError = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🏆 Kraftangan Certificate validated & attached: ${_kraftanganFile!.name}',
              ),
              backgroundColor: const Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _pickStudioPhotos() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);

      if (files.isNotEmpty) {
        setState(() {
          _uploadedPhotos.addAll(files);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📸 Studio workshop photo attached (${files.length} files)',
              ),
              backgroundColor: const Color(0xFF004D40),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    final ssm = _ssmController.text.trim();
    final authVM = context.read<AuthViewModel>();

    if (ssm.isNotEmpty) {
      final isAvailable = await authVM.isSsmAvailable(ssm);
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ This SSM registration number is already registered by another artisan studio.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else if (!_isVillageWorkshop) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide your SSM or Kraftangan registration number.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (ssm.isNotEmpty && _isSsmAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _ssmStatusMessage ??
                'Please provide a valid, registered SSM or Kraftangan number.',
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final phoneText = _phoneController.text.trim();
    if (phoneText.isNotEmpty) {
      _phoneDebounce?.cancel();
      final phoneErr = ProfileValidator.validatePhone(phoneText, isRequired: false);
      if (phoneErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(phoneErr),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        _isCheckingPhone = true;
      });
      try {
        final isPhoneAvail = await authVM.isPhoneAvailable(
          phoneText,
          excludeEmail: authVM.currentUser?.email,
          excludeUserId: authVM.currentUser?.id,
        );
        if (!mounted) return;
        setState(() {
          _isCheckingPhone = false;
          _isPhoneAvailable = isPhoneAvail;
          _phoneStatusMessage = isPhoneAvail
              ? '✓ This contact phone number is available'
              : '⚠️ This phone number is already registered by another account';
        });
        if (!isPhoneAvail) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ This contact phone number is already registered by another artisan studio or account.'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isCheckingPhone = false;
          _isPhoneAvailable = null;
          _phoneStatusMessage = 'Unable to check phone number availability right now.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to verify contact phone number with the database. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (_workshopLocation == null || _workshopAddress == null) {
      setState(() {
        _locationError =
            'Search for your workshop or tap the map to place its pin.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pin your workshop location before submitting.'),
          backgroundColor: Color(0xFFB42318),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Enforce mandatory authentic document validation
    final ssmDocTitle = _isVillageWorkshop
        ? 'Crafting Photo Evidence'
        : 'SSM Business Registration Document';
    final ssmError = await DocumentValidator.validateDocument(
      _ssmFile,
      documentTitle: ssmDocTitle,
      isMandatory: true,
    );
    if (!mounted) return;
    if (ssmError != null) {
      setState(() => _documentError = ssmError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ssmError),
          backgroundColor: const Color(0xFFB42318),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Kraftangan Certificate: Mandatory for commercial studio, optional for village workshop
    final certError = await DocumentValidator.validateDocument(
      _kraftanganFile,
      documentTitle: 'Kraftangan Master Accreditation Certificate',
      isMandatory: !_isVillageWorkshop,
    );
    if (!mounted) return;
    if (certError != null) {
      setState(() => _documentError = certError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(certError),
          backgroundColor: const Color(0xFFB42318),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _documentError = null;
      _isSubmitting = true;
    });

    UserModel? user = authVM.currentUser;
    if (user == null || user.email.trim().isEmpty) {
      user = await authVM.restoreSession();
    }
    if (!mounted) return;
    final studioName = _studioNameController.text.trim();
    final expDigits = _experienceController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final experience = expDigits.isNotEmpty ? '$expDigits Years' : null;
    final bio = _bioController.text.trim();
    final phone = phoneText.isNotEmpty ? phoneText : null;

    final effectiveEmail = user?.email.trim() ?? '';

    if (effectiveEmail.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in with your tourist account to apply.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await authVM.linkArtisanToExistingTourist(
      email: effectiveEmail,
      studioName: studioName,
      craftCategory: _selectedCraftCategory,
      ssmNumber: ssm,
      experience: experience,
      bio: bio.isNotEmpty ? bio : null,
      phone: phone,
      state: _selectedState,
      address: _workshopAddress,
      latitude: _workshopLocation!.latitude,
      longitude: _workshopLocation!.longitude,
      toolsAndMaterials: _toolsAndMaterials,
      ssmFile: _ssmFile,
      certFile: _kraftanganFile,
      photos: _uploadedPhotos,
      premiseType: _selectedPremiseType,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Application submission failed'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final updatedUser = authVM.currentUser ?? user;
      context.read<ModerationViewModel>().addPendingArtisan(
        PendingArtisanProfile(
          id: updatedUser?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
          name: studioName,
          craftCategory: _selectedCraftCategory,
          state: _selectedState,
          dateSubmitted: 'Just Now',
          imageUrl: updatedUser?.avatarUrl ?? '',
          email: updatedUser?.email ?? '',
          experience: (experience != null && experience.isNotEmpty) ? experience : 'Craft Artisan',
          phone: phone ?? '',
          ssmNumber: ssm.isNotEmpty ? ssm : (_isVillageWorkshop ? 'Village Crafter (Endorsement Letter)' : null),
          ssmFileName: _ssmFile?.name ?? updatedUser?.ssmFileName,
          ssmFileUrl: updatedUser?.ssmFileUrl,
          certFileName: _kraftanganFile?.name ?? updatedUser?.certFileName,
          certFileUrl: updatedUser?.certFileUrl,
          photos: _uploadedPhotos.map((p) => p.name).toList(),
          bio: bio.isNotEmpty
              ? bio
              : '${_isVillageWorkshop ? 'Village craft workshop' : 'Master studio'} application for $_selectedCraftCategory in $_selectedState.',
          isUpgradeFromTourist: true,
          premiseType: _selectedPremiseType,
        ),
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'STUDIO APPLICATION SUBMITTED: Under Kraftangan Admin Review!',
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ArtisanApplicationPendingScreen(
          studioName: studioName,
          craftCategory: _selectedCraftCategory,
          ssmNumber: ssm,
          premiseType: _selectedPremiseType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Apply for Master Artisan',
            style: GoogleFonts.dmSerifDisplay(
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              fontSize: 22,
            ),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: 20,
              ),
              child: Container(
                width: isDesktop ? 600 : double.infinity,
                padding: EdgeInsets.all(isDesktop ? 28.0 : 20.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2825) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: isDark ? Border.all(color: const Color(0xFF1E3A34)) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF231F10) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF78350F) : const Color(0xFFFCD34D),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kraftangan Malaysia Accreditation',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Register your heritage workshop to host interactive quests, create unique QR keys, and gain verified status on the live directory.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFFFFE082) : const Color(0xFF78350F),
                                      height: 1.3,
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
                        'Studio & Workshop Details',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Premise Type Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedPremiseType,
                        dropdownColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Premise Type *',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          prefixIcon: Icon(
                            _isVillageWorkshop ? Icons.holiday_village_outlined : Icons.storefront_outlined,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          helperText: _isVillageWorkshop
                              ? 'Village crafters: SSM & certificates are exempted. You only need to show a crafting photo!'
                              : 'Commercial studios: SSM business registration is mandatory.',
                          helperMaxLines: 2,
                          helperStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _isVillageWorkshop
                                ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF047857))
                                : (isDark ? Colors.white54 : Colors.grey[600]),
                            fontWeight: _isVillageWorkshop ? FontWeight.w600 : FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: _premiseTypes
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _selectedPremiseType = v;
                            if (_isVillageWorkshop && _ssmController.text.trim().isEmpty) {
                              _isCheckingSsm = false;
                              _isSsmAvailable = null;
                              _ssmStatusMessage = null;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Studio Name
                      TextFormField(
                        controller: _studioNameController,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Studio Name *',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          hintText: 'e.g. Pak Mat Pottery & Ceramics Studio',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                          prefixIcon: Icon(
                            Icons.storefront_rounded,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: ProfileValidator.validateStudioName,
                      ),

                      const SizedBox(height: 16),

                      // Craft Category Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedCraftCategory,
                        dropdownColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Heritage Craft Category *',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          prefixIcon: Icon(
                            Icons.palette_outlined,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: _craftCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCraftCategory = v!),
                      ),

                      const SizedBox(height: 16),

                      // State / Location Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedState,
                        dropdownColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Workshop State / Region *',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: _malaysiaStates
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _selectedState = v;
                            _workshopLocation = null;
                            _workshopAddress = null;
                            _locationError = null;
                            _locationSearchController.clear();
                          });
                          _moveMapToSelectedState(v);
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildWorkshopLocationPicker(),

                      const SizedBox(height: 16),

                      // SSM Registration Number
                      TextFormField(
                        controller: _ssmController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          labelText: _isVillageWorkshop
                              ? 'SSM / Kraftangan Reg. No. (Optional for Village Crafters)'
                              : 'SSM / Kraftangan Reg. No. *',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          hintText: _isVillageWorkshop
                              ? 'Optional for village workshops (e.g. 202601004821 or leave empty)'
                              : 'e.g. 202601004821 or KT/2026/0491',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          suffixIcon: _isCheckingSsm
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                                    ),
                                  ),
                                )
                              : (_isSsmAvailable != null
                                  ? Icon(
                                      _isSsmAvailable!
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: _isSsmAvailable!
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    )
                                  : null),
                          helperText: _ssmController.text.trim().isEmpty && _isVillageWorkshop
                              ? 'Optional: Village crafters do not need SSM — only a crafting photo is required.'
                              : (_isSsmAvailable == true
                                  ? _ssmStatusMessage
                                  : 'Format: 12-digit SSM (202601004821), ROB (123456-A), or Kraftangan (KT/2026/0491)'),
                          helperStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: _isSsmAvailable == true
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _isSsmAvailable == true
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white54 : Colors.grey[600]),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          errorMaxLines: 3,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) {
                          final trimmed = (v ?? '').trim();
                          if (_isVillageWorkshop && trimmed.isEmpty) {
                            return null;
                          }
                          final formatErr = SsmValidator.validate(v);
                          if (formatErr != null) return formatErr;
                          if (_isSsmAvailable == false) {
                            return _ssmStatusMessage ?? 'This SSM number is already registered';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Contact Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Studio Contact Phone',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          hintText: 'e.g. 012-345 6789 or +60123456789',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          suffixIcon: _isCheckingPhone
                              ? Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? const Color(0xFFFFD54F)
                                          : const Color(0xFF004D40),
                                    ),
                                  ),
                                )
                              : (_phoneStatusMessage == null
                                  ? null
                                  : Icon(
                                      _isPhoneAvailable == true
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.error_outline_rounded,
                                      color: _isPhoneAvailable == true
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFDC2626),
                                    )),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          errorMaxLines: 2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          helperText: _phoneStatusMessage,
                          helperStyle: TextStyle(
                            color: _isCheckingPhone
                                ? const Color(0xFFD97706)
                                : (_isPhoneAvailable == true
                                    ? const Color(0xFF10B981)
                                    : (_isPhoneAvailable == false
                                        ? const Color(0xFFEF4444)
                                        : (isDark ? Colors.white60 : Colors.grey[600]))),
                            fontSize: 11,
                            fontWeight: _isPhoneAvailable != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) {
                          final trimmed = (v ?? '').trim();
                          if (trimmed.isEmpty) return null;
                          final formatErr = ProfileValidator.validatePhone(trimmed, isRequired: false);
                          if (formatErr != null) return formatErr;
                          if (_isPhoneAvailable == false) {
                            return 'This phone number is already registered by another user';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Years of Craft Experience
                      TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Years of Craft Experience *',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          hintText: 'e.g. 15',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                          suffixText: 'Years',
                          suffixStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          prefixIcon: Icon(
                            Icons.workspace_premium_outlined,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          helperText: 'Enter your years of craft heritage experience in numbers (e.g. 15)',
                          helperStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) => ProfileValidator.validateExperience(v, isRequired: true),
                      ),

                      const SizedBox(height: 16),

                      // Bio / Heritage Description
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                        validator: (v) => ProfileValidator.validateBio(
                          v,
                          isRequired: true,
                          minLength: 15,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Studio Heritage Bio *',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          hintText:
                              'Describe your craft background, workshop history, and master lineage (min 15 chars)...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 45),
                            child: Icon(
                              Icons.history_edu_rounded,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.keyboard_hide_rounded,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            ),
                            tooltip: 'Done / Exit Keyboard',
                            onPressed: () => FocusScope.of(context).unfocus(),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Traditional Materials & Tools Used',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 16,
                          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._toolsAndMaterials.map((tool) => Chip(
                                backgroundColor: isDark ? const Color(0xFF041412) : null,
                                side: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : null,
                                label: Text(
                                  tool,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: isDark ? Colors.white : null,
                                  ),
                                ),
                                deleteIcon: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: isDark ? Colors.white70 : null,
                                ),
                                onDeleted: () {
                                  setState(() => _toolsAndMaterials.remove(tool));
                                },
                              )),
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              size: 14,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                            ),
                            label: Text(
                              'Add Tool/Material',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                              ),
                            ),
                            backgroundColor: isDark ? const Color(0xFF231F10) : const Color(0xFFFEF3C7),
                            side: isDark ? const BorderSide(color: Color(0xFF78350F)) : BorderSide.none,
                            onPressed: () {
                              final textController = TextEditingController();
                              final dialogFormKey = GlobalKey<FormState>();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: isDark ? const Color(0xFF0D2825) : null,
                                  title: Text(
                                    'Add Traditional Tool or Material',
                                    style: GoogleFonts.dmSerifDisplay(
                                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                                    ),
                                  ),
                                  content: Form(
                                    key: dialogFormKey,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    child: TextFormField(
                                      controller: textController,
                                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                      validator: (v) => ProfileValidator.validateTag(
                                        v,
                                        _toolsAndMaterials,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Natural Indigo Dye',
                                        hintStyle: TextStyle(
                                          color: isDark ? Colors.white38 : Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : null,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (dialogFormKey.currentState?.validate() ?? false) {
                                          setState(() => _toolsAndMaterials.add(textController.text.trim()));
                                          Navigator.pop(context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? const Color(0xFF1E3A34) : null,
                                        foregroundColor: isDark ? const Color(0xFFFFD54F) : null,
                                      ),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Proof of Authenticity & Credentials',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 16,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3B1212) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? const Color(0xFF991B1B) : const Color(0xFFF87171),
                              ),
                            ),
                            child: Text(
                              'MANDATORY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isVillageWorkshop
                            ? 'Village and home craft workshops only need to upload a photo of your handmade craftwork or crafting process to qualify for verified artisan status.'
                            : 'Both official SSM business registration and your Kraftangan Malaysia accreditation certificate are required for verified Master Artisan status.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Document Pickers
                      _buildUploadTile(
                        icon: _isVillageWorkshop ? Icons.photo_camera_outlined : Icons.description_outlined,
                        title: _isVillageWorkshop
                            ? '1. Crafting Photo Evidence *'
                            : '1. SSM Business Registration PDF / Image *',
                        subtitle: _ssmFile != null
                            ? 'Attached: ${_ssmFile!.name} ($_ssmFileSizeLabel)'
                            : _isVillageWorkshop
                                ? 'Upload a clear photo of your craftwork or crafting process (JPG/PNG, up to 10 MB)'
                                : 'Upload official SSM business certificate (10 KB – 10 MB)',
                        isAttached: _ssmFile != null,
                        onTap: _pickSsmDocument,
                        onRemove: _ssmFile != null
                            ? () {
                                setState(() {
                                  _ssmFile = null;
                                  _ssmFileSizeLabel = null;
                                  _documentError = null;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _isVillageWorkshop
                                          ? 'Crafting photo unattached'
                                          : 'SSM document unattached',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                      ),

                      const SizedBox(height: 10),

                      _buildUploadTile(
                        icon: Icons.workspace_premium_outlined,
                        title: _isVillageWorkshop
                            ? '2. Kraftangan Certificate (Optional for Village Crafters)'
                            : '2. Kraftangan Master Certificate *',
                        subtitle: _kraftanganFile != null
                            ? 'Attached: ${_kraftanganFile!.name} ($_kraftanganFileSizeLabel)'
                            : _isVillageWorkshop
                                ? 'Optional for village workshops — upload if available'
                                : 'Upload accreditation certificate from Kraftangan Malaysia',
                        isAttached: _kraftanganFile != null,
                        onTap: _pickKraftanganCertificate,
                        onRemove: _kraftanganFile != null
                            ? () {
                                setState(() {
                                  _kraftanganFile = null;
                                  _kraftanganFileSizeLabel = null;
                                  _documentError = null;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kraftangan Master Certificate unattached'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                      ),

                      const SizedBox(height: 10),

                      _buildUploadTile(
                        icon: Icons.photo_camera_outlined,
                        title: 'Studio Workshop Photos (Optional)',
                        subtitle: _uploadedPhotos.isNotEmpty
                            ? 'Attached ${_uploadedPhotos.length} photo(s)'
                            : 'Upload photos of your craft studio/workshop',
                        isAttached: _uploadedPhotos.isNotEmpty,
                        onTap: _pickStudioPhotos,
                        onRemove: _uploadedPhotos.isNotEmpty
                            ? () {
                                setState(() {
                                  _uploadedPhotos.clear();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('All studio photos unattached'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                      ),

                      if (_uploadedPhotos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _uploadedPhotos.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final photo = entry.value;
                            return Chip(
                              avatar: const Icon(
                                Icons.image_outlined,
                                size: 16,
                                color: Color(0xFF004D40),
                              ),
                              label: Text(
                                photo.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.cancel_rounded,
                                size: 16,
                                color: Color(0xFFEF4444),
                              ),
                              onDeleted: () {
                                setState(() {
                                  _uploadedPhotos.removeAt(idx);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed photo: ${photo.name}'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              backgroundColor: isDark
                                  ? const Color(0xFF041412)
                                  : const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E3A34)
                                    : const Color(0xFFCBD5E1),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (_documentError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3B1212) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _documentError!,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submitApplication,
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                            foregroundColor: isDark ? const Color(0xFFFFD54F) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Submit Artisan Application',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFFFD54F) : Colors.white,
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
      ),
    );
  }

  Widget _buildWorkshopLocationPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pin = _workshopLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workshop Location *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationSearchController,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => _searchWorkshopLocation(),
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search workshop name or address in $_selectedState',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            ),
            suffixIcon: _isSearchingLocation
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'Search place',
                    onPressed: _searchWorkshopLocation,
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                    ),
                  ),
            filled: true,
            fillColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
            errorText: _locationError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: isDark ? const BorderSide(color: Color(0xFF1E3A34)) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF041412) : const Color(0xFFE8EFEC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pin == null
                  ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFFD7E0DC))
                  : const Color(0xFF10B981),
              width: pin == null ? 1 : 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedStateCenter,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _workshopMapController = controller;
                    },
                    markers: pin == null
                        ? const <Marker>{}
                        : {
                            Marker(
                              markerId: const MarkerId('workshop-location'),
                              position: pin,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueOrange,
                              ),
                            ),
                          },
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: _openWorkshopMapPicker),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_full_rounded,
                            color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Open Large Map',
                            style: GoogleFonts.plusJakartaSans(
                              color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
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
            Icon(
              pin == null
                  ? Icons.touch_app_rounded
                  : Icons.check_circle_rounded,
              size: 16,
              color: pin == null
                  ? (isDark ? Colors.white54 : const Color(0xFF64748B))
                  : const Color(0xFF10B981),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                pin == null
                    ? 'Search above or open the large map to place the exact workshop pin.'
                    : _workshopAddress ?? 'Resolving the selected address…',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  height: 1.35,
                  color: pin == null
                      ? (isDark ? Colors.white60 : const Color(0xFF64748B))
                      : (isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isAttached,
    required VoidCallback onTap,
    VoidCallback? onRemove,
    String removeTooltip = 'Unsubmit / Remove attached document',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (isAttached ? const Color(0xFF063529) : const Color(0xFF041412))
            : (isAttached ? const Color(0xFFECFDF5) : const Color(0xFFF8F9FA)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAttached
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF1E3A34) : Colors.grey[300]!),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAttached
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1E3A34) : Colors.grey[200]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAttached ? Icons.check_circle_rounded : icon,
                    color: isAttached
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: isDark
                              ? (isAttached ? const Color(0xFF34D399) : Colors.white60)
                              : (isAttached ? const Color(0xFF047857) : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAttached && onRemove != null) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    ),
                    tooltip: removeTooltip,
                    onPressed: onRemove,
                  ),
                ] else
                  Icon(
                    Icons.upload_file_rounded,
                    size: 18,
                    color: isAttached
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white38 : Colors.grey[500]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

