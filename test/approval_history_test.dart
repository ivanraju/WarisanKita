import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/approval_history_record.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/viewmodels/moderation_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApprovalHistoryRecord Model Tests', () {
    test('serializes and deserializes cleanly through toMap and fromMap', () {
      final now = DateTime(2026, 9, 12, 14, 30);
      final record = ApprovalHistoryRecord(
        id: 'hist_12345',
        title: 'Master Artisan Profile Approved',
        targetName: 'Pak Ali Woodcraft',
        targetEmail: 'ali@woodcraft.my',
        approvalType: 'Artisan Profile',
        craftCategory: 'Wood Carving',
        state: 'Terengganu',
        details: 'Approved with SSM license 202601004821 • Experience: 15 Years',
        previousPremise: null,
        newPremise: 'Pak Ali Woodcraft Studio (Terengganu)',
        ssmNumber: '202601004821',
        approvedAt: now,
        approvedBy: 'Admin Moderator',
        status: 'APPROVED',
      );

      final map = record.toMap();
      expect(map['id'], 'hist_12345');
      expect(map['targetName'], 'Pak Ali Woodcraft');
      expect(map['approvalType'], 'Artisan Profile');
      expect(map['craftCategory'], 'Wood Carving');

      final reconstructed = ApprovalHistoryRecord.fromMap(map);
      expect(reconstructed.id, record.id);
      expect(reconstructed.title, record.title);
      expect(reconstructed.targetName, record.targetName);
      expect(reconstructed.targetEmail, record.targetEmail);
      expect(reconstructed.approvalType, record.approvalType);
      expect(reconstructed.craftCategory, record.craftCategory);
      expect(reconstructed.state, record.state);
      expect(reconstructed.details, record.details);
      expect(reconstructed.ssmNumber, record.ssmNumber);
      expect(reconstructed.isRelocation, isFalse);
      expect(reconstructed.formattedDate, '12 Sep 2026');
      expect(reconstructed.formattedTime, '14:30');
    });

    test('correctly identifies relocation approval type', () {
      final record = ApprovalHistoryRecord(
        id: 'hist_reloc_99',
        title: 'Workshop Premise Relocation Approved',
        targetName: 'Siti Batik Studio',
        targetEmail: 'siti@batik.my',
        approvalType: 'Premise Relocation',
        craftCategory: 'Batik Weaving',
        state: 'Kelantan',
        details: 'Relocated from Kota Bharu to Pasir Mas',
        previousPremise: '12 Jalan Sultan, Kota Bharu',
        newPremise: '88 Jalan Merdeka, Pasir Mas',
        approvedAt: DateTime(2026, 9, 12, 10, 15),
      );

      expect(record.isRelocation, isTrue);
      expect(record.formattedDate, '12 Sep 2026');
      expect(record.formattedTime, '10:15');
      expect(record.formattedDateTime, '12 Sep 2026 at 10:15');
    });

    test('correctly serializes, deserializes, and computes allDocuments for uploaded documents', () {
      final now = DateTime(2026, 9, 12, 16, 0);
      final record = ApprovalHistoryRecord(
        id: 'hist_docs_1',
        title: 'Master Artisan Profile Approved',
        targetName: 'Hassan Royal Keris',
        targetEmail: 'hassan@keris.my',
        approvalType: 'Artisan Profile',
        craftCategory: 'Metalwork & Weaponry',
        state: 'Perak',
        details: 'Approved with SSM license and master accreditation',
        ssmNumber: 'SSM-1029384',
        ssmFileName: 'hassan_ssm_cert.pdf',
        ssmFileUrl: 'https://storage.warisankita.my/docs/hassan_ssm.pdf',
        certFileName: 'kraftangan_master_keris.pdf',
        certFileUrl: 'https://storage.warisankita.my/docs/kraftangan_cert.pdf',
        photos: const [
          'https://storage.warisankita.my/photos/forge1.jpg',
          'https://storage.warisankita.my/photos/forge2.jpg',
        ],
        documents: const [
          {
            'name': 'Apprenticeship Endorsement.pdf',
            'url': 'https://storage.warisankita.my/docs/endorsement.pdf',
            'type': 'endorsement',
          }
        ],
        approvedAt: now,
      );

      expect(record.hasDocuments, isTrue);
      expect(record.ssmFileName, 'hassan_ssm_cert.pdf');
      expect(record.ssmFileUrl, 'https://storage.warisankita.my/docs/hassan_ssm.pdf');
      expect(record.photos.length, 2);

      final allDocs = record.allDocuments;
      expect(allDocs.length, 5); // 1 generic doc + 1 SSM + 1 cert + 2 photos
      expect(allDocs.any((d) => d['name'] == 'hassan_ssm_cert.pdf'), isTrue);
      expect(allDocs.any((d) => d['name'] == 'kraftangan_master_keris.pdf'), isTrue);
      expect(allDocs.any((d) => d['name'] == 'Studio Photo 1'), isTrue);
      expect(allDocs.any((d) => d['name'] == 'Apprenticeship Endorsement.pdf'), isTrue);

      final map = record.toMap();
      final restored = ApprovalHistoryRecord.fromMap(map);

      expect(restored.hasDocuments, isTrue);
      expect(restored.ssmFileName, record.ssmFileName);
      expect(restored.ssmFileUrl, record.ssmFileUrl);
      expect(restored.certFileName, record.certFileName);
      expect(restored.certFileUrl, record.certFileUrl);
      expect(restored.photos, record.photos);
      expect(restored.allDocuments.length, 5);
    });
  });

  group('ModerationViewModel Approval History Integration Tests', () {
    late SupabaseService mockService;
    late UserRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockService = SupabaseService();
      repository = UserRepository(service: mockService);
    });

    test('approveArtisan records an Artisan Profile approval record in history', () async {
      final vm = ModerationViewModel(repository: repository);
      await vm.refreshAllData();

      final pending = PendingArtisanProfile(
        id: 'p_test_approval_history',
        name: 'Heritage Pewter Studio',
        craftCategory: 'Pewter Craft',
        state: 'Kuala Lumpur',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/artisan.jpg',
        email: 'pewter.master@warisankita.my',
        experience: '12 Years',
        phone: '+60 12-345 6789',
        ssmNumber: 'SSM-889911',
      );
      vm.addPendingArtisan(pending);
      vm.addUserForTesting(
        UserModel(
          id: 'u_pewter_master',
          email: 'pewter.master@warisankita.my',
          displayName: 'Heritage Pewter Studio',
          role: 'Tourist',
          roles: const ['Tourist'],
          status: 'PENDING_APPROVAL',
        ),
      );

      final initialCount = vm.totalApprovalHistoryCount;
      final success = await vm.approveArtisan('p_test_approval_history');
      expect(success, isTrue);

      expect(vm.totalApprovalHistoryCount, initialCount + 1);
      final latest = vm.approvalHistory.first;
      expect(latest.targetName, 'Heritage Pewter Studio');
      expect(latest.targetEmail, 'pewter.master@warisankita.my');
      expect(latest.approvalType, 'Artisan Profile');
      expect(latest.craftCategory, 'Pewter Craft');
      expect(latest.ssmNumber, 'SSM-889911');
      expect(latest.isRelocation, isFalse);
    });

    test('approveArtisan records a Premise Relocation approval record in history', () async {
      final vm = ModerationViewModel(repository: repository);
      await vm.refreshAllData();

      final reloc = PendingArtisanProfile(
        id: 'reloc_artisan_456',
        name: 'Melaka Heritage Pottery',
        craftCategory: 'Pottery & Ceramics',
        state: 'Melaka',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/pottery.jpg',
        email: 'pottery.reloc@warisankita.my',
        experience: '20 Years',
        phone: '+60 19-876 5432',
        isRelocationRequest: true,
        currentAddress: '10 Old Town, Melaka',
        proposedAddress: '25 Jonker Street, Melaka',
        proposedState: 'Melaka',
      );
      vm.addRelocationRequest(reloc);

      final initialCount = vm.totalApprovalHistoryCount;
      final success = await vm.approveArtisan('reloc_artisan_456');
      expect(success, isTrue);

      expect(vm.totalApprovalHistoryCount, initialCount + 1);
      final latest = vm.approvalHistory.first;
      expect(latest.targetName, 'Melaka Heritage Pottery');
      expect(latest.approvalType, 'Premise Relocation');
      expect(latest.isRelocation, isTrue);
      expect(latest.previousPremise, '10 Old Town, Melaka');
      expect(latest.newPremise, '25 Jonker Street, Melaka');
    });

    test('search and type filters filter history correctly', () async {
      final vm = ModerationViewModel(repository: repository);
      await vm.refreshAllData();

      // Seed approvals
      final profile = PendingArtisanProfile(
        id: 'p_filter_1',
        name: 'Terengganu Songket Weavers',
        craftCategory: 'Songket Weaving',
        state: 'Terengganu',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/songket.jpg',
        email: 'songket@terengganu.my',
        experience: '8 Years',
        phone: '+60 11-1234567',
        ssmNumber: 'SSM-SONGKET-01',
      );
      vm.addPendingArtisan(profile);
      await vm.approveArtisan('p_filter_1');

      final reloc = PendingArtisanProfile(
        id: 'reloc_filter_2',
        name: 'Borneo Woodcarvers',
        craftCategory: 'Wood Carving',
        state: 'Sarawak',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/wood.jpg',
        email: 'wood@borneo.my',
        experience: '18 Years',
        phone: '+60 13-9988776',
        isRelocationRequest: true,
        currentAddress: 'Old Kuching Bazaar',
        proposedAddress: 'Sarawak Cultural Village',
        proposedState: 'Sarawak',
      );
      vm.addRelocationRequest(reloc);
      await vm.approveArtisan('reloc_filter_2');

      // Test search query
      vm.setHistorySearchQuery('Songket');
      expect(vm.filteredApprovalHistory.length, 1);
      expect(vm.filteredApprovalHistory.first.targetName, 'Terengganu Songket Weavers');

      // Test type filter
      vm.setHistorySearchQuery('');
      vm.setHistoryTypeFilter('Premise Relocations');
      expect(
        vm.filteredApprovalHistory.every((r) => r.approvalType == 'Premise Relocation'),
        isTrue,
      );
      expect(
        vm.filteredApprovalHistory.any((r) => r.targetName == 'Borneo Woodcarvers'),
        isTrue,
      );

      vm.setHistoryTypeFilter('Artisan Profiles');
      expect(
        vm.filteredApprovalHistory.every((r) => r.approvalType == 'Artisan Profile'),
        isTrue,
      );
      expect(
        vm.filteredApprovalHistory.any((r) => r.targetName == 'Terengganu Songket Weavers'),
        isTrue,
      );

      // Reset
      vm.setHistoryTypeFilter('All Types');
      expect(vm.filteredApprovalHistory.length >= 2, isTrue);
    });

    test('relocation request persists and remains visible across refreshAllData()', () async {
      final vm = ModerationViewModel(repository: repository);
      await vm.refreshAllData();

      const reloc = PendingArtisanProfile(
        id: 'reloc_persisted_777',
        name: 'Mahani Songket Atelier',
        craftCategory: 'Textile Weaving',
        state: 'Kelantan',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/mahani.jpg',
        email: 'mahani@songket.my',
        experience: '25 Years',
        phone: '+60 12-3334444',
        isRelocationRequest: true,
        currentAddress: '10 Kota Bharu Bazaar',
        proposedAddress: '88 Pasir Mas Heritage Craft Village',
        proposedState: 'Kelantan',
        proposedLatitude: 6.0421,
        proposedLongitude: 102.1432,
      );

      vm.addRelocationRequest(reloc);

      // Verify immediate presence
      expect(vm.pendingRelocations.any((r) => r.id == 'reloc_persisted_777'), isTrue);

      // Simulate admin dashboard refresh (which invokes refreshAllData and fetchPendingArtisans)
      await vm.refreshAllData();

      // Ensure relocation was NOT wiped by fetchPendingArtisans
      expect(vm.pendingRelocations.any((r) => r.id == 'reloc_persisted_777'), isTrue);
      expect(vm.filteredRelocations.any((r) => r.id == 'reloc_persisted_777'), isTrue);

      // Verify tab switching resets filter query so relocations are not accidentally hidden
      vm.setSearchQuery('NonExistentArtisan');
      expect(vm.filteredRelocations.isEmpty, isTrue);

      vm.setActiveTab('Workshop Relocations');
      expect(vm.searchQuery, isEmpty);
      expect(vm.filteredRelocations.any((r) => r.id == 'reloc_persisted_777'), isTrue);
    });

    test('approveArtisan preserves and records uploaded documents in approval history', () async {
      final vm = ModerationViewModel(repository: repository);
      await vm.refreshAllData();

      final pendingWithDocs = const PendingArtisanProfile(
        id: 'p_docs_test',
        name: 'Pak Daud Wau Atelier',
        craftCategory: 'Wau Making',
        state: 'Kelantan',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/daud.jpg',
        email: 'daud.wau@warisankita.my',
        experience: '30 Years',
        phone: '+60 19-1234567',
        ssmNumber: '202601009988',
        ssmFileName: 'daud_ssm_certificate.pdf',
        ssmFileUrl: 'https://storage.warisankita.my/docs/daud_ssm.pdf',
        certFileName: 'kraftangan_wau_master.pdf',
        certFileUrl: 'https://storage.warisankita.my/docs/daud_cert.pdf',
        photos: [
          'https://storage.warisankita.my/photos/wau_photo1.jpg',
          'https://storage.warisankita.my/photos/wau_photo2.jpg',
        ],
      );

      vm.addPendingArtisan(pendingWithDocs);
      final success = await vm.approveArtisan('p_docs_test');
      expect(success, isTrue);

      final latest = vm.approvalHistory.first;
      expect(latest.targetEmail, 'daud.wau@warisankita.my');
      expect(latest.hasDocuments, isTrue);
      expect(latest.ssmFileName, 'daud_ssm_certificate.pdf');
      expect(latest.ssmFileUrl, 'https://storage.warisankita.my/docs/daud_ssm.pdf');
      expect(latest.certFileName, 'kraftangan_wau_master.pdf');
      expect(latest.certFileUrl, 'https://storage.warisankita.my/docs/daud_cert.pdf');
      expect(latest.photos.length, 2);
      expect(latest.allDocuments.length, 4);
    });

    test('approveArtisan for premise relocation preserves relocation documents in approval history', () async {
      final vm = ModerationViewModel(repository: repository);
      await vm.refreshAllData();

      final relocWithDocs = const PendingArtisanProfile(
        id: 'reloc_docs_test',
        name: 'Kak Som Batik Gallery',
        craftCategory: 'Batik Weaving',
        state: 'Terengganu',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/som.jpg',
        email: 'som.batik@warisankita.my',
        experience: '22 Years',
        phone: '+60 12-9876543',
        isRelocationRequest: true,
        currentAddress: '15 Jalan Pantai, Terengganu',
        proposedAddress: '42 Pasar Payang, Terengganu',
        proposedState: 'Terengganu',
        ssmFileName: 'som_ssm.pdf',
        ssmFileUrl: 'https://storage.warisankita.my/docs/som_ssm.pdf',
        relocationCertFileName: 'pasar_payang_tenancy_cert.pdf',
        relocationCertFileUrl: 'https://storage.warisankita.my/docs/pasar_payang_cert.pdf',
      );

      vm.addRelocationRequest(relocWithDocs);
      final success = await vm.approveArtisan('reloc_docs_test');
      expect(success, isTrue);

      final latest = vm.approvalHistory.first;
      expect(latest.targetEmail, 'som.batik@warisankita.my');
      expect(latest.isRelocation, isTrue);
      expect(latest.hasDocuments, isTrue);
      expect(latest.relocationCertFileName, 'pasar_payang_tenancy_cert.pdf');
      expect(latest.relocationCertFileUrl, 'https://storage.warisankita.my/docs/pasar_payang_cert.pdf');
      expect(latest.allDocuments.any((d) => d['name'] == 'pasar_payang_tenancy_cert.pdf'), isTrue);
    });

    test('rejectArtisan records documents in approval history', () async {
      final vm = ModerationViewModel(repository: repository);
      await vm.refreshAllData();

      final pendingRejected = const PendingArtisanProfile(
        id: 'p_reject_docs_test',
        name: 'Rejected Metal Crafts',
        craftCategory: 'Metalwork',
        state: 'Johor',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/reject.jpg',
        email: 'reject.metal@warisankita.my',
        experience: '1 Year',
        phone: '+60 11-00112233',
        ssmFileName: 'blurry_ssm_photo.jpg',
        ssmFileUrl: 'https://storage.warisankita.my/docs/blurry_ssm.jpg',
      );

      vm.addPendingArtisan(pendingRejected);
      await vm.rejectArtisan('p_reject_docs_test', reason: 'SSM document is illegible');

      final latest = vm.approvalHistory.first;
      expect(latest.targetEmail, 'reject.metal@warisankita.my');
      expect(latest.status, 'REJECTED');
      expect(latest.hasDocuments, isTrue);
      expect(latest.ssmFileName, 'blurry_ssm_photo.jpg');
      expect(latest.ssmFileUrl, 'https://storage.warisankita.my/docs/blurry_ssm.jpg');
      expect(latest.details, contains('SSM document is illegible'));
    });

    test('approval history persists across reload even before fetchActiveArtisans/fetchAllUsers complete', () async {
      // Step 1: Initialize ViewModel and approve an artisan
      final vm1 = ModerationViewModel(repository: repository);
      await vm1.refreshAllData();

      final profile = const PendingArtisanProfile(
        id: 'p_persist_reload_1',
        name: 'Reload Persistence Test Master',
        craftCategory: 'Woodcraft',
        state: 'Perak',
        dateSubmitted: 'Today',
        imageUrl: 'https://example.com/wood.jpg',
        email: 'persist.reload@warisankita.my',
        experience: '15 Years',
        phone: '+60 12-3456789',
        ssmNumber: 'SSM-RELOAD-12345',
      );
      vm1.addPendingArtisan(profile);
      final success = await vm1.approveArtisan('p_persist_reload_1');
      expect(success, isTrue);
      expect(vm1.approvalHistory.any((r) => r.targetEmail == 'persist.reload@warisankita.my'), isTrue);

      // Step 2: Simulate page reload (F5) - a new ModerationViewModel instance is created.
      // On browser reload, SharedPreferences is already populated from Step 1,
      // but activeArtisans and registeredUsers are still empty until network fetches finish.
      final vmReload = ModerationViewModel(repository: repository);
      await vmReload.loadApprovalHistory();

      // Ensure the history was NOT wiped out by pruning while activeArtisans was empty!
      expect(
        vmReload.approvalHistory.any((r) => r.targetEmail == 'persist.reload@warisankita.my'),
        isTrue,
        reason: 'Approval history must survive page reload when active artisans have not loaded yet',
      );
    });

    test('loadApprovalHistory reconciles approved artisans from registered users on fresh device', () async {
      // Simulate a fresh device: clear SharedPreferences
      SharedPreferences.setMockInitialValues({});

      final vmFresh = ModerationViewModel(repository: repository);
      // Simulate fetchAllUsers returning an approved artisan
      vmFresh.addUserForTesting(
        const UserModel(
          id: 'u_approved_reconcile',
          email: 'reconciled.artisan@warisankita.my',
          displayName: 'Reconciled Artisan Master',
          role: 'Artisan',
          status: 'ACTIVE',
          artisanStatus: 'APPROVED',
          craftCategory: 'Batik Craft',
          state: 'Kelantan',
          joinedDate: '2026-01-15T10:00:00.000Z',
        ),
      );

      await vmFresh.loadApprovalHistory();

      expect(
        vmFresh.approvalHistory.any((r) => r.targetEmail == 'reconciled.artisan@warisankita.my'),
        isTrue,
        reason: 'Approved users in Supabase should be reconciled into approval history even on a fresh device',
      );
    });
  });
}

