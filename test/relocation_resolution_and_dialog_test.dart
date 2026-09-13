import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/approval_history_record.dart';
import 'package:warisan_kita/domain/models/pending_artisan_profile.dart';
import 'package:warisan_kita/ui/admin_web/widgets/artisan_review_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 1: ArtisanReviewDialog Inline Error Validation', () {
    testWidgets('Shows inline error in dialog when rejecting with empty reason',
        (tester) async {
      final pendingRelocation = PendingArtisanProfile(
        id: 'reloc_test_1',
        name: 'Test Artisan Studio',
        craftCategory: 'Batik',
        state: 'Melaka',
        dateSubmitted: '2026-09-13T12:00:00Z',
        imageUrl: 'https://images.unsplash.com/photo-1',
        email: 'artisan@test.my',
        experience: '10 Years',
        phone: '+60 12-345 6789',
        isRelocationRequest: true,
        currentAddress: 'Current Address 123',
        proposedAddress: 'Proposed New Premise 456',
        relocationReason: 'Expansion of workshop',
      );

      String? rejectedReason;
      bool approved = false;
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dlgContext) => ArtisanReviewDialog(
                        artisan: pendingRelocation,
                        onApprove: () => approved = true,
                        onReject: (reason) => rejectedReason = reason,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ArtisanReviewDialog), findsOneWidget);

      // Tap 'Reject Relocation' without entering feedback
      await tester.ensureVisible(find.text('Reject Relocation'));
      await tester.tap(find.text('Reject Relocation'));
      await tester.pumpAndSettle();

      // Dialog must NOT be dismissed
      expect(find.byType(ArtisanReviewDialog), findsOneWidget);
      expect(rejectedReason, isNull);

      // An inline error must be visible directly on screen
      expect(
        find.text(
          'Please enter rejection feedback explaining the reason to the applicant.',
        ),
        findsAtLeastNWidgets(1),
      );

      // Enter feedback and tap Reject again
      await tester.enterText(
        find.byType(TextField),
        'Premise permit missing or invalid council stamp.',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reject Relocation'));
      await tester.tap(find.text('Reject Relocation'));
      await tester.pumpAndSettle();

      // Dialog is dismissed and callback receives reason
      expect(find.byType(ArtisanReviewDialog), findsNothing);
      expect(
        rejectedReason,
        'Premise permit missing or invalid council stamp.',
      );
      expect(approved, isFalse);
    });
  });

  group('Issue 3: ApprovalHistoryRecord strictly isolates proof of relocation', () {
    test('allDocuments for Premise Relocation excludes SSM, Kraftangan, and photos', () {
      final relocationRecord = ApprovalHistoryRecord(
        id: 'hist_reloc_1',
        title: 'Workshop Premise Relocation Approved',
        targetName: 'Master Artisan',
        targetEmail: 'artisan@test.my',
        approvalType: 'Premise Relocation',
        craftCategory: 'Batik',
        state: 'Melaka',
        details: 'Relocated to Melaka Raya',
        previousPremise: 'Old Address',
        newPremise: 'New Address',
        ssmNumber: 'SSM-12345',
        ssmFileName: 'ssm_cert.pdf',
        ssmFileUrl: 'https://storage.test/ssm_cert.pdf',
        certFileName: 'master_cert.pdf',
        certFileUrl: 'https://storage.test/master_cert.pdf',
        photos: const ['https://storage.test/studio1.jpg'],
        relocationCertFileName: 'relocation_proof_council.pdf',
        relocationCertFileUrl: 'https://storage.test/relocation_proof_council.pdf',
        documents: const [
          {
            'name': 'ssm.pdf',
            'url': 'https://storage.test/ssm.pdf',
            'doc_type': 'SSM_BUSINESS_CERT',
          },
          {
            'name': 'relocation_permit.pdf',
            'url': 'https://storage.test/relocation_permit.pdf',
            'doc_type': 'RELOCATION_CERT',
          }
        ],
        approvedAt: DateTime(2026, 9, 13),
      );

      expect(relocationRecord.isRelocation, isTrue);
      expect(relocationRecord.hasDocuments, isTrue);

      final docs = relocationRecord.allDocuments;
      // Must contain ONLY relocation documents
      expect(docs.length, 2);
      for (final doc in docs) {
        final type = (doc['doc_type'] ?? doc['type'] ?? '').toString().toUpperCase();
        expect(type.contains('RELOCATION'), isTrue);
      }
      expect(docs.any((d) => d['url'] == 'https://storage.test/ssm_cert.pdf'), isFalse);
      expect(docs.any((d) => d['url'] == 'https://storage.test/master_cert.pdf'), isFalse);
      expect(docs.any((d) => d['url'] == 'https://storage.test/studio1.jpg'), isFalse);
      expect(docs.any((d) => d['url'] == 'https://storage.test/ssm.pdf'), isFalse);
    });

    test('allDocuments for Artisan Profile approval retains full documents', () {
      final profileRecord = ApprovalHistoryRecord(
        id: 'hist_artisan_1',
        title: 'Master Artisan Profile Approved',
        targetName: 'Master Artisan',
        targetEmail: 'artisan@test.my',
        approvalType: 'Artisan Profile',
        craftCategory: 'Batik',
        state: 'Melaka',
        details: 'Approved',
        ssmFileName: 'ssm_cert.pdf',
        ssmFileUrl: 'https://storage.test/ssm_cert.pdf',
        certFileName: 'master_cert.pdf',
        certFileUrl: 'https://storage.test/master_cert.pdf',
        photos: const ['https://storage.test/studio1.jpg'],
        approvedAt: DateTime(2026, 9, 13),
      );

      expect(profileRecord.isRelocation, isFalse);
      final docs = profileRecord.allDocuments;
      expect(docs.length, 3);
      expect(docs.any((d) => d['url'] == 'https://storage.test/ssm_cert.pdf'), isTrue);
      expect(docs.any((d) => d['url'] == 'https://storage.test/master_cert.pdf'), isTrue);
      expect(docs.any((d) => d['url'] == 'https://storage.test/studio1.jpg'), isTrue);
    });
  });
}
