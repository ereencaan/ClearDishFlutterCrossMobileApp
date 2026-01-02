// Re-export the platform implementation.
export 'iap_facade_stub.dart'
    if (dart.library.io) 'iap_facade_mobile.dart';

