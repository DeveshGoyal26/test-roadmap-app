import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env.dev', obfuscate: true)
abstract class DevEnv {
  @EnviedField(varName: 'API_URL')
  static String apiUrl = _DevEnv.apiUrl;
}

@Envied(path: '.env.prod', obfuscate: true)
abstract class ProdEnv {
  @EnviedField(varName: 'API_URL')
  static String apiUrl = _ProdEnv.apiUrl;
}

class Env {
  static String get apiUrl {
    const environment = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'dev',
    );
    return environment == 'prod' ? ProdEnv.apiUrl : DevEnv.apiUrl;
  }
}
