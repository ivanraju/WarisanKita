import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/data/services/google_map_service.dart';
import 'package:warisan_kita/ui/tourist/widgets/workshop_map_picker.dart';
import 'package:warisan_kita/viewmodels/language_viewmodel.dart';
import 'package:warisan_kita/ui/core/widgets/heritage_background.dart';

class ArtisanDetailScreen extends StatefulWidget {
  final String artisanName;
  final String craftCategory;
  final String state;
  final String imageUrl;
  final List<String>? imageUrls;
  final String bio;
  final double rating;
  final String experience;
  final List<String> tags;
  final String? address;
  final double? latitude;
  final double? longitude;
  final VoidCallback? onViewQuest;
  final bool isLiveOpen;
  final int? workshopsHosted;
  final String? ssmNumber;
  final List<Map<String, dynamic>> documents;
  final String? phoneNumber;
  final String? premiseType;

  const ArtisanDetailScreen({
    super.key,
    this.artisanName = 'Artisan Studio',
    this.craftCategory = 'Heritage Craft',
    this.state = 'Malaysia',
    this.imageUrl =
        'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
    this.imageUrls,
    this.bio = '',
    this.rating = 5.0,
    this.experience = '',
    this.tags = const [],
    this.address,
    this.latitude,
    this.longitude,
    this.onViewQuest,
    this.isLiveOpen = true,
    this.workshopsHosted,
    this.ssmNumber,
    this.documents = const [],
    this.phoneNumber,
    this.premiseType,
  });

  bool get isVillageWorkshop =>
      premiseType?.toLowerCase().contains('village') == true ||
      premiseType?.toLowerCase().contains('desa') == true ||
      premiseType?.toLowerCase().contains('kediaman') == true ||
      premiseType?.toLowerCase().contains('home') == true ||
      ssmNumber == 'VILLAGE_EXEMPT' ||
      (ssmNumber != null && ssmNumber!.toLowerCase().contains('exempt')) ||
      (ssmNumber != null && ssmNumber!.toLowerCase().contains('village'));

  @override
  State<ArtisanDetailScreen> createState() => _ArtisanDetailScreenState();
}

