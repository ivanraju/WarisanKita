import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:warisan_kita/data/services/google_map_service.dart';

class WorkshopPlaceResult {
  final String displayName;
  final LatLng position;
  final String? countryCode;
  final String? malaysiaState;

  const WorkshopPlaceResult({
    required this.displayName,
    required this.position,
    this.countryCode,
    this.malaysiaState,
  });

  bool get isInMalaysia => countryCode?.toLowerCase() == 'my';

  static WorkshopPlaceResult? fromMap(Map<String, dynamic> map) {
    final displayName = map['display_name']?.toString().trim();
    final latitude = double.tryParse(map['lat']?.toString() ?? '');
    final longitude = double.tryParse(map['lon']?.toString() ?? '');
    final address = map['address'] is Map
        ? Map<String, dynamic>.from(map['address'] as Map)
        : const <String, dynamic>{};
    if (displayName == null ||
        displayName.isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    return WorkshopPlaceResult(
      displayName: displayName,
      position: LatLng(latitude, longitude),
      countryCode:
          address['country_code']?.toString() ??
          map['country_code']?.toString(),
      malaysiaState: _resolveMalaysiaState(address, displayName),
    );
  }

  static WorkshopPlaceResult? fromGooglePlace(Map<String, dynamic> map) {
    final location = map['location'] is Map
        ? Map<String, dynamic>.from(map['location'] as Map)
        : const <String, dynamic>{};
    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();
    final formattedAddress = map['formattedAddress']?.toString().trim();
    final displayNameMap = map['displayName'] is Map
        ? Map<String, dynamic>.from(map['displayName'] as Map)
        : const <String, dynamic>{};
    final placeName = displayNameMap['text']?.toString().trim();
    if (latitude == null || longitude == null) return null;

    String? countryCode;
    String? stateName;
    final components = map['addressComponents'];
    if (components is List) {
      for (final component in components.whereType<Map>()) {
        final value = Map<String, dynamic>.from(component);
        final types =
            (value['types'] as List?)?.map((type) => type.toString()).toSet() ??
            const <String>{};
        if (types.contains('country')) {
          countryCode = value['shortText']?.toString();
        }
        if (types.contains('administrative_area_level_1')) {
          stateName = value['longText']?.toString();
        }
      }
    }

    final address = formattedAddress?.isNotEmpty == true
        ? formattedAddress!
        : placeName;
    if (address == null || address.isEmpty) return null;
    final label =
        placeName != null &&
            placeName.isNotEmpty &&
            !address.toLowerCase().startsWith(placeName.toLowerCase())
        ? '$placeName, $address'
        : address;

    return WorkshopPlaceResult(
      displayName: label,
      position: LatLng(latitude, longitude),
      countryCode: countryCode,
      malaysiaState: _resolveMalaysiaState({
        'state': stateName,
      }, '$label ${stateName ?? ''}'),
    );
  }

  static String? _resolveMalaysiaState(
    Map<String, dynamic> address,
    String displayName,
  ) {
    final locationText = <Object?>[
      address['state'],
      address['region'],
      address['city'],
      address['county'],
      displayName,
    ].whereType<Object>().join(' ').toLowerCase();

    const aliases = <String, List<String>>{
      'Kuala Lumpur': ['kuala lumpur', 'kl', 'wilayah persekutuan kuala lumpur'],
      'Putrajaya': ['putrajaya', 'wilayah persekutuan putrajaya'],
      'Labuan': ['labuan', 'wilayah persekutuan labuan'],
      'Negeri Sembilan': ['negeri sembilan'],
      'Penang': ['pulau pinang', 'penang'],
      'Melaka': ['malacca', 'melaka'],
      'Terengganu': ['terengganu'],
      'Selangor': ['selangor'],
      'Sarawak': ['sarawak'],
      'Sabah': ['sabah'],
      'Perlis': ['perlis'],
      'Perak': ['perak'],
      'Pahang': ['pahang'],
      'Kelantan': ['kelantan'],
      'Kedah': ['kedah'],
      'Johor': ['johor'],
    };
    for (final entry in aliases.entries) {
      if (entry.value.any(locationText.contains)) return entry.key;
    }
    return null;
  }
}

class WorkshopPlaceSearch {
  static const MethodChannel _mapsChannel = MethodChannel(
    'warisan_kita/google_maps',
  );
  static const Map<String, String> _headers = {
    'User-Agent': 'WarisanKita/1.0 (workshop location picker)',
    'Accept-Language': 'en-MY,en',
  };

  static Future<List<WorkshopPlaceResult>> search({
    required String query,
    String? targetState,
  }) async {
    try {
      final googleResults = await _searchGooglePlaces(
        query,
        targetState: targetState,
      );
      if (googleResults.isNotEmpty) return googleResults;
    } catch (_) {
      // Keep the location picker usable if Google Places is unavailable.
    }

    return _searchOpenStreetMap(query, targetState: targetState);
  }

