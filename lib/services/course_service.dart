import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillpe/services/base_url.dart';

class CourseService {
  static final String baseUrl = getBaseUrl();
  final Dio _dio = Dio();
  String? _authToken;

  CourseService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _dio.options.baseUrl = baseUrl;
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
          debugPrint('🚀 Making course request to: ${options.uri}');

          // Get token from shared preferences
          if (_authToken == null) {
            final prefs = await SharedPreferences.getInstance();
            _authToken = prefs.getString('auth_token');
          }

          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('📥 Course response: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Course error: ${error.message}');
          debugPrint('Error response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );

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

  // Fetch course details by ID
  Future<Map<String, dynamic>> getCourseDetails(String courseId) async {
    try {
      final response = await _dio.get('/courses/$courseId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch course details: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching course details: $e');
      throw Exception('Error fetching course details: $e');
    }
  }

  // Fetch user progress for a course
  Future<Map<String, dynamic>> getUserProgress(String courseId) async {
    try {
      final String endpoint = '/application/progress?courseId=$courseId';

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch course progress: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching course progress: $e');
      // Return mock data or rethrow based on requirements
      throw Exception('Error fetching course progress: $e');
    }
  }

  // Get all available courses
  Future<Map<String, dynamic>> getAllCourses() async {
    try {
      final response = await _dio.get('/courses');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch courses: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching courses: $e');
      // Return mock data or rethrow based on requirements
      throw Exception('Error fetching courses: $e');
    }
  }

  // Update progress for a course
  Future<Map<String, dynamic>> updateProgress(
    String courseId,
    String contentId,
  ) async {
    try {
      final response = await _dio.post(
        '/courses/$courseId/progress',
        data: {'contentId': contentId},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update progress: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error updating progress: $e');
      // Return mock data or rethrow based on requirements
      throw Exception('Error updating progress: $e');
    }
  }

  // Get coming soon courses
  Future<Map<String, dynamic>> getComingSoonCourses() async {
    try {
      final response = await _dio.get('/courses/coming-soon');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch coming soon courses: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching coming soon courses: $e');
      throw Exception('Error fetching coming soon courses: $e');
    }
  }

  // Get trending courses
  Future<Map<String, dynamic>> getTrendingCourses() async {
    try {
      final response = await _dio.get('/courses/trending');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch trending courses: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching trending courses: $e');
      throw Exception('Error fetching trending courses: $e');
    }
  }

  // Get in progress courses
  Future<Map<String, dynamic>> getInProgressCourses() async {
    try {
      final response = await _dio.get('/application/in-progress');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch in progress courses: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching in progress courses: $e');
      throw Exception('Error fetching in progress courses: $e');
    }
  }
}
