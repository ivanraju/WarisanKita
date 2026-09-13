import 'package:flutter/foundation.dart';
import 'package:warisan_kita/data/repositories/gamification_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/workshop_location.dart';

class ArtisanRepository {
  final SupabaseService _service;
  late final GamificationRepository _gamificationRepository;
  final Map<String, String> _workshopImageCache = {};

  ArtisanRepository({
    SupabaseService? service,
    GamificationRepository? gamificationRepository,
  }) : _service = service ?? SupabaseService() {
    _gamificationRepository =
        gamificationRepository ?? GamificationRepository(service: _service);
  }

  Future<List<ArtisanModel>> getArtisans() async {
    final artisans = await _service.fetchArtisans();
    if (artisans.isEmpty) return artisans;

    try {
      // Use the same approved-quest summary as Map. It already excludes
      // pending/archived tasks and selects only one quest per workshop.
      final snapshot = await _gamificationRepository
          .getTouristJourneySnapshot();
      return artisans.map((artisan) {
        final journey = snapshot.journeysByWorkshopId[artisan.id];
        return artisan.copyWith(questPotentialXp: journey?.xpReward);
      }).toList(growable: false);
    } catch (error, stackTrace) {
      // Quest XP is supplementary; never prevent directory cards from loading.
      debugPrint('ArtisanRepository quest XP summary unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return artisans;
    }
  }

  Future<List<WorkshopLocation>> getWorkshopLocations() async {
    final data = await _service.fetchWorkshopLocations();

    return _mapWorkshopLocations(data);
  }

  Stream<List<WorkshopLocation>> watchWorkshopLocations() {
    return _service.watchWorkshopLocations().map(_mapWorkshopLocations);
  }

  Future<bool> getWorkshopLiveStatus(String workshopId) {
    return _service.fetchWorkshopLiveStatus(workshopId);
  }

  List<WorkshopLocation> _mapWorkshopLocations(
    List<Map<String, dynamic>> data,
  ) {
    return data.map((row) {
      final id = row['id'] as String;
      final tags = (row['tags'] as List? ?? const <Object>[])
          .map((tag) => tag.toString())
          .toSet();
      final hasDocumentPayload = row.containsKey('artisan_documents');
      final resolvedImageUrl = hasDocumentPayload
          ? _firstSavedWorkshopImage(row['artisan_documents'])
          : null;

      if (hasDocumentPayload) {
        if (resolvedImageUrl == null) {
          _workshopImageCache.remove(id);
        } else {
          _workshopImageCache[id] = resolvedImageUrl;
        }
      }

      return WorkshopLocation(
        id: id,
        name: row['studio_name'] as String,
        craftCategory: row['craft_category'] as String,
        address: row['address'] as String,
        state: row['state'] as String,
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        primaryImageUrl: resolvedImageUrl ?? _workshopImageCache[id] ?? '',
        isLiveOpen: !tags.contains('__LIVE_DEMO_CLOSED__'),
      );
    }).toList();
  }

  String? _firstSavedWorkshopImage(Object? rawDocuments) {
    if (rawDocuments is! List) return null;

    Map<String, dynamic>? selectedDocument;
    int? selectedUploadTimestamp;

    for (final rawDocument in rawDocuments) {
      if (rawDocument is! Map) continue;
      final document = Map<String, dynamic>.from(rawDocument);
      final type = document['doc_type']?.toString().trim().toUpperCase();
      if (type != 'PORTFOLIO_IMAGE' && type != 'STUDIO_PHOTO') continue;

      final imageUrl = document['file_url']?.toString().trim() ?? '';
      final uri = Uri.tryParse(imageUrl);
      if (imageUrl.isEmpty ||
          uri == null ||
          !(uri.isScheme('http') || uri.isScheme('https'))) {
        continue;
      }

      final uploadTimestamp = _uploadTimestamp(document['file_name']);
      if (selectedDocument == null ||
          (uploadTimestamp != null &&
              selectedUploadTimestamp != null &&
              uploadTimestamp < selectedUploadTimestamp)) {
        selectedDocument = document;
        selectedUploadTimestamp = uploadTimestamp;
      }
    }

    return selectedDocument?['file_url']?.toString().trim();
  }

  int? _uploadTimestamp(Object? rawFileName) {
    final fileName = rawFileName?.toString().trim() ?? '';
    if (fileName.isEmpty) return null;
    return int.tryParse(fileName.split('_').first);
  }
}
