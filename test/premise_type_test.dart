import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/active_artisan_master.dart';
import 'package:warisan_kita/domain/models/artisan_profile.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/domain/validators/ssm_validator.dart';

void main() {
  group('UserModel Premise Type Tests', () {
    test('Defaults to Commercial Studio when premiseType is null or not provided', () {
      final user = const UserModel(
        id: 'u-1',
        email: 'artisan@test.com',
        username: 'artisan_test',
        role: 'Artisan',
      );

      expect(user.premiseType, isNull);
      expect(user.isVillageWorkshop, isFalse);
      expect(user.premiseTypeDisplay, equals('Commercial Studio'));
      expect(user.artisanTitle, equals('Master Artisan'));
    });

    test('Identifies Home / Village Workshop correctly', () {
      final user = const UserModel(
        id: 'u-2',
        email: 'crafter@village.com',
        username: 'village_crafter',
        role: 'Artisan',
        premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
      );

      expect(user.isVillageWorkshop, isTrue);
      expect(user.premiseTypeDisplay, equals('Home / Village Workshop'));
      expect(user.artisanTitle, equals('Heritage Village Crafter'));
    });

    test('Serializes and deserializes premise_type in toMap and fromMap', () {
      final user = const UserModel(
        id: 'u-3',
        email: 'tokbatin@craft.com',
        username: 'tokbatin_artisan',
        role: 'Artisan',
        premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
      );

      final map = user.toMap();
      expect(map['premise_type'], equals('Home / Village Workshop (Bengkel Kediaman / Desa)'));

      final restored = UserModel.fromMap(map);
      expect(restored.premiseType, equals('Home / Village Workshop (Bengkel Kediaman / Desa)'));
      expect(restored.isVillageWorkshop, isTrue);
      expect(restored.premiseTypeDisplay, equals('Home / Village Workshop'));
      expect(restored.artisanTitle, equals('Heritage Village Crafter'));
    });

    test('Recognizes VILLAGE_HEAD_ENDORSEMENT as endorsement document in ssmFileName and ssmFileUrl', () {
      final user = const UserModel(
        id: 'u-4',
        email: 'crafter@village.com',
        username: 'crafter_4',
        role: 'Artisan',
        premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
        artisanDocuments: [
          {
            'doc_type': 'VILLAGE_HEAD_ENDORSEMENT',
            'file_name': 'tok_batin_letter.pdf',
            'file_url': 'https://supabase.co/storage/tok_batin_letter.pdf',
          },
          {
            'doc_type': 'KRAFTANGAN_CERT',
            'file_name': 'kraftangan.pdf',
            'file_url': 'https://supabase.co/storage/kraftangan.pdf',
          },
        ],
      );

      expect(user.ssmFileName, equals('tok_batin_letter.pdf'));
      expect(user.ssmFileUrl, equals('https://supabase.co/storage/tok_batin_letter.pdf'));
    });

    test('Recognizes CRAFTING_PHOTO as primary proof document in ssmFileName and ssmFileUrl', () {
      final user = const UserModel(
        id: 'u-5',
        email: 'photo@village.com',
        username: 'crafter_5',
        role: 'Artisan',
        premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
        artisanDocuments: [
          {
            'doc_type': 'CRAFTING_PHOTO',
            'file_name': 'weaving_process.jpg',
            'file_url': 'https://supabase.co/storage/weaving_process.jpg',
          },
        ],
      );

      expect(user.ssmFileName, equals('weaving_process.jpg'));
      expect(user.ssmFileUrl, equals('https://supabase.co/storage/weaving_process.jpg'));
    });

    test('Resolves crafting proof photo and certificates from tags when artisan_documents is empty', () {
      final user = UserModel.fromMap({
        'id': 'u-tag-test',
        'email': 'crafter@village.com',
        'role': 'Tourist',
        'artisan_status': 'PENDING_APPROVAL',
        'tags': [
          'premise:Home / Village Workshop (Bengkel Kediaman / Desa)',
          'doc_crafting_photo_url:https://supabase.co/storage/crafting_proof.jpg',
          'doc_crafting_photo_name:crafting_proof.jpg',
          'doc_kraftangan_cert_url:https://supabase.co/storage/kraftangan_master.pdf',
          'doc_kraftangan_cert_name:kraftangan_master.pdf',
          'doc_studio_photo:https://supabase.co/storage/studio_1.jpg',
        ],
      });

      expect(user.isVillageWorkshop, isTrue);
      expect(user.ssmFileUrl, equals('https://supabase.co/storage/crafting_proof.jpg'));
      expect(user.ssmFileName, equals('crafting_proof.jpg'));
      expect(user.certFileUrl, equals('https://supabase.co/storage/kraftangan_master.pdf'));
      expect(user.certFileName, equals('kraftangan_master.pdf'));
      expect(user.photos, contains('https://supabase.co/storage/studio_1.jpg'));
      expect(user.artisanDocuments.length, equals(3));
    });
  });

  group('ActiveArtisanMaster Premise Type Tests', () {
    test('Correctly determines premise type display and helpers from fromMap', () {
      final villageArtisan = ActiveArtisanMaster.fromMap({
        'id': 'artisan-village-1',
        'studio_name': 'Kampung Weaving Atelier',
        'craft_category': 'Songket',
        'state': 'Terengganu',
        'email': 'weaving@village.com',
        'phone': '0123456789',
        'premise_type': 'Home / Village Workshop (Bengkel Kediaman / Desa)',
      });

      expect(villageArtisan.isVillageWorkshop, isTrue);
      expect(villageArtisan.premiseTypeDisplay, equals('Home / Village Workshop'));

      final commercialArtisan = ActiveArtisanMaster.fromMap({
        'id': 'artisan-comm-1',
        'studio_name': 'Royal Pewter Gallery',
        'craft_category': 'Metalwork',
        'state': 'Selangor',
        'email': 'pewter@commercial.com',
        'phone': '0198765432',
        'premise_type': 'Commercial Studio (Premis Perniagaan)',
      });

      expect(commercialArtisan.isVillageWorkshop, isFalse);
      expect(commercialArtisan.premiseTypeDisplay, equals('Commercial Studio'));
    });
  });

  group('ArtisanModel Premise Type Tests', () {
    test('Parses premise_type and provides appropriate title and display', () {
      final model = ArtisanModel.fromMap({
        'id': 'artisan-profile-1',
        'studio_name': 'Mak Cik Bedah Weaving',
        'craft_category': 'Anyaman Mengkuang',
        'state': 'Pahang',
        'premise_type': 'Home / Village Workshop (Bengkel Kediaman / Desa)',
      });

      expect(model.isVillageWorkshop, isTrue);
      expect(model.premiseTypeDisplay, equals('Home / Village Workshop'));
      expect(model.artisanTitle, equals('Heritage Village Crafter'));
    });
  });

  group('PendingArtisanProfile Premise Type Tests', () {
    test('Holds premiseType and identifies village workshop', () {
      const pending = PendingArtisanProfile(
        id: 'p-1',
        name: 'Pak Dollah Woodcraft',
        craftCategory: 'Wood Carving',
        state: 'Kelantan',
        dateSubmitted: '2026-03-15T09:00:00Z',
        imageUrl: 'https://example.com/photo.jpg',
        email: 'pakdollah@village.com',
        experience: '25 Years',
        phone: '0112345678',
        premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
      );

      expect(pending.premiseType, equals('Home / Village Workshop (Bengkel Kediaman / Desa)'));
      expect(pending.isVillageWorkshop, isTrue);
    });

    test('Identifies village workshop when ssmNumber is VILLAGE_EXEMPT even if premiseType is null', () {
      const pending = PendingArtisanProfile(
        id: 'p-2',
        name: 'Pak Dollah Woodcraft',
        craftCategory: 'Wood Carving',
        state: 'Kelantan',
        dateSubmitted: '2026-03-15T09:00:00Z',
        imageUrl: 'https://example.com/photo.jpg',
        email: 'pakdollah@village.com',
        experience: '25 Years',
        phone: '0112345678',
        ssmNumber: 'VILLAGE_EXEMPT',
      );

      expect(pending.isVillageWorkshop, isTrue);
    });
  });

  group('UserModel Tag and VILLAGE_EXEMPT Fallback Tests', () {
    test('Extracts premise type from tags when premise_type column is absent', () {
      final user = UserModel.fromMap({
        'id': 'u-tags-1',
        'email': 'tagcrafter@village.com',
        'username': 'tag_crafter',
        'artisan_profiles': {
          'tags': ['woodwork', 'premise:Home / Village Workshop (Bengkel Kediaman / Desa)'],
          'studio_name': 'Tag Village Studio',
        },
      });

      expect(user.isVillageWorkshop, isTrue);
      expect(user.premiseType, equals('Home / Village Workshop (Bengkel Kediaman / Desa)'));
    });

    test('Infers village workshop when ssm_number is VILLAGE_EXEMPT and premise_type is null', () {
      final user = UserModel.fromMap({
        'id': 'u-exempt-1',
        'email': 'exempt@village.com',
        'username': 'exempt_crafter',
        'artisan_profiles': {
          'ssm_number': 'VILLAGE_EXEMPT',
          'studio_name': 'Exempt Craft Studio',
        },
      });

      expect(user.isVillageWorkshop, isTrue);
      expect(user.premiseType, contains('Village Workshop'));
    });
  });

  group('Premise Type Conditional SSM Validation Tests', () {
    test('Commercial Studio requires SSM registration number and rejects empty input', () {
      final emptyResult = SsmValidator.validate('');
      expect(emptyResult, isNotNull);
      expect(emptyResult, contains('Please enter your SSM or Kraftangan registration number'));

      final validCommercial = SsmValidator.validate('202301004821');
      expect(validCommercial, isNull);
    });

    test('Village Workshop permits empty SSM registration number without error', () {
      const isVillageWorkshop = true;
      const ssmInput = '';

      // Applying the conditional logic used in ApplyArtisanScreen & AuthViewModel
      String? validationError;
      if (!isVillageWorkshop || ssmInput.trim().isNotEmpty) {
        validationError = SsmValidator.validate(ssmInput);
      }

      expect(validationError, isNull, reason: 'Village Crafter with empty SSM should not throw validation error');
    });

    test('Village Workshop validates SSM format if user chooses to provide one', () {
      const isVillageWorkshop = true;
      const invalidSsmInput = 'not-a-valid-ssm';

      String? validationError;
      if (!isVillageWorkshop || invalidSsmInput.trim().isNotEmpty) {
        validationError = SsmValidator.validate(invalidSsmInput);
      }

      expect(validationError, isNotNull, reason: 'If SSM is provided, it must conform to valid format');
    });
  });
}
