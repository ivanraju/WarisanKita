import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/data/repositories/user_repository.dart';
import 'package:warisan_kita/data/services/supabase_service.dart';
import 'package:warisan_kita/domain/models/user.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';
import 'support/auth_backend.dart';

class TestableAuthViewModel extends AuthViewModel {
  TestableAuthViewModel({required super.repository});

  @override
  Future<UserModel?> refreshCurrentUser() async => currentUser;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Artisan Application Documents Display Tests', () {
    late AuthBackend backend;
    late SupabaseService service;
    late UserRepository repository;
    late TestableAuthViewModel authVM;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      backend = AuthBackend();
      service = SupabaseService(client: backend.client);
      repository = UserRepository(service: service);
      authVM = TestableAuthViewModel(repository: repository);
    });

    tearDown(() {
      backend.client.dispose();
      authVM.dispose();
    });

    Widget createTestWidget({
      required Widget child,
      Size surfaceSize = const Size(1000, 1800),
    }) {
      return ChangeNotifierProvider<AuthViewModel>.value(
        value: authVM,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: surfaceSize),
            child: child,
          ),
        ),
      );
    }

    testWidgets('Commercial Studio displays SSM and Kraftangan Cert documents with mandatory badges', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final user = const UserModel(
        id: 'comm_user_1',
        email: 'commercial@craft.my',
        role: 'Tourist',
        status: 'PENDING_APPROVAL',
        studioName: 'Royal Pewter Studio',
        craftCategory: 'Metalwork',
        premiseType: 'Commercial Studio (Premis Perniagaan)',
        ssmNumber: '202601099881',
        artisanDocuments: [
          {
            'doc_type': 'SSM_BUSINESS_CERT',
            'file_name': 'SSM_Registration_2026.pdf',
            'file_url': 'https://storage.test/docs/ssm_cert.pdf',
          },
          {
            'doc_type': 'KRAFTANGAN_MASTER_CERT',
            'file_name': 'Kraftangan_Master_Accreditation.pdf',
            'file_url': 'https://storage.test/docs/kraftangan_cert.pdf',
          },
          {
            'doc_type': 'PORTFOLIO_IMAGE',
            'file_url': 'https://storage.test/photos/workshop_1.jpg',
            'file_name': 'workshop_1.jpg',
          }
        ],
      );

      authVM.setCurrentUserForTesting(user);

      await tester.pumpWidget(
        createTestWidget(
          child: const ArtisanApplicationPendingScreen(
            studioName: 'Royal Pewter Studio',
            craftCategory: 'Metalwork',
            ssmNumber: '202601099881',
            premiseType: 'Commercial Studio (Premis Perniagaan)',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify header and commercial section title
      expect(find.text('Application Submitted Successfully!'), findsOneWidget);
      expect(find.text('Commercial Studio Uploaded Documents'), findsOneWidget);

      // Verify SSM card and badge
      expect(find.text('MANDATORY SSM'), findsOneWidget);
      expect(find.text('SSM Business Registration Document'), findsOneWidget);
      expect(find.text('SSM_Registration_2026.pdf'), findsOneWidget);

      // Verify Kraftangan Cert card and badge
      expect(find.text('MANDATORY ACCREDITATION'), findsOneWidget);
      expect(find.text('Kraftangan Master Accreditation Certificate'), findsOneWidget);
      expect(find.text('Kraftangan_Master_Accreditation.pdf'), findsOneWidget);

      // Verify studio photos gallery section
      expect(find.textContaining('Studio / Workshop Photos'), findsOneWidget);

      // Tap View on the SSM document to open the preview dialog
      final viewButtons = find.text('View');
      expect(viewButtons, findsWidgets);
      await tester.tap(viewButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify document preview dialog rendered
      expect(find.text('SSM Business Registration Document'), findsWidgets);
      expect(find.text('Close Preview'), findsOneWidget);

      // Close the preview
      await tester.tap(find.text('Close Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Close Preview'), findsNothing);
    });

    testWidgets('Home / Village Studio displays Crafting Photo proof and optional items', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final user = const UserModel(
        id: 'village_user_1',
        email: 'village@craft.my',
        role: 'Tourist',
        status: 'PENDING_APPROVAL',
        studioName: 'Desa Anyaman Studio',
        craftCategory: 'Weaving',
        premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
        ssmNumber: 'VILLAGE_EXEMPT',
        artisanDocuments: [
          {
            'doc_type': 'CRAFTING_PHOTO',
            'file_name': 'Crafting_Process_Evidence.jpg',
            'file_url': 'https://storage.test/photos/crafting_process.jpg',
          },
        ],
      );

      authVM.setCurrentUserForTesting(user);

      await tester.pumpWidget(
        createTestWidget(
          child: const ArtisanApplicationPendingScreen(
            studioName: 'Desa Anyaman Studio',
            craftCategory: 'Weaving',
            ssmNumber: 'VILLAGE_EXEMPT',
            premiseType: 'Home / Village Workshop (Bengkel Kediaman / Desa)',
            ssmFileName: 'Crafting_Process_Evidence.jpg',
            ssmFileUrl: 'https://storage.test/photos/crafting_process.jpg',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify village section title
      expect(find.text('Home Studio Uploaded Documents'), findsOneWidget);

      // Verify mandatory Crafting Photo Evidence
      expect(find.text('MANDATORY PROOF'), findsOneWidget);
      expect(find.text('Crafting Photo Evidence (Proof)'), findsOneWidget);
      expect(find.text('Crafting_Process_Evidence.jpg'), findsOneWidget);

      // Verify optional SSM is shown as exempted for village workshop
      expect(find.textContaining('Exempted for Home / Village Crafters'), findsOneWidget);

      // Verify optional Kraftangan certificate is shown as optional / not attached
      expect(find.textContaining('Optional for Home / Village Workshops'), findsOneWidget);

      // Tap View on crafting photo proof to trigger preview
      final viewButton = find.text('View');
      expect(viewButton, findsOneWidget);
      await tester.tap(viewButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Attached File: Crafting_Process_Evidence.jpg'), findsOneWidget);
      expect(find.text('Close Preview'), findsOneWidget);

      await tester.tap(find.text('Close Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Rejection page displays both uploaded documents and official review feedback', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final user = const UserModel(
        id: 'rejected_artisan_1',
        email: 'rejected@craft.my',
        role: 'Tourist',
        status: 'REJECTED',
        artisanStatus: 'REJECTED',
        rejectionReason: 'The uploaded SSM certificate is expired. Please upload valid current documentation.',
        studioName: 'Pak Mat Batik',
        craftCategory: 'Batik',
        premiseType: 'Commercial Studio (Premis Perniagaan)',
        ssmNumber: '202001998877',
        artisanDocuments: [
          {
            'doc_type': 'SSM_BUSINESS_CERT',
            'file_name': 'Old_SSM_Expired.pdf',
            'file_url': 'https://storage.test/docs/old_ssm.pdf',
          },
          {
            'doc_type': 'KRAFTANGAN_MASTER_CERT',
            'file_name': 'Kraftangan_Cert.pdf',
            'file_url': 'https://storage.test/docs/kraftangan.pdf',
          },
        ],
      );

      authVM.setCurrentUserForTesting(user);

      await tester.pumpWidget(
        createTestWidget(
          child: const ArtisanApplicationPendingScreen(
            studioName: 'Pak Mat Batik',
            craftCategory: 'Batik',
            ssmNumber: '202001998877',
            premiseType: 'Commercial Studio (Premis Perniagaan)',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify rejection header and badge
      expect(find.text('❌ APPLICATION NOT APPROVED'), findsOneWidget);
      expect(find.text('Application Needs Update'), findsOneWidget);

      // Verify uploaded documents are present on rejection page
      expect(find.text('Commercial Studio Uploaded Documents'), findsOneWidget);
      expect(find.text('Old_SSM_Expired.pdf'), findsOneWidget);
      expect(find.text('Kraftangan_Cert.pdf'), findsOneWidget);

      // Verify official feedback notice is present
      expect(find.text('OFFICIAL REVIEW FEEDBACK'), findsOneWidget);
      expect(find.textContaining('The uploaded SSM certificate is expired'), findsOneWidget);

      // Verify re-apply action button is available
      expect(find.text('Update Documents & Re-Apply'), findsOneWidget);
    });
  });
}
