import 'dart:convert';
import 'package:universal_platform/universal_platform.dart';
import 'package:skillpe/providers/theme_provider.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:skillpe/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';
import '../platform/login/otpless.dart';
import 'package:skillpe/providers/auth_provider.dart' as user_auth_provider;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _otplessPlugin = OtplessImplementation();

  String responseData = "null";
  bool isWhatsAppInstalled = true;

  // Email regex pattern
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  // Phone regex pattern (supports international format)
  final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');

  @override
  void initState() {
    super.initState();
    // if (UniversalPlatform.isWeb) {
    //   _otplessPlugin.headlessResponse(onHeadlessWebResult);
    // } else {
    //   _otplessPlugin.initOtplessHeadless("vl8fm4e97scpxrgpo9hi");
    //   _otplessPlugin.setHeadlessCallback(onHeadlessResult);
    // }
  }

  void onHeadlessWebResult(result) async {
    // Parse the result JSON string into a Map
    Map<String, dynamic> parsedResult = jsonDecode(result);

    switch (parsedResult['responseType'] as String) {
      case "INITIATE":
        {
          debugPrint("INITIATE  ${parsedResult["response"]}");
          responseData = parsedResult.toString();
          setState(() {});
          break;
        }
      case "FALLBACK_TRIGGERED":
        {
          debugPrint("FALLBACK_TRIGGERED  ${parsedResult["response"]}");
          responseData = parsedResult.toString();
          setState(() {});
          break;
        }

      case "VERIFY":
        {
          debugPrint("VERIFY  ${parsedResult["response"]}");
          responseData = parsedResult.toString();
          setState(() {});
          break;
        }

      case 'ONETAP':
        {
          debugPrint("ONETAP  ${parsedResult["response"]}");
          debugPrint("Token  ${parsedResult["response"]["token"]}");
          final token = parsedResult["response"]["token"];
          final idToken = parsedResult["response"]["idToken"];
          final identities = parsedResult["response"]["identities"];
          logger.d('idToken: $idToken');
          logger.d('token: $token');
          // Decode the JWT token

          // final authProvider = Provider.of<AuthProvider>(
          //   context,
          //   listen: false,
          // );

          // final sessionToken = await authProvider.register(
          //   token,
          //   idToken,
          //   identities,
          // );
          // logger.d('response: $sessionToken');

          // if (sessionToken.isEmpty) {
          //   logger.e("Authentication failed, token: $sessionToken");
          //   return;
          // }

          // authProvider.setToken(sessionToken);
          // logger.d("Authentication successful, token: $sessionToken");
          // authProvider.getUser();
          // if (mounted) {
          //   Navigator.of(context).pushReplacementNamed('/');
          // }

          // responseData = parsedResult.toString();
          // setState(() {});
          // break;
        }
    }
  }

  void onHeadlessResult(dynamic result) async {
    logger.d(result);
    if (result['statusCode'] == 200) {
      switch (result['responseType'] as String) {
        case 'INITIATE':
          logger.d("Authentication initiated");
          break;
        case 'VERIFY':
          logger.d("Verification completed");
          break;
        case 'OTP_AUTO_READ':
          if (UniversalPlatform.isAndroid) {
            var otp = result['response']['otp'] as String;
            logger.d("OTP received: $otp");
          }
          break;
        case 'ONETAP':
          if (mounted) {
            Navigator.pop(context);
          }
          final token = result["response"]['token'];
          final idToken = result["response"]['idToken'];
          final identities = result["response"]['identities'];
          logger.d('idToken: $idToken');
          logger.d('token: $token');
        // Decode the JWT token

        // final authProvider = Provider.of<AuthProvider>(
        //   context,
        //   listen: false,
        // );

        // final sessionToken = await authProvider.register(
        //   token,
        //   idToken,
        //   identities,
        // );
        // logger.d('response: $sessionToken');

        // if (sessionToken.isEmpty) {
        //   logger.e("Authentication failed, token: $sessionToken");
        //   return;
        // }

        // authProvider.setToken(sessionToken);
        // logger.d("Authentication successful, token: $sessionToken");
        // authProvider.getUser();
        // if (mounted) {
        //   Navigator.of(context).pushReplacementNamed('/');
        // }
        // break;
      }
    } else {
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.show(
          context: context,
          message: '${result['response']['errorMessage'] ?? 'Unknown error'}',
        );
      }
    }
  }

  // Add this method to show the loading dialog
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Update the _login method
  Future<void> _login() async {
    try {
      if (_formKey.currentState!.validate()) {
        _showLoadingDialog(context, 'Authenticating...');

        Map<String, dynamic> arg = {};

        if (_emailPhoneController.text.contains('@') &&
            emailRegex.hasMatch(_emailPhoneController.text)) {
          arg["email"] = _emailPhoneController.text;
        } else if (_emailPhoneController.text.length == 10 &&
            phoneRegex.hasMatch(_emailPhoneController.text)) {
          arg["phone"] = _emailPhoneController.text;
          arg["countryCode"] = "+91";
        } else {
          Navigator.pop(context);
          CustomSnackBar.show(
            context: context,
            message: 'Please enter a valid email or phone number',
          );
          return;
        }

        final authProvider = Provider.of<user_auth_provider.AuthProvider>(
          context,
          listen: false,
        );

        // if (kIsWeb) {
        //   if (emailRegex.hasMatch(_emailPhoneController.text)) {
        //     _otplessPlugin.initiateEmailAuth(onHeadlessWebResult, arg);
        //   } else {
        //     _otplessPlugin.initiatePhoneAuth(onHeadlessWebResult, arg);
        //   }
        // } else {
        //   _otplessPlugin.startHeadless(onHeadlessResult, arg);
        // }

        if (emailRegex.hasMatch(_emailPhoneController.text)) {
          authProvider.signInWithEmail(_emailPhoneController.text);
        } else {
          // TODO: Implement phone login
        }
      }
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  // Update the startHeadlessWithSocialLogin method
  Future<void> startHeadlessWithSocialLogin(String loginType) async {
    logger.d('loginType: $loginType');
    if (loginType == 'WHATSAPP' && !isWhatsAppInstalled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please install WhatsApp")),
        );
      }
      return;
    }

    _showLoadingDialog(
      context,
      'Authenticating with ${loginType.toLowerCase()}...',
    );

    Map<String, dynamic> arg = {'channelType': loginType};
    if (UniversalPlatform.isWeb) {
      _otplessPlugin.initiateOAuth(onHeadlessWebResult, loginType);
    } else {
      _otplessPlugin.startHeadless(onHeadlessResult, arg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final authProvider = Provider.of<user_auth_provider.AuthProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      body: Stack(
        alignment: isSmallScreen ? Alignment.bottomCenter : Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  themeProvider.isDarkMode
                      ? 'assets/images/bg-dark.png'
                      : 'assets/images/bg-dark.png',
                ),
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          SizedBox(
            width: isSmallScreen ? double.infinity : 500,
            child: SingleChildScrollView(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 32.0,
                  vertical:
                      isSmallScreen
                          ? isKeyboardVisible
                              ? 0
                              : 30.0
                          : 16.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? double.infinity : 500,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo and Text Section
                        AnimatedContainer(
                          margin: EdgeInsets.only(
                            bottom:
                                isKeyboardVisible
                                    ? 50
                                    : isSmallScreen
                                    ? 100
                                    : 150,
                          ),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                alignment: Alignment.center,
                                width:
                                    isKeyboardVisible
                                        ? 160
                                        : isSmallScreen
                                        ? 180
                                        : 222,
                                child: Image.asset(
                                  themeProvider.isDarkMode
                                      ? 'assets/logos/skillpe-logo-dark.png'
                                      : 'assets/logos/skillpe-logo-light.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Learn Faster Earn Faster',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  fontSize: isSmallScreen ? 16 : 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                        TextFormField(
                          controller: _emailPhoneController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email or Phone',
                            hintText: 'Enter your email or phone number',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email or phone number';
                            }

                            if (!emailRegex.hasMatch(value) &&
                                !phoneRegex.hasMatch(value)) {
                              return 'Please enter a valid email or phone number';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: authProvider.isAuthenticating ? null : _login,
                          style: FilledButton.styleFrom(
                            minimumSize: Size.fromHeight(
                              isSmallScreen ? 45 : 50,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                          ),
                          child:
                              authProvider.isAuthenticating
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    'Start Learning',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Expanded(child: Divider(thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    authProvider.isAuthenticating
                                        ? null
                                        : () async {
                                          try {
                                            final result =
                                                await authProvider
                                                    .signInWithGoogle();
                                            if (result != null) {
                                              // Success - AuthGuard will handle navigation
                                              if (mounted) {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // Remove loading dialog
                                              }
                                            } else {
                                              // Failed to sign in
                                              if (mounted) {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // Remove loading dialog
                                                CustomSnackBar.show(
                                                  context: context,
                                                  message:
                                                      'Failed to sign in with Google. Please try again.',
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              Navigator.of(
                                                context,
                                              ).pop(); // Remove loading dialog
                                              CustomSnackBar.show(
                                                context: context,
                                                message:
                                                    'Failed to sign in with Google: ${e.toString()}',
                                              );
                                            }
                                          }
                                        },
                                icon:
                                    authProvider.isAuthenticating
                                        ? SizedBox(
                                          width: isSmallScreen ? 16 : 18,
                                          height: isSmallScreen ? 16 : 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  themeProvider.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                          ),
                                        )
                                        : Image.asset(
                                          'assets/icons/google-icon.png',
                                          width: isSmallScreen ? 16 : 18,
                                          height: isSmallScreen ? 16 : 18,
                                        ),
                                label: Text(
                                  authProvider.isAuthenticating
                                      ? 'Signing in...'
                                      : 'Google',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      themeProvider.isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                  foregroundColor:
                                      themeProvider.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 10 : 12,
                                  ),
                                  minimumSize: Size.fromHeight(
                                    isSmallScreen ? 45 : 50,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                    side: BorderSide(
                                      color:
                                          themeProvider.isDarkMode
                                              ? const Color(0xFF666666)
                                              : const Color.fromARGB(
                                                255,
                                                220,
                                                221,
                                                221,
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
