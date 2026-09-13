import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warisan_kita/data/services/google_map_service.dart';

void main() {
  group('Dark mode theming for Passport & Workshop Map Picker', () {
    late String passportSource;
    late String mapPickerSource;

    setUpAll(() {
      passportSource = File(
        'lib/ui/tourist/tourist_profile_tab.dart',
      ).readAsStringSync();
      mapPickerSource = File(
        'lib/ui/tourist/widgets/workshop_map_picker.dart',
      ).readAsStringSync();
    });

    test('GoogleMapService provides valid dark heritage map style', () {
      expect(GoogleMapService.darkHeritageMapStyle, isNotEmpty);
      expect(GoogleMapService.darkHeritageMapStyle, contains('#101c19'));
      expect(GoogleMapService.darkHeritageMapStyle, contains('#d5a928'));
    });

    test('TouristProfileTab has dark mode styling for empty passport card and notices', () {
      expect(passportSource, contains('_buildPassportStateCard'));
      expect(passportSource, contains('0xFF0D2825'));
      expect(passportSource, contains('0xFF1E3A34'));
      expect(passportSource, contains('0xFFFFE082'));
      expect(passportSource, contains('0xFF2E2305'));
      expect(passportSource, contains('isDark: isDark'));
    });

    test('WorkshopMapPickerPage has dark mode styling for scaffold, app bar, search bar and controls', () {
      expect(mapPickerSource, contains('GoogleMapService.darkHeritageMapStyle'));
      expect(mapPickerSource, contains('0xFF041412'));
      expect(mapPickerSource, contains('0xFF0D2825'));
      expect(mapPickerSource, contains('0xFF1E3A34'));
      expect(mapPickerSource, contains('0xFFFFE082'));
      expect(mapPickerSource, contains('0xFF6EE7B7'));
      expect(mapPickerSource, contains('0xFF94A3B8'));
    });
  });
}