  static Future<List<WorkshopPlaceResult>> _searchGooglePlaces(
    String query, {
    String? targetState,
  }) async {
    final apiKey = await _mapsChannel.invokeMethod<String>('getApiKey');
    if (apiKey == null || apiKey.trim().isEmpty) return const [];

    String textQuery = query;
    if (targetState != null &&
        targetState.trim().isNotEmpty &&
        !textQuery.toLowerCase().contains(targetState.toLowerCase())) {
      textQuery = '$textQuery, $targetState';
    }
    final malaysiaQuery = textQuery.toLowerCase().contains('malaysia')
        ? textQuery
        : '$textQuery, Malaysia';
    final response = await http
        .post(
          Uri.https('places.googleapis.com', '/v1/places:searchText'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,'
                'places.location,places.addressComponents',
          },
          body: jsonEncode({
            'textQuery': malaysiaQuery,
            'languageCode': 'en',
            'regionCode': 'MY',
            'pageSize': 8,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Google Places search is temporarily unavailable.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Google Places response.');
    }
    final places = decoded['places'];
    if (places is! List) return const [];
    var results = places
        .whereType<Map>()
        .map(
          (place) => WorkshopPlaceResult.fromGooglePlace(
            Map<String, dynamic>.from(place),
          ),
        )
        .whereType<WorkshopPlaceResult>()
        .where((place) => place.isInMalaysia);

    if (targetState != null && targetState.trim().isNotEmpty) {
      final target = targetState.trim().toLowerCase();
      results = results.where((place) {
        if (place.malaysiaState != null) {
          return place.malaysiaState!.toLowerCase() == target;
        }
        return place.displayName.toLowerCase().contains(target);
      });
    }

    return results.toList(growable: false);
  }

  static Future<List<WorkshopPlaceResult>> _searchOpenStreetMap(
    String query, {
    String? targetState,
  }) async {
    String searchQuery = query;
    if (targetState != null &&
        targetState.trim().isNotEmpty &&
        !searchQuery.toLowerCase().contains(targetState.toLowerCase())) {
      searchQuery = '$searchQuery, $targetState';
    }
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': searchQuery,
      'format': 'jsonv2',
      'addressdetails': '1',
      'namedetails': '1',
      'countrycodes': 'my',
      'limit': '5',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw StateError('Place search is temporarily unavailable.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Invalid place search response.');
    }
    var results = decoded
        .whereType<Map<String, dynamic>>()
        .map(WorkshopPlaceResult.fromMap)
        .whereType<WorkshopPlaceResult>()
        .where((place) => place.isInMalaysia);

    if (targetState != null && targetState.trim().isNotEmpty) {
      final target = targetState.trim().toLowerCase();
      results = results.where((place) {
        if (place.malaysiaState != null) {
          return place.malaysiaState!.toLowerCase() == target;
        }
        return place.displayName.toLowerCase().contains(target);
      });
    }

    return results.toList(growable: false);
  }

  static Future<WorkshopPlaceResult?> reverse(LatLng position) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '18',
      });
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return WorkshopPlaceResult.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }
}

class WorkshopMapPickerPage extends StatefulWidget {
  final String initialState;
  final LatLng? initialLocation;
  final String? initialAddress;
  final Map<String, LatLng> stateCenters;
  final String? lockedState;
  final bool isReadOnly;
  final String? artisanName;

  const WorkshopMapPickerPage({
    super.key,
    required this.initialState,
    required this.initialLocation,
    required this.initialAddress,
    required this.stateCenters,
    this.lockedState,
    this.isReadOnly = false,
    this.artisanName,
  });

  @override
  State<WorkshopMapPickerPage> createState() => _WorkshopMapPickerPageState();
}

class _WorkshopMapPickerPageState extends State<WorkshopMapPickerPage> {
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  WorkshopPlaceResult? _selection;
  LatLng? _pendingPosition;
  late String _detectedState;
  bool _isLoading = false;
  bool _isLocating = false;
  bool _hasLocationPermission = false;
  MapType _mapType = MapType.normal;
  String? _error;

