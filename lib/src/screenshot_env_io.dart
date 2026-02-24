import 'dart:io' show Platform;

/// Returns INITIAL_LOCATION from environment (used by screenshot workflows on iOS/macOS).
String? getInitialLocationFromEnv() =>
    Platform.environment['INITIAL_LOCATION'];