class _ArtisanDetailScreenState extends State<ArtisanDetailScreen> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _rotationTimer;
  bool _isInteracting = false;
  GoogleMapController? _mapController;
  late final LatLng? _workshopPin;
  late final LatLng _mapTarget;

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
    'Terengganu': LatLng(5.3117, 103.1324),
    'Kuala Lumpur': LatLng(3.1390, 101.6869),
    'Putrajaya': LatLng(2.9264, 101.6964),
    'Labuan': LatLng(5.2831, 115.2308),
  };

  late final List<String> _carouselImages = () {
    if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) {
      return widget.imageUrls!;
    }
    return [widget.imageUrl];
  }();

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null && widget.longitude != null) {
      _workshopPin = LatLng(widget.latitude!, widget.longitude!);
      _mapTarget = _workshopPin!;
    } else {
      _workshopPin = null;
      _mapTarget =
          _stateCenters[widget.state] ?? const LatLng(2.1896, 102.2501);
    }
    _startAutoRotation();
  }

  void _startAutoRotation() {
    _stopAutoRotation();
    if (_carouselImages.length <= 1) return;

    _rotationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _isInteracting) return;
      if (!_pageController.hasClients) return;

      final nextPage = (_currentCarouselIndex + 1) % _carouselImages.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  void _onUserTouchStart() {
    _isInteracting = true;
    _stopAutoRotation();
  }

  void _onUserTouchEnd() {
    _isInteracting = false;
    _stopAutoRotation();
    _rotationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isInteracting) {
        _startAutoRotation();
      }
    });
  }

  @override
  void dispose() {
    _stopAutoRotation();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _openWorkshopMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkshopMapPickerPage(
          initialState: widget.state,
          initialLocation: _workshopPin,
          initialAddress: widget.address,
          stateCenters: _stateCenters,
          isReadOnly: true,
          artisanName: widget.artisanName,
        ),
      ),
    );
  }

  Future<void> _openDirections() async {
    final target = _workshopPin ?? _mapTarget;
    final uri = await const GoogleMapService().directionsTo(
      latitude: target.latitude,
      longitude: target.longitude,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map directions')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        final tr = context.read<LanguageViewModel?>()?.translate;
        final prefix = tr != null ? tr('Could not call') : 'Could not call';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$prefix $phone')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    LanguageViewModel? langVM;
    try {
      langVM = context.watch<LanguageViewModel>();
    } catch (_) {}
    String tr(String text) => langVM?.translate(text) ?? text;

    return HeritageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top Image Carousel Sliver AppBar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF041412)
                : const Color(0xFF004D40),
            leading: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Listener(
                    onPointerDown: (_) => _onUserTouchStart(),
                    onPointerUp: (_) => _onUserTouchEnd(),
                    onPointerCancel: (_) => _onUserTouchEnd(),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (idx) =>
                          setState(() => _currentCarouselIndex = idx),
                      itemCount: _carouselImages.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          _carouselImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isDark
                                ? const Color(0xFF0D2825)
                                : const Color(0xFF004D40),
                          ),
                        );
                      },
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_carouselImages.length > 1)
                    Positioned(
                      top: 48,
                      right: 68,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_rounded,
                              size: 11,
                              color: Color(0xFFFFD54F),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentCarouselIndex + 1}/${_carouselImages.length}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_carouselImages.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _carouselImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _currentCarouselIndex == index ? 18 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: _currentCarouselIndex == index
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tr(widget.craftCategory),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: const Color(0xFF004D40),
                                ),
                              ),
                            ),
                            if (widget.isVillageWorkshop || (widget.premiseType != null && widget.premiseType!.isNotEmpty))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isVillageWorkshop
                                      ? const Color(0xFFECFDF5)
                                      : Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.isVillageWorkshop
                                          ? Icons.cottage_outlined
                                          : Icons.store_outlined,
                                      size: 13,
                                      color: widget.isVillageWorkshop
                                          ? const Color(0xFF047857)
                                          : const Color(0xFF004D40),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.isVillageWorkshop
                                          ? tr('Village Workshop')
                                          : tr('Commercial Studio'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: widget.isVillageWorkshop
                                            ? const Color(0xFF047857)
                                            : const Color(0xFF004D40),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.artisanName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Screen Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Demo Availability Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isLiveOpen
                          ? (isDark
                                ? const Color(0xFF0D2825)
                                : const Color(0xFFECFDF5))
                          : (isDark
                                ? const Color(0xFF2A1215)
                                : const Color(0xFFFEF2F2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isLiveOpen
                            ? (isDark
                                  ? const Color(0xFF1E3A34)
                                  : const Color(0xFF10B981))
                            : (isDark
                                  ? const Color(0xFF5C1D24)
                                  : const Color(0xFFEF4444)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isLiveOpen
                              ? Icons.check_circle_rounded
                              : Icons.pause_circle_filled_rounded,
                          color: widget.isLiveOpen
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isLiveOpen
                                ? tr(
                                    'LIVE: OPEN FOR EDUCATIONAL DEMOS & WORKSHOPS',
                                  )
                                : tr(
                                    'DEMOS TEMPORARILY PAUSED / NOT ACCEPTING VISITORS',
                                  ),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                              color: widget.isLiveOpen
                                  ? (isDark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF047857))
                                  : (isDark
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFFB91C1C)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location & Experience Row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: isDark
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF004D40),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.state}, Malaysia',
                          softWrap: true,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF004D40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A34)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: isDark
                              ? Border.all(
                                  color: const Color(
                                    0xFF34D399,
                                  ).withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.4,
                          ),
                          child: Text(
                            widget.experience,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Rating & Live Status Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D2825) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E3A34)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final demoBadge = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isLiveOpen
                                ? (isDark
                                      ? const Color(0xFF064E3B)
                                      : const Color(0xFFDCFCE7))
                                : (isDark
                                      ? const Color(0xFF450A0A)
                                      : const Color(0xFFFEE2E2)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: widget.isLiveOpen
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.isLiveOpen
                                    ? tr('OPEN DEMOS')
                                    : tr('DEMOS PAUSED'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isLiveOpen
                                      ? (isDark
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF15803D))
                                      : (isDark
                                            ? const Color(0xFFF87171)
                                            : const Color(0xFFB91C1C)),
                                ),
                              ),
                            ],
                          ),
                        );

                        final verifiedRow = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isVillageWorkshop
                                  ? Icons.cottage_rounded
                                  : Icons.verified_rounded,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF004D40),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.isVillageWorkshop
                                    ? tr('Verified Village Crafter')
                                    : tr('Verified Commercial Studio'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF004D40),
                                ),
                              ),
                            ),
                          ],
                        );

                        if (constraints.maxWidth < 290) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              verifiedRow,
                              const SizedBox(height: 8),
                              demoBadge,
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: verifiedRow),
                            const SizedBox(width: 8),
                            demoBadge,
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Master Bio Card
                  Text(
                    tr('Artisan Biography'),
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(widget.bio),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🏆 AUTHENTICITY & CERTIFICATION CREDENTIALS
                  Text(
                    tr('Master Authenticity & Credentials'),
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (widget.isVillageWorkshop) ...[
                    _buildCredentialTile(
                      icon: Icons.verified_user_rounded,
                      title: tr('SSM Registration: Exempted (Village Crafter)'),
                      subtitle: tr(
                        'Exempted from commercial registration under National Heritage Preservation Scheme • Recognized traditional craft practitioner',
                      ),
                      isDark: isDark,
                    ),
                    _buildCredentialTile(
                      icon: Icons.photo_camera_rounded,
                      title: tr('Traditional Crafting Evidence & Workshop'),
                      subtitle: tr(
                        'Authentic handcrafted production and workshop evidence verified by Kraftangan Malaysia',
                      ),
                      isDark: isDark,
                    ),
                  ] else ...[
                    _buildCredentialTile(
                      icon: Icons.store_rounded,
                      title: tr('SSM Business Registration'),
                      subtitle: (widget.ssmNumber != null &&
                              widget.ssmNumber!.trim().isNotEmpty &&
                              widget.ssmNumber != 'VILLAGE_EXEMPT')
                          ? '${tr('Registration')} #${widget.ssmNumber!.trim()} • ${tr('Official Registered Commercial Studio')}'
                          : tr('Official Registered Commercial Studio Premise'),
                      isDark: isDark,
                    ),
                  ],
                  _buildCredentialTile(
                    icon: Icons.workspace_premium_rounded,
                    title: tr('Kraftangan Malaysia Accredited Master'),
                    subtitle: widget.documents.any((d) {
                      final t = d['doc_type']?.toString().toUpperCase() ?? '';
                      return t == 'KRAFTANGAN_MASTER_CERT' ||
                          t == 'KRAFTANGAN_CERT';
                    })
                        ? '${tr('Accredited in')} ${tr(widget.craftCategory)} (${widget.state}) • ${tr('Official Certificate Verified')}'
                        : '${tr('Accredited in')} ${tr(widget.craftCategory)} (${widget.state}) • ${tr('Verified Master Craftsman')}',
                    isDark: isDark,
                  ),
                  _buildCredentialTile(
                    icon: Icons.history_edu_rounded,
                    title: tr('Heritage Craft Practitioner'),
                    subtitle: widget.experience.trim().isNotEmpty
                        ? '${widget.experience.trim()} ${tr('of authentic')} ${tr(widget.craftCategory)} ${tr('heritage mastery in')} ${widget.state}'
                        : '${tr('Dedicated authentic')} ${tr(widget.craftCategory)} ${tr('practitioner in')} ${widget.state}',
                    isDark: isDark,
                  ),

                  if (widget.tags.any((t) => !t.startsWith('__') && !t.startsWith('doc_') && !t.startsWith('premise:'))) ...[
                    const SizedBox(height: 24),
                    Text(
                      tr('Materials & Traditional Tools Used'),
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 20,
                        color: isDark
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.tags
                          .where((t) =>
                              !t.startsWith('__') &&
                              !t.startsWith('doc_') &&
                              !t.startsWith('premise:'))
                          .map(
                            (tag) => Chip(
                              backgroundColor: isDark
                                  ? const Color(0xFF0D2825)
                                  : null,
                              side: isDark
                                  ? const BorderSide(color: Color(0xFF1E3A34))
                                  : null,
                              avatar: Icon(
                                Icons.handyman_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF34D399) : null,
                              ),
                              label: Text(
                                tr(tag),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : null,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Craft Experience Highlight Chip
                  _buildHighlightChip(
                    icon: Icons.workspace_premium_rounded,
                    title: tr('Craft Experience'),
                    value: widget.experience.trim().isNotEmpty
                        ? tr(widget.experience.trim())
                        : tr('10+ Years'),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 28),

                  // Studio Location Map Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          tr('Studio Location & Workshop Map'),
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 19,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF004D40),
                          ),
                        ),
                      ),
                      if (_workshopPin != null) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _openDirections,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            Icons.directions_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF004D40),
                          ),
                          label: Text(
                            tr('Directions'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFF004D40),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D2825)
                          : const Color(0xFFE8EFEC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _workshopPin != null
                            ? const Color(0xFF10B981)
                            : (isDark
                                  ? const Color(0xFF1E3A34)
                                  : const Color(0xFFD7E0DC)),
                        width: _workshopPin != null ? 1.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _mapTarget,
                              zoom: _workshopPin != null ? 14 : 11,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                            markers: _workshopPin == null
                                ? const <Marker>{}
                                : {
                                    Marker(
                                      markerId: const MarkerId('workshop_pin'),
                                      position: _workshopPin,
                                      infoWindow: InfoWindow(
                                        title: widget.artisanName,
                                        snippet: widget.craftCategory,
                                      ),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueOrange,
                                          ),
                                    ),
                                  },
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: false,
                            compassEnabled: false,
                          ),
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(onTap: _openWorkshopMap),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D2825)
                                    : const Color(0xFF004D40),
                                borderRadius: BorderRadius.circular(20),
                                border: isDark
                                    ? Border.all(color: const Color(0xFFFFD54F))
                                    : null,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                  ),
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
                                      color: isDark
                                          ? const Color(0xFFFFD54F)
                                          : Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr('Open Large Map'),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: isDark
                                            ? const Color(0xFFFFD54F)
                                            : Colors.white,
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
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: _workshopPin != null
                            ? const Color(0xFFEF4444)
                            : (isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.address != null &&
                                  widget.address!.trim().isNotEmpty
                              ? widget.address!
                              : widget.state,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (widget.phoneNumber != null &&
                      widget.phoneNumber!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF004D40),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.phoneNumber!.trim(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D2825) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E3A34)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(
                                      0xFF34D399,
                                    ).withValues(alpha: 0.15)
                                  : const Color(
                                      0xFF004D40,
                                    ).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.phone_in_talk_rounded,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF004D40),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('Studio Contact & Inquiries'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.phoneNumber!.trim(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.call_rounded, size: 16),
                            label: Text(tr('Call')),
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF1E3A34)
                                  : const Color(0xFFDCFCE7),
                              foregroundColor: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF15803D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () =>
                                _makePhoneCall(widget.phoneNumber!),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: widget.onViewQuest == null ? 24 : 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.onViewQuest == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D2825) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF1E3A34)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onViewQuest,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF00695C)
                          : const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFFD54F),
                      size: 18,
                    ),
                    label: Text(
                      tr('VIEW QUEST'),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildCredentialTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A34)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF004D40),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightChip({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D2825) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A34)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.15)
                  : const Color(0xFF004D40).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
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
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