  @override
  void initState() {
    super.initState();
    _detectedState = widget.initialState;
    if (widget.initialLocation != null) {
      final initialAddr = widget.initialAddress?.trim() ?? '';
      _selection = WorkshopPlaceResult(
        displayName: initialAddr,
        position: widget.initialLocation!,
        countryCode: 'my',
        malaysiaState: widget.initialState,
      );
      if (initialAddr.isNotEmpty) {
        _searchController.text = initialAddr;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Enter a workshop name or address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await WorkshopPlaceSearch.search(
        query: query,
        targetState: widget.lockedState,
      );
      if (results.isEmpty) {
        throw StateError('No matching place found.');
      }
      if (!mounted) return;
      final place = results.length == 1
          ? results.first
          : await _chooseResult(results);
      if (place != null && mounted) {
        if (widget.lockedState != null &&
            place.malaysiaState != null &&
            place.malaysiaState!.toLowerCase() !=
                widget.lockedState!.toLowerCase()) {
          setState(() {
            _error =
                'Location is in ${place.malaysiaState}. Please search within ${widget.lockedState}.';
          });
          return;
        }
        await _applySelection(place);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = widget.lockedState != null
              ? 'No location found in ${widget.lockedState}. Try a more complete address.'
              : 'No Malaysian location found. Try a more complete address.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pin(LatLng position) async {
    setState(() {
      _isLoading = true;
      _pendingPosition = position;
      _error = null;
    });
    final place = await WorkshopPlaceSearch.reverse(position);
    if (!mounted) return;
    if (place == null || !place.isInMalaysia) {
      setState(() {
        _isLoading = false;
        _pendingPosition = null;
        _error = 'That pin is outside Malaysia. Choose a Malaysian location.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workshop pins must be located within Malaysia.'),
          backgroundColor: Color(0xFFB42318),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.lockedState != null &&
        place.malaysiaState != null &&
        place.malaysiaState!.toLowerCase() !=
            widget.lockedState!.toLowerCase()) {
      setState(() {
        _isLoading = false;
        _pendingPosition = null;
        _error =
            'Location is in ${place.malaysiaState}. Must be within ${widget.lockedState}.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected location is in ${place.malaysiaState}. Workshop must be within ${widget.lockedState}.',
          ),
          backgroundColor: const Color(0xFFB42318),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _applySelection(
      WorkshopPlaceResult(
        displayName: place.displayName,
        position: position,
        countryCode: place.countryCode,
        malaysiaState: place.malaysiaState,
      ),
      moveCamera: false,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Enable location services to find your position.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission is required for this button.');
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final target = LatLng(current.latitude, current.longitude);
      setState(() => _hasLocationPermission = true);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 17),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: const Color(0xFFB42318),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _adjustZoom(double amount) async {
    final controller = _mapController;
    if (controller == null) return;
    final currentZoom = await controller.getZoomLevel();
    final targetZoom = (currentZoom + amount).clamp(3.0, 21.0);
    await controller.animateCamera(CameraUpdate.zoomTo(targetZoom));
  }

  Widget _mapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF0D2825) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        side: isDark
            ? const BorderSide(color: Color(0xFF1E3A34))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        child: SizedBox.square(
          dimension: 46,
          child: Center(
            child: _isLocating && icon == Icons.my_location_rounded
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF004D40),
                    ),
                  )
                : Tooltip(
                    message: tooltip,
                    child: Icon(
                      icon,
                      color: isDark
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFF004D40),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _applySelection(
    WorkshopPlaceResult place, {
    bool moveCamera = true,
  }) async {
    setState(() {
      _selection = place;
      _pendingPosition = null;
      _detectedState = place.malaysiaState ?? _detectedState;
      _searchController.text = place.displayName;
      _error = null;
    });
    if (moveCamera) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(place.position, 17),
      );
    }
  }

  Future<WorkshopPlaceResult?> _chooseResult(
    List<WorkshopPlaceResult> results,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<WorkshopPlaceResult>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 430),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
            ),
            itemBuilder: (_, index) {
              final result = results[index];
              return ListTile(
                leading: Icon(
                  Icons.location_on_rounded,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                ),
                title: Text(
                  result.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(result),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openDirections(LatLng target) async {
    final uri = await const GoogleMapService().directionsTo(
      latitude: target.latitude,
      longitude: target.longitude,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map directions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selection;
    final markerPosition = _pendingPosition ?? selected?.position;
    final initialTarget =
        selected?.position ??
        widget.initialLocation ??
        widget.stateCenters[_detectedState] ??
        const LatLng(3.1390, 101.6869);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF7F5EF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF041412) : Colors.white,
        foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
        ),
        title: Text(
          widget.isReadOnly
              ? (widget.artisanName != null && widget.artisanName!.isNotEmpty
                  ? '${widget.artisanName}\'s Workshop'
                  : 'Workshop Location')
              : (widget.lockedState != null
                  ? 'Pin Workshop (${widget.lockedState})'
                  : 'Pin Workshop Location'),
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: isDark ? const Color(0xFFFFE082) : const Color(0xFF004D40),
          ),
        ),
        actions: [
          if (!widget.isReadOnly) ...[
            TextButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(context).pop(selected),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                disabledForegroundColor: isDark ? Colors.white24 : Colors.black26,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Done'),
            ),
            const SizedBox(width: 8),
          ] else if (markerPosition != null) ...[
            IconButton(
              icon: const Icon(Icons.directions_rounded),
              tooltip: 'Get Directions',
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
              onPressed: () => _openDirections(markerPosition),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              style: isDark && _mapType == MapType.normal
                  ? GoogleMapService.darkHeritageMapStyle
                  : null,
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: selected == null ? 15 : 17,
              ),
              mapType: _mapType,
              onMapCreated: (controller) => _mapController = controller,
              onTap: widget.isReadOnly || _isLoading ? null : _pin,
              onLongPress: widget.isReadOnly || _isLoading ? null : _pin,
              markers: markerPosition == null
                  ? const <Marker>{}
                  : {
                      Marker(
                        markerId: const MarkerId('large-workshop-pin'),
                        position: markerPosition,
                        draggable: !widget.isReadOnly && !_isLoading,
                        onDragEnd: widget.isReadOnly ? null : _pin,
                        infoWindow: InfoWindow(
                          title: widget.artisanName != null && widget.artisanName!.isNotEmpty
                              ? widget.artisanName
                              : 'Accredited Workshop',
                          snippet: selected?.displayName.isNotEmpty == true
                              ? selected!.displayName
                              : (widget.initialAddress ?? _detectedState),
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                      ),
                    },
              myLocationButtonEnabled: false,
              myLocationEnabled: _hasLocationPermission,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),
          ),
          Positioned(
            top: 88,
            right: 14,
            child: SafeArea(
              child: Column(
                children: [
                  _mapControlButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Go to my location',
                    onPressed: _isLocating ? null : _moveToCurrentLocation,
                  ),
                  const SizedBox(height: 12),
                  _mapControlButton(
                    icon: _mapType == MapType.normal
                        ? Icons.satellite_alt_rounded
                        : Icons.map_rounded,
                    tooltip: _mapType == MapType.normal
                        ? 'Switch to Satellite View'
                        : 'Switch to Standard Map',
                    onPressed: () {
                      setState(() {
                        _mapType = _mapType == MapType.normal
                            ? MapType.hybrid
                            : MapType.normal;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      children: [
                        _mapControlButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Zoom in',
                          onPressed: () => _adjustZoom(1),
                          borderRadius: BorderRadius.zero,
                        ),
                        Container(
                          width: 32,
                          height: 1,
                          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                        ),
                        _mapControlButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Zoom out',
                          onPressed: () => _adjustZoom(-1),
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (!widget.isReadOnly) ...[
                    Material(
                      elevation: 5,
                      color: isDark ? const Color(0xFF0D2825) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                        cursorColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: widget.lockedState != null
                              ? 'Search within ${widget.lockedState}...'
                              : 'Search a workshop or address',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                          ),
                          suffixIcon: IconButton(
                            onPressed: _isLoading ? null : _search,
                            icon: Icon(
                              Icons.arrow_forward_rounded,
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                            ),
                          ),
                          errorText: _error,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0D2825) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF004D40),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: LinearProgressIndicator(
                          color: const Color(0xFFD97706),
                          backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFFFDE68A),
                          minHeight: 3,
                        ),
                      ),
                  ] else ...[
                    Material(
                      elevation: 4,
                      color: isDark ? const Color(0xFF0D2825) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF123D35) : const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified_rounded,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Verified Heritage Workshop',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF14532D),
                                    ),
                                  ),
                                  Text(
                                    'Official accredited premise verified by Kraftangan Malaysia',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Material(
                    elevation: 5,
                    color: isDark ? const Color(0xFF0D2825) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                widget.isReadOnly
                                    ? Icons.location_on_rounded
                                    : (selected == null
                                        ? Icons.touch_app_rounded
                                        : Icons.location_on_rounded),
                                color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isReadOnly
                                          ? (widget.artisanName != null && widget.artisanName!.isNotEmpty
                                              ? '${widget.artisanName} • $_detectedState'
                                              : _detectedState)
                                          : (selected == null
                                              ? (widget.lockedState != null
                                                  ? 'Tap within ${widget.lockedState} to place the pin'
                                                  : 'Tap anywhere in Malaysia to place the pin')
                                              : _detectedState),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFFFE082) : const Color(0xFF004D40),
                                      ),
                                    ),
                                    if (selected != null || widget.initialAddress != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        selected?.displayName.isNotEmpty == true
                                            ? selected!.displayName
                                            : (widget.initialAddress ?? 'Accredited Workshop Location'),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.isReadOnly && markerPosition != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _openDirections(markerPosition),
                                icon: const Icon(Icons.directions_rounded, size: 18),
                                label: const Text('Get Directions'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF1E3A34) : const Color(0xFF004D40),
                                  foregroundColor: isDark ? const Color(0xFFFFD54F) : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
