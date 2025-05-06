// apps/flutter_app/lib/platform/login/otpless.dart
export 'login_page_stub.dart' // Default implementation
    if (dart.library.html) 'login_page_web.dart' // Web implementation
    if (dart.library.io) 'login_page_mobile.dart';   // Mobile implementation