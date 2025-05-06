// apps/flutter_app/lib/platform/login/login_page_web.dart
import 'package:otpless_flutter_web/otpless_flutter_web.dart' as otpless_web;

class OtplessImplementation {
  final _otplessWebPlugin = otpless_web.Otpless();

  dynamic get instance => _otplessWebPlugin;

  // Web-specific methods
  void initiateEmailAuth(
    otpless_web.OtplessResultCallback callback,
    Map<String, dynamic> arg,
  ) {
    _otplessWebPlugin.initiateEmailAuth(callback, arg);
  }

  void initiatePhoneAuth(
    otpless_web.OtplessResultCallback callback,
    Map<String, dynamic> arg,
  ) {
    _otplessWebPlugin.initiatePhoneAuth(callback, arg);
  }

  void headlessResponse(otpless_web.OtplessResultCallback callback) {
    _otplessWebPlugin.headlessResponse(callback);
  }

  void initiateOAuth(
    otpless_web.OtplessResultCallback callback,
    String provider,
  ) {
    _otplessWebPlugin.initiateOAuth(callback, provider);
  }

  // Mobile-specific methods implemented as no-ops for web
  void initOtplessHeadless(String clientId) {
    // No-op on web as it's not needed
  }

  void setHeadlessCallback(Function callback) {
    // No-op on web
  }

  void startHeadless(Function callback, Map<String, dynamic> arg) {
    // On web, we'll redirect to the appropriate auth method based on the args
    if (arg.containsKey('channelType')) {
      initiateOAuth(
        callback as otpless_web.OtplessResultCallback,
        arg['channelType'],
      );
    } else if (arg.containsKey('email')) {
      initiateEmailAuth(callback as otpless_web.OtplessResultCallback, arg);
    } else if (arg.containsKey('phone')) {
      initiatePhoneAuth(callback as otpless_web.OtplessResultCallback, arg);
    }
  }
}
