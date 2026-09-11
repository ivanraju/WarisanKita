import 'package:warisan_kita/domain/models/user_location.dart';

enum QuestLocationFailure {
  unavailable,
  invalidCoordinates,
  missingTimestamp,
  stale,
  invalidAccuracy,
  inaccurate,
  invalidDistance,
  outsideRadius,
}

class QuestLocationValidationResult {
  final UserLocation? location;
  final double? distanceMeters;
  final QuestLocationFailure? failure;
  final String? message;

  const QuestLocationValidationResult.valid({
    required UserLocation this.location,
    required double this.distanceMeters,
  }) : failure = null,
       message = null;

  const QuestLocationValidationResult.invalid({
    required QuestLocationFailure this.failure,
    required String this.message,
    this.location,
    this.distanceMeters,
  });

  bool get isValid => failure == null && location != null;
}

class QuestLocationValidator {
  const QuestLocationValidator._();

  static QuestLocationValidationResult validate({
    required UserLocation reading,
    required double distanceMeters,
    required double radiusMeters,
    required DateTime nowUtc,
    required Duration maximumAge,
    required double maximumAccuracyMeters,
  }) {
    if (!reading.latitude.isFinite ||
        reading.latitude < -90 ||
        reading.latitude > 90 ||
        !reading.longitude.isFinite ||
        reading.longitude < -180 ||
        reading.longitude > 180) {
      return QuestLocationValidationResult.invalid(
        failure: QuestLocationFailure.invalidCoordinates,
        message: 'Current location is invalid. Refresh and try again.',
        location: reading,
      );
    }

    final recordedAt = reading.recordedAt;
    if (recordedAt == null) {
      return QuestLocationValidationResult.invalid(
        failure: QuestLocationFailure.missingTimestamp,
        message: 'Your location is out of date. Refresh and try again.',
        location: reading,
      );
    }
    final age = nowUtc.toUtc().difference(recordedAt.toUtc());
    if (age.isNegative || age > maximumAge) {
      return QuestLocationValidationResult.invalid(
        failure: QuestLocationFailure.stale,
        message: 'Your location is out of date. Refresh and try again.',
        location: reading,
      );
    }

    if (!reading.accuracy.isFinite || reading.accuracy <= 0) {
      return QuestLocationValidationResult.invalid(
        failure: QuestLocationFailure.invalidAccuracy,
        message: 'Waiting for a more accurate GPS reading.',
        location: reading,
      );
    }
    if (!maximumAccuracyMeters.isFinite ||
        maximumAccuracyMeters <= 0 ||
        reading.accuracy > maximumAccuracyMeters) {
      return QuestLocationValidationResult.invalid(
        failure: QuestLocationFailure.inaccurate,
        message: 'Waiting for a more accurate GPS reading.',
        location: reading,
      );
    }

    if (!distanceMeters.isFinite || distanceMeters < 0) {
      return QuestLocationValidationResult.invalid(
        failure: QuestLocationFailure.invalidDistance,
        message: 'Current location is unavailable. Please try again.',
        location: reading,
      );
    }
    if (!radiusMeters.isFinite ||
        radiusMeters <= 0 ||
        distanceMeters > radiusMeters) {
      final radiusLabel = radiusMeters.isFinite && radiusMeters > 0
          ? radiusMeters.toStringAsFixed(0)
          : 'the required';
      return QuestLocationValidationResult.invalid(
        failure: QuestLocationFailure.outsideRadius,
        message: 'Move within $radiusLabel m of the workshop to continue.',
        location: reading,
        distanceMeters: distanceMeters,
      );
    }

    return QuestLocationValidationResult.valid(
      location: reading,
      distanceMeters: distanceMeters,
    );
  }
}
