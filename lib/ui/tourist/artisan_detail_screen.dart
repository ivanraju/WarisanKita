import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/data/services/google_map_service.dart';
import 'package:warisan_kita/ui/tourist/widgets/workshop_map_picker.dart';

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
  });

  @override
  State<ArtisanDetailScreen> createState() => _ArtisanDetailScreenState();
}

class _ArtisanDetailScreenState extends State<ArtisanDetailScreen> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
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

  late final List<String> _carouselImages =
      widget.imageUrls != null && widget.imageUrls!.isNotEmpty
      ? widget.imageUrls!
      : [
          widget.imageUrl,
          'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
        ];

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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF041412)
          : const Color(0xFFF8F9FA),
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
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Share Artisan Profile',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFFFD54F),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '🔗 Link copied: https://warisankita.my/artisan/${Uri.encodeComponent(widget.artisanName)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF004D40),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Row(
                      children: List.generate(
                        _carouselImages.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarouselIndex == index
                                ? const Color(0xFFFFD54F)
                                : Colors.white.withValues(alpha: 0.5),
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
                            widget.craftCategory,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: const Color(0xFF004D40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.artisanName,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.isLiveOpen
                          ? (isDark ? const Color(0xFF0D2825) : const Color(0xFFECFDF5))
                          : (isDark ? const Color(0xFF2A1215) : const Color(0xFFFEF2F2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isLiveOpen
                            ? (isDark ? const Color(0xFF1E3A34) : const Color(0xFF10B981))
                            : (isDark ? const Color(0xFF5C1D24) : const Color(0xFFEF4444)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isLiveOpen ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                          color: widget.isLiveOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isLiveOpen
                                ? 'LIVE: OPEN FOR EDUCATIONAL DEMOS & WORKSHOPS'
                                : 'DEMOS TEMPORARILY PAUSED / NOT ACCEPTING VISITORS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                              color: widget.isLiveOpen
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                                  : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
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
                        child: Text(
                          widget.experience,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFFB45309),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF004D40),
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Artisan Studio',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF004D40),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'OPEN DEMOS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Master Bio Card
                  Text(
                    'Artisan Biography',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.bio,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🏆 AUTHENTICITY & CERTIFICATION CREDENTIALS
                  Text(
                    'Master Authenticity & Credentials',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 20,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildCredentialTile(
                    icon: Icons.verified_rounded,
                    title: 'Kraftangan Malaysia Accredited Master',
                    subtitle: widget.documents.any((d) {
                      final t = d['doc_type']?.toString().toUpperCase() ?? '';
                      return t == 'KRAFTANGAN_MASTER_CERT' || t == 'KRAFTANGAN_CERT';
                    })
                        ? 'Accredited in ${widget.craftCategory} (${widget.state}) • Official Certificate Verified'
                        : 'Accredited in ${widget.craftCategory} (${widget.state}) • Verified Master Craftsman',
                    isDark: isDark,
                  ),
                  _buildCredentialTile(
                    icon: Icons.business_rounded,
                    title: 'SSM Business Registration',
                    subtitle: (widget.ssmNumber != null && widget.ssmNumber!.trim().isNotEmpty)
                        ? 'Registration #${widget.ssmNumber!.trim()} • Official Registered Heritage Studio'
                        : 'Official Registered Heritage Studio Premise',
                    isDark: isDark,
                  ),
                  _buildCredentialTile(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Heritage Craft Practitioner',
                    subtitle: widget.experience.trim().isNotEmpty
                        ? '${widget.experience.trim()} of authentic ${widget.craftCategory} heritage mastery in ${widget.state}'
                        : 'Dedicated authentic ${widget.craftCategory} practitioner in ${widget.state}',
                    isDark: isDark,
                  ),

                  if (widget.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Materials & Traditional Tools Used',
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
                                tag,
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
                    title: 'Craft Experience',
                    value: widget.experience.trim().isNotEmpty
                        ? widget.experience.trim()
                        : '10+ Years',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 28),

                  // Studio Location Map Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Studio Location & Workshop Map',
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
                            'Directions',
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
                                      'Open Large Map',
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
                      backgroundColor: const Color(0xFF004D40),
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
                      'VIEW QUEST',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
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
