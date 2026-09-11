import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/domain/models/quest_location_validation.dart';
import 'package:warisan_kita/domain/models/user_location.dart';

void main() {
  final now = DateTime.utc(2026, 9, 11, 12);

  QuestLocationValidationResult validate({
    double latitude = 3.1416,
    double longitude = 101.6869,
    double accuracy = 10,
    DateTime? recordedAt,
    double distance = 20,
    double radius = 50,
  }) {
    return QuestLocationValidator.validate(
      reading: UserLocation(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        recordedAt: recordedAt ?? now.subtract(const Duration(seconds: 5)),
      ),
      distanceMeters: distance,
      radiusMeters: radius,
      nowUtc: now,
      maximumAge: const Duration(seconds: 30),
      maximumAccuracyMeters: 35,
    );
  }

  test('fresh accurate in-range reading succeeds', () {
    expect(validate().isValid, isTrue);
  });

  test('stale and future readings fail', () {
    expect(
      validate(recordedAt: now.subtract(const Duration(seconds: 31))).failure,
      QuestLocationFailure.stale,
    );
    expect(
      validate(recordedAt: now.add(const Duration(seconds: 1))).failure,
      QuestLocationFailure.stale,
    );
  });

  test('missing timestamp fails', () {
    final result = QuestLocationValidator.validate(
      reading: const UserLocation(
        latitude: 3.1416,
        longitude: 101.6869,
        accuracy: 10,
      ),
      distanceMeters: 20,
      radiusMeters: 50,
      nowUtc: now,
      maximumAge: const Duration(seconds: 30),
      maximumAccuracyMeters: 35,
    );
    expect(result.failure, QuestLocationFailure.missingTimestamp);
  });

  test('inaccurate, invalid, and non-finite accuracy fail', () {
    expect(validate(accuracy: 36).failure, QuestLocationFailure.inaccurate);
    expect(validate(accuracy: 0).failure, QuestLocationFailure.invalidAccuracy);
    expect(
      validate(accuracy: double.nan).failure,
      QuestLocationFailure.invalidAccuracy,
    );
  });

  test('invalid and non-finite coordinates fail', () {
    expect(
      validate(latitude: 91).failure,
      QuestLocationFailure.invalidCoordinates,
    );
    expect(
      validate(longitude: double.infinity).failure,
      QuestLocationFailure.invalidCoordinates,
    );
  });

  test('outside radius and non-finite distance fail', () {
    expect(validate(distance: 51).failure, QuestLocationFailure.outsideRadius);
    expect(
      validate(distance: double.nan).failure,
      QuestLocationFailure.invalidDistance,
    );
  });
}
