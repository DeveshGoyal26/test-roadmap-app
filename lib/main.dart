import 'package:skillpe/pages/privacy_policy_page.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skillpe/pages/payment_page.dart';
import 'package:provider/provider.dart';
import 'pages/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_guard.dart';
import 'pages/video_player_page.dart';
import 'pages/roadmaps_page.dart';
import 'pages/quiz_page.dart';
import 'pages/category_page.dart';
import 'pages/terms_and_conditions_page.dart';
import 'pages/completed_roadmap_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Preserve the native splash screen until the app is fully loaded
  if (!kIsWeb) {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Force the status bar to update
  if (UniversalPlatform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  runApp(MyApp(themeProvider: themeProvider));
}

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Center(child: Text('404!')));
  }
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Update system UI overlay style when theme changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SystemChrome.setSystemUIOverlayStyle(
              themeProvider.isDarkMode
                  ? AppTheme.darkStatusBar
                  : AppTheme.lightStatusBar,
            );
          });

          return MaterialApp(
            title: 'Skillpe',
            debugShowCheckedModeBanner: false,
            theme:
                themeProvider.isDarkMode
                    ? AppTheme.darkTheme
                    : AppTheme.lightTheme,
            builder: (context, child) {
              return ColoredBox(
                color:
                    themeProvider.isDarkMode
                        ? Colors.black
                        : Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          UniversalPlatform.isWeb
                              ? 450
                              : MediaQuery.of(context).size.width,
                    ),
                    child: child!,
                  ),
                ),
              );
            },
            onGenerateRoute: (settings) {
              // Handle '/'
              if (settings.name == '/') {
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
              }

              // Handle '/roadmaps/:id'
              var uri = Uri.parse(settings.name ?? '');
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments.first == 'roadmaps') {
                var id = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder:
                      (context) => AuthGuard(
                        requireAuth: true,
                        child: RoadmapsPage(courseId: id as String?),
                      ),
                );
              }

              // Handle '/privacy-policy'
              if (settings.name == '/privacy-policy') {
                return MaterialPageRoute(
                  builder:
                      (context) => AuthGuard(
                        requireAuth: true,
                        child: const PrivacyPolicyPage(),
                      ),
                );
              }

              // Handle '/terms-and-conditions'
              if (settings.name == '/terms-and-conditions') {
                return MaterialPageRoute(
                  builder:
                      (context) => AuthGuard(
                        requireAuth: true,
                        child: const TermsAndConditionsPage(),
                      ),
                );
              }

              // // Handle '/login'
              // if (settings.name == '/login') {
              //   return MaterialPageRoute(
              //     builder: (context) => AuthGuard(
              //       requireAuth: false,
              //       child: const LoginPage(),
              //     ),
              //   );
              // }

              // // Handle '/home'
              // if (settings.name == '/home') {
              //   return MaterialPageRoute(
              //     builder:
              //         (context) => AuthGuard(
              //           requireAuth: true,
              //           child: const MainScreen(),
              //         ),
              //   );
              // }

              // Handle '/category/:id'
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments.first == 'category') {
                var id = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder:
                      (context) => AuthGuard(
                        requireAuth: true,
                        child: CategoryPage(id: id),
                      ),
                );
              }

              // Handle '/payment'
              if (settings.name == '/payment') {
                return MaterialPageRoute(
                  builder:
                      (context) => AuthGuard(
                        requireAuth: true,
                        child: const PaymentPage(),
                      ),
                );
              }

              // Handle '/video'
              if (settings.name == '/video') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder:
                      (context) => AuthGuard(
                        requireAuth: true,
                        child: VideoPlayerPage(
                          title: args?['title'] as String? ?? 'Video',
                          level: args?['level'] as int? ?? 1,
                          description: args?['description'] as String? ?? '',
                          videoUrl: args?['videoUrl'] as String?,
                          contentId: args?['contentId'] as String?,
                          roadmapId: args?['roadmapId'] as String?,
                          courseId: args?['courseId'] as String?,
                          onAction: args?['onAction'] as Function()?,
                        ),
                      ),
                );
              }

              // Handle '/quiz'
              if (settings.name == '/quiz') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder:
                      (context) => AuthGuard(
                        requireAuth: true,
                        child:
                            args != null
                                ? QuizPage.fromRouteArguments(args)
                                : const QuizPage(),
                      ),
                );
              }

              // Handle '/completed-roadmap'
              if (settings.name == '/completed-roadmap') {
                return MaterialPageRoute(
                  builder:
                      (context) => AuthGuard(
                        requireAuth: true,
                        child: const CompletedRoadmapPage(),
                      ),
                );
              }

              return MaterialPageRoute(builder: (context) => UnknownScreen());
            },
          );
        },
      ),
    );
  }
}
