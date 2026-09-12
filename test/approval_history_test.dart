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
  });
}
