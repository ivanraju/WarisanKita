import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../tourist/widgets/workshop_map_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
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
  late final TextEditingController _usernameController;
  late final TextEditingController _studioNameController;
  late final TextEditingController _craftCategoryController;
  late final TextEditingController _stateController;
  late final TextEditingController _experienceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  GoogleMapController? _workshopMapController;
  LatLng? _selectedWorkshopPin;
  String? _workshopAddress;

  static const Map<String, LatLng> _stateCenters = {
    'Johor': LatLng(2.0301, 103.3185),
    'Kedah': LatLng(6.1184, 100.3685),
    'Kelantan': LatLng(5.3117, 102.2381),
    'Melaka': LatLng(2.1896, 102.2501),
    'Negeri Sembilan': LatLng(2.7258, 101.9424),
    'Pahang': LatLng(3.8126, 103.3256),
    'Penang': LatLng(5.4141, 100.3288),
    'Perak': LatLng(4.5921, 101.0901),
    'Perlis': LatLng(6.4449, 100.2048),
    'Sabah': LatLng(5.9788, 116.0753),
    'Sarawak': LatLng(1.5533, 110.3592),
    'Selangor': LatLng(3.0738, 101.5183),
    'Terengganu': LatLng(5.3117, 103.1324),
    'Kuala Lumpur': LatLng(3.1390, 101.6869),
  };

  LatLng get _selectedStateCenter {
    final state = _stateController.text.trim();
    return _stateCenters[state] ?? const LatLng(4.2105, 101.9758); // Default Malaysia center
  }

  bool _isOpenForDemos = true;

  List<String> _toolsAndMaterials = [
    'Kampung Morten River Clay',
    'Paddy Husk Kiln Ash',
    'Organic Indigo Dyes',
    'Hand-spun Wooden Wheel',
  ];

  List<String> _portfolioImages = [];
  Map<String, String> _documents = {};

  @override
  void initState() {
    super.initState();
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    final initialHandle = (user?.username ?? user?.effectiveUsername ?? 'Pak Mat').replaceAll('@', '');
    _usernameController = TextEditingController(text: initialHandle);
    _studioNameController = TextEditingController(
      text: user?.studioName ?? user?.displayName ?? 'Pak Mat Pottery Studio',
    );
    _craftCategoryController = TextEditingController(
      text: user?.craftCategory ?? 'Pottery & Ceramics',
    );
    _stateController = TextEditingController(text: user?.state ?? 'Melaka');
    _workshopAddress = user?.address;
    if (user != null && user.latitude != null && user.longitude != null) {
      _selectedWorkshopPin = LatLng(user.latitude!, user.longitude!);
    }
    _experienceController = TextEditingController(text: '25+ Years Experience');
    _phoneController = TextEditingController(text: user?.phone ?? '+60 12-345 6789');
    _bioController = TextEditingController(
      text: user?.bio ?? 'Master Pak Mat has been hand-crafting traditional clay labu sayong and ceramic vessels for over 25 years in Kampung Morten. Each piece is hand-spun and natural clay kilned.',
    );
    
    if (user != null) {
      for (var doc in user.artisanDocuments) {
        final type = doc['doc_type'] as String?;
        final url = doc['file_url'] as String?;
        if (type != null && url != null) {
          if (type == 'PORTFOLIO_IMAGE' || type == 'STUDIO_PHOTO') {
            _portfolioImages.add(url);
          } else {
            _documents[type] = url;
          }
        }
      }
      if (user.tags.isNotEmpty) {
        _toolsAndMaterials = List<String>.from(user.tags);
      }
    }
    
    if (_portfolioImages.isEmpty) {
      _portfolioImages = [
        'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
      ];
    }
  }

  @override
  void dispose() {
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

  Future<void> _openWorkshopMapPicker() async {
    final result = await Navigator.of(context).push<WorkshopPlaceResult>(
      MaterialPageRoute(
        builder: (_) => WorkshopMapPickerPage(
          initialState: _stateController.text.trim().isEmpty
              ? 'Melaka'
              : _stateController.text.trim(),
          initialLocation: _selectedWorkshopPin,
          initialAddress: _workshopAddress,
          stateCenters: _stateCenters,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedWorkshopPin = result.position;
        _workshopAddress = result.displayName;
        if (result.malaysiaState != null) {
          _stateController.text = result.malaysiaState!;
        }
      });
      await _workshopMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(result.position, 17),
      );
    }
  }

  Future<void> _handleSave() async {
    final username = _usernameController.text.trim().replaceAll('@', '');
    final studio = _studioNameController.text.trim();
    final craft = _craftCategoryController.text.trim();
    final bio = _bioController.text.trim();
    final state = _stateController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty && studio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username or Studio name cannot be empty!'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    try {
      await authVM.updateProfile(
        username: username.isNotEmpty ? username : studio,
        displayName: studio.isNotEmpty ? studio : username,
        studioName: studio.isNotEmpty ? studio : username,
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
            _usernameController.text = (updatedUser.username ?? updatedUser.effectiveUsername).replaceAll('@', '');
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
          artisanName: _studioNameController.text.trim().isEmpty ? 'Pak Mat Pottery Studio' : _studioNameController.text.trim(),
          craftCategory: _craftCategoryController.text.trim().isEmpty ? 'Pottery & Ceramics' : _craftCategoryController.text.trim(),
          state: _stateController.text.trim().isEmpty ? 'Melaka' : _stateController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? 'Master Pak Mat has been hand-crafting traditional clay labu sayong...' : _bioController.text.trim(),
          experience: _experienceController.text.trim().isEmpty ? '25+ Years Experience' : _experienceController.text.trim(),
          imageUrl: _portfolioImages.firstWhere((img) => img.isNotEmpty, orElse: () => 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80'),
          tags: _toolsAndMaterials,
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
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : const Color(0xFF475569),
      ),
      helperText: helperText,
      helperStyle: TextStyle(
        color: isDark ? Colors.white54 : Colors.grey[600],
        fontSize: 11,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
            )
          : null,
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
      body: SingleChildScrollView(
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
            TextField(
              controller: _usernameController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: _inputDecoration(
                isDark,
                labelText: 'Account Username / Handle (@username)',
                prefixIcon: Icons.person_outline_rounded,
                helperText: 'Unified account handle synced across Tourist & Master Artisan roles',
              ),
            ),

            const SizedBox(height: 14),

            // Studio Name Input
            TextField(
              controller: _studioNameController,
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
                  child: TextField(
                    controller: _craftCategoryController,
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
                  child: TextField(
                    controller: _phoneController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: _inputDecoration(
                      isDark,
                      labelText: 'Phone / WhatsApp',
                      prefixIcon: Icons.phone_outlined,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🗺️ Workshop Map Location
            Text(
              'Workshop Location',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pin your exact workshop or studio location on the map.',
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
                  color: _selectedWorkshopPin == null
                      ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFFD7E0DC))
                      : const Color(0xFF10B981),
                  width: _selectedWorkshopPin == null ? 1 : 2,
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
                        markers: _selectedWorkshopPin == null
                            ? const <Marker>{}
                            : {
                                Marker(
                                  markerId: const MarkerId('workshop-location'),
                                  position: _selectedWorkshopPin!,
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
                          color: isDark ? const Color(0xFF0D2825) : const Color(0xFF004D40),
                          borderRadius: BorderRadius.circular(20),
                          border: isDark ? Border.all(color: const Color(0xFFFFD54F)) : null,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  _selectedWorkshopPin == null
                      ? Icons.touch_app_rounded
                      : Icons.check_circle_rounded,
                  size: 16,
                  color: _selectedWorkshopPin == null
                      ? (isDark ? Colors.white54 : const Color(0xFF64748B))
                      : (isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedWorkshopPin == null
                        ? 'Tap the map to place your exact workshop pin.'
                        : _workshopAddress ?? 'Resolving the selected address…',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      height: 1.35,
                      color: _selectedWorkshopPin == null
                          ? (isDark ? Colors.white54 : const Color(0xFF64748B))
                          : (isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Experience Input
            TextField(
              controller: _experienceController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: _inputDecoration(
                isDark,
                labelText: 'Years of Experience & Rank Title',
                prefixIcon: Icons.workspace_premium_outlined,
              ),
            ),

            const SizedBox(height: 14),

            // Bio Input
            TextField(
              controller: _bioController,
              maxLines: 4,
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
                    final textController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                        title: Text(
                          'Add Traditional Tool or Material',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                        content: TextField(
                          controller: textController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'e.g., Paddy Husk Kiln Ash',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[500],
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
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              foregroundColor: isDark ? const Color(0xFF041412) : Colors.white,
                            ),
                            onPressed: () {
                              if (textController.text.trim().isNotEmpty) {
                                setState(() => _toolsAndMaterials.add(textController.text.trim()));
                              }
                              Navigator.pop(context);
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