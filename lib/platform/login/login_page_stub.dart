// apps/flutter_app/lib/platform/login/login_page_stub.dart
class OtplessImplementation {
  dynamic get instance =>
      throw UnsupportedError(
        'Cannot create OTPless instance without dart:html or dart:io',
      );

  void initOtplessHeadless(String clientId) =>
      throw UnsupportedError('Cannot use OTPless without dart:html or dart:io');

  void initHeadless(String clientId) =>
      throw UnsupportedError('Cannot use OTPless without dart:html or dart:io');

  void startHeadless(Function callback, Map<String, dynamic> arg) =>
      throw UnsupportedError('Cannot use OTPless without dart:html or dart:io');

  void setHeadlessCallback(Function callback) =>
      throw UnsupportedError('Cannot use OTPless without dart:html or dart:io');

  void initiateEmailAuth(Function callback, Map<String, dynamic> arg) =>
      throw UnsupportedError('Cannot use OTPless without dart:html or dart:io');

  void initiatePhoneAuth(Function callback, Map<String, dynamic> arg) =>
      throw UnsupportedError('Cannot use OTPless without dart:html or dart:io');

  void headlessResponse(Function callback) =>
      throw UnsupportedError('Cannot use OTPless without dart:html or dart:io');

  void initiateOAuth(Function callback, String provider) =>
      throw UnsupportedError('Cannot use OTPless without dart:html or dart:io');
}
