import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillpe/core/config/env.dart';
import 'package:skillpe/services/base_url.dart';

class ApiService {
  static final String baseUrl = getBaseUrl();
  final Dio _dio = Dio();
  String? _authToken;

  // Simulate network delay
  static const int _simulatedDelay = 1000; // 1 second delay

  ApiService() {
    debugPrint('Base URL: $baseUrl');
    _dio.options.baseUrl = baseUrl;
    debugPrint('Env.apiUrl: ${Env.apiUrl}');
    debugPrint('baseUrl: $baseUrl');
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      "Access-Control-Allow-Origin": "*",
      'ngrok-skip-browser-warning': 'true',
    };
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('🚀 Making request to: ${options.uri}');
          debugPrint('Request data: ${options.data}');
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('📥 Response: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Error: ${error.message}');
          debugPrint('Error response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );

    // Add interceptor for logging
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          responseBody: true,
          error: true,
          requestHeader: true,
          responseHeader: true,
        ),
      );
    }
  }

  // Register method
  Future<Response> register(
    String token,
    UserCredential userCredential,
    String? referralCode,
  ) async {
    debugPrint('🚀 Making request to: ${Env.apiUrl}/auth/register');

    // Create a comprehensive map of UserCredential data
    final userCredentialMap = {
      // User specific data
      'user': {
        'uid': userCredential.user?.uid,
        'email': userCredential.user?.email,
        'emailVerified': userCredential.user?.emailVerified,
        'displayName': userCredential.user?.displayName,
        'phoneNumber': userCredential.user?.phoneNumber,
        'photoURL': userCredential.user?.photoURL,
        'isAnonymous': userCredential.user?.isAnonymous,
        'metadata': {
          'creationTime':
              userCredential.user?.metadata.creationTime?.toIso8601String(),
          'lastSignInTime':
              userCredential.user?.metadata.lastSignInTime?.toIso8601String(),
        },
        'providerData':
            userCredential.user?.providerData
                .map(
                  (userInfo) => {
                    'providerId': userInfo.providerId,
                    'uid': userInfo.uid,
                    'displayName': userInfo.displayName,
                    'email': userInfo.email,
                    'phoneNumber': userInfo.phoneNumber,
                    'photoURL': userInfo.photoURL,
                  },
                )
                .toList(),
      },
      // Additional credential information
      'credential':
          userCredential.credential != null
              ? {
                'providerId': userCredential.credential?.providerId,
                'signInMethod': userCredential.credential?.signInMethod,
                'token': userCredential.credential?.token,
              }
              : null,
      'additionalUserInfo':
          userCredential.additionalUserInfo != null
              ? {
                'isNewUser': userCredential.additionalUserInfo?.isNewUser,
                'providerId': userCredential.additionalUserInfo?.providerId,
                'username': userCredential.additionalUserInfo?.username,
                'profile': userCredential.additionalUserInfo?.profile,
              }
              : null,
    };

    final data = {
      'token': token,
      'userCredential': userCredentialMap,
      if (referralCode != null) 'referralCode': referralCode,
    };
    debugPrint('Request data: $data');

    final response = await _dio.post('/auth/register', data: data);

    return response;
  }

  // Login method
  Future<bool> login(String email, String password) async {
    try {
      debugPrint('🔑 Attempting login for email: $email');
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      debugPrint('📥 Login response: ${response.data}');

      if (response.statusCode == 200 && response.data['token'] != null) {
        _authToken = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _authToken!);
        debugPrint(
          '✅ Token saved to SharedPreferences: ${_authToken != null ? 'exists' : 'not found'}',
        );

        // Verify token was saved
        final savedToken = prefs.getString('auth_token');
        debugPrint(
          '✅ Verification - Token in SharedPreferences: ${savedToken != null ? 'exists' : 'not found'}',
        );

        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('❌ Login error: ${e.message}');
      debugPrint('Error response: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return false;
    }
  }

  // Initialize auth state
  Future<bool> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    if (_authToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_authToken';
    }
    return _authToken != null;
  }

  Future<Response<dynamic>> getUser({required String token}) async {
    try {
      final response = await _dio.get(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Store the token in memory and SharedPreferences
        _authToken = token;
        _dio.options.headers['Authorization'] = 'Bearer $token';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return response;
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    } on DioException catch (e) {
      debugPrint('❌ Get user error: ${e.message}');
      debugPrint('Error response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error in getUser: $e');
      rethrow;
    }
  }

  Future<Response<dynamic>> updateUser(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '/users/me',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response;
    } on DioException catch (e) {
      debugPrint('❌ Update user error: ${e.message}');
      debugPrint('Error response: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionToken = prefs.getString('auth_token');
    final response = await _dio.post(
      '/users/logout',
      data: {'sessionToken': sessionToken},
    );
    if (response.statusCode == 200) {
      await prefs.remove('auth_token');
    }
  }

  // Get spiral path data
  static Future<Map<String, dynamic>> getSpiralPathData() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: _simulatedDelay));

    // Return mock data
    return {
      "currentLevel": 5,
      "totalLevels": 10,
      "description":
          "Explore the captivating world of video descriptions, where every frame tells a story.",
      "levels": [
        for (int i = 1; i <= 10; i++)
          {
            "level": i,
            "description":
                "Explore the captivating world of video descriptions, where every frame tells a story.",
            "isCompleted": i <= 5,
            "isCurrent": i == 5,
            "position": i % 2 == 1 ? "LEFT" : "RIGHT",
            "contentType": i % 3 == 0 ? "QUIZ" : "VIDEO",
          },
      ],
    };
  }

  // Get quiz data for a specific level
  static Future<Map<String, dynamic>> getQuizData(int level) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: _simulatedDelay));

    // Default questions if level-specific questions are not available
    final Map<String, dynamic> defaultQuizData = {
      "title": "Product Design Quiz",
      "subtitle": "Test your knowledge",
      "questions": [
        {
          "question": "How much minimum font size we can give in a website?",
          "answers": ["8 px", "12 px", "10 px", "16 px"],
          "correctAnswerIndex": 1,
          "type": "mcq",
        },
        {
          "question": "What's your product design comfort level?",
          "answers": [
            "I'm Beginner",
            "I'm Intermediate",
            "I'm Advanced",
            "I'm Expert",
          ],
          "correctAnswerIndex": 1,
          "type": "poll",
          "voteCount": [35, 45, 15, 5],
        },
        {
          "question":
              "Explain how you would approach designing a mobile app for elderly users. What special considerations would you take into account?",
          "answers": [], // Empty for input type
          "type": "input",
          "sampleAnswer":
              "When designing for elderly users, I would focus on larger text sizes (at least 16px), high contrast colors, simple navigation with clear labels, minimal gestures required, and provide feedback for all interactions. I would also ensure buttons are large enough to tap easily and use familiar metaphors. Testing with the target demographic would be essential to validate usability.",
        },
        {
          "question": "Which color has the highest contrast with white?",
          "answers": ["Light Gray", "Yellow", "Black", "Light Blue"],
          "correctAnswerIndex": 2,
          "type": "mcq",
        },
        {
          "question": "What does UI stand for?",
          "answers": [
            "User Interface",
            "User Interaction",
            "User Information",
            "User Implementation",
          ],
          "correctAnswerIndex": 0,
          "type": "mcq",
        },
        {
          "question": "Which design software do you prefer?",
          "answers": ["Figma", "Sketch", "Adobe XD", "InVision"],
          "type": "poll",
          "voteCount": [45, 30, 15, 10],
        },
        {
          "question":
              "Describe a situation where you had to make a design compromise due to technical constraints. How did you handle it?",
          "answers": [], // Empty for input type
          "type": "input",
          "sampleAnswer":
              "On a recent project, I designed an animated transition between screens that the development team said would be too resource-intensive on older devices. Instead of insisting on the complex animation, I collaborated with the developers to create a simpler version that maintained the core user experience while meeting performance requirements. This taught me the importance of balancing design ideals with technical feasibility.",
        },
        {
          "question": "What do you find most challenging in UI design?",
          "answers": [
            "Color selection",
            "Typography",
            "Layout composition",
            "User flows",
          ],
          "type": "poll",
          "voteCount": [22, 18, 40, 35],
        },
        {
          "question": "Which mobile platform do you prioritize in design?",
          "answers": [
            "iOS first",
            "Android first",
            "Both equally",
            "Web-first approach",
          ],
          "type": "poll",
          "voteCount": [33, 25, 30, 12],
        },
      ],
    };

    // Level-specific questions
    if (level == 1) {
      return {
        "title": "Level 1 Quiz",
        "subtitle": "Product Design Basics",
        "questions": [
          {
            "question": "What is responsive design?",
            "answers": [
              "Design that responds to user clicks",
              "Design that works across different screen sizes",
              "Design with fast loading times",
              "Design with animations",
            ],
            "correctAnswerIndex": 1,
            "type": "mcq",
          },
          {
            "question": "What aspect of UX is most important to you?",
            "answers": [
              "Usability",
              "Visual appeal",
              "Performance",
              "Accessibility",
            ],
            "type": "poll",
            "voteCount": [40, 25, 15, 20],
          },
          {
            "question":
                "Explain the difference between UX and UI design in your own words.",
            "answers": [], // Empty for input type
            "type": "input",
            "sampleAnswer":
                "UI (User Interface) design focuses on the visual elements of a product, including layout, colors, typography, and interactive elements that users directly interact with. UX (User Experience) design is broader and encompasses the entire journey and experience a user has with a product, including ease of use, accessibility, and how it makes users feel. While UI is about how a product looks, UX is about how it works and how users interact with it.",
          },
        ],
      };
    } else if (level == 3) {
      return {
        "title": "Level 3 Quiz",
        "subtitle": "Advanced Design Concepts",
        "questions": [
          {
            "question": "Which design principle emphasizes visual hierarchy?",
            "answers": ["Proximity", "Contrast", "Repetition", "Alignment"],
            "correctAnswerIndex": 1,
            "type": "mcq",
          },
          {
            "question": "How often do you conduct user testing?",
            "answers": ["Every sprint", "Monthly", "Quarterly", "Rarely"],
            "type": "poll",
            "voteCount": [15, 35, 28, 22],
          },
          {
            "question":
                "Describe your approach to designing a component system or design system. What key elements would you include?",
            "answers": [], // Empty for input type
            "type": "input",
            "sampleAnswer":
                "When designing a component system, I start by auditing existing UI elements to identify patterns. I then establish core design tokens (colors, typography, spacing) and create base components that are versatile and composable. Documentation is crucial - I ensure each component has clear usage guidelines, code examples, and accessibility considerations. I also implement a version control strategy and governance process for updates. The system should balance consistency with flexibility to meet diverse product needs while maintaining a unified experience.",
          },
        ],
      };
    }

    return defaultQuizData;
  }

  // Add method to get latest token
  String? getLatestToken() {
    return _authToken;
  }

  // Modify your request headers to always get fresh token
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'ngrok-skip-browser-warning': 'true',
    if (getLatestToken() != null) 'Authorization': 'Bearer ${getLatestToken()}',
  };
}
