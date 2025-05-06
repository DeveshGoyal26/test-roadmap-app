// apps/flutter_app/lib/platform/login/login_page_mobile.dart
import 'package:otpless_flutter/otpless_flutter.dart' as otpless_flutter;
import 'package:otpless_flutter/otpless_flutter_method_channel.dart';

class OtplessImplementation {
  final _otplessFlutterPlugin = otpless_flutter.Otpless();

  dynamic get instance => _otplessFlutterPlugin;

  void initOtplessHeadless(String clientId) {
    _otplessFlutterPlugin.initHeadless(clientId);
    _otplessFlutterPlugin.setLoaderVisibility(true);
    _otplessFlutterPlugin.enableDebugLogging(true);
    _otplessFlutterPlugin.setWebviewInspectable(true);
  }

  void startHeadless(OtplessResultCallback callback, Map<String, dynamic> arg) {
    _otplessFlutterPlugin.startHeadless(callback, arg);
  }

  void setHeadlessCallback(OtplessResultCallback callback) {
    _otplessFlutterPlugin.setHeadlessCallback(callback);
  }

  // Add stubs for web-specific methods
  void initiateEmailAuth(Function callback, Map<String, dynamic> arg) {
    throw UnsupportedError('Email auth is only supported on web platform');
  }

  void initiatePhoneAuth(Function callback, Map<String, dynamic> arg) {
    throw UnsupportedError('Phone auth is only supported on web platform');
  }

  void headlessResponse(Function callback) {
    throw UnsupportedError(
      'Headless response is only supported on web platform',
    );
  }

  void initiateOAuth(Function callback, String provider) {
    throw UnsupportedError('OAuth is only supported on web platform');
  }
}
