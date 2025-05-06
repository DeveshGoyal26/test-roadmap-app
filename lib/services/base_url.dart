import 'package:skillpe/core/config/env.dart';

String getBaseUrl() {
  return Env.apiUrl.isNotEmpty
      ? Env.apiUrl
      : 'https://511a-203-92-57-226.ngrok-free.app';
}
