import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillpe/services/base_url.dart';

class RoadmapService {
  static final String baseUrl = getBaseUrl();
  final Dio _dio = Dio();
  String? _authToken;

  RoadmapService() {
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

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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
      ),
    );
  }

  // Fetch course details by ID
  Future<Map<String, dynamic>> getCourseDetails(String courseId) async {
    try {
      final response = await _dio.get('/courses/$courseId');
      if (response.statusCode == 200) {
        debugPrint('Course details recieved: ${response.data}');
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch course details: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching course details: $e');
      throw Exception('Error fetching course details: $e');
    }
  }

  // Fetch user progress for a course
  Future<Map<String, dynamic>> getUserProgress(String courseId) async {
    try {
      final String endpoint = '/application/progress?courseId=$courseId';
      final response = await _dio.get(endpoint);
      if (response.statusCode == 200) {
        debugPrint('Course progress recieved: ${response.data}');
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch course progress: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching course progress: $e');
      throw Exception('Error fetching course progress: $e');
    }
  }
}
