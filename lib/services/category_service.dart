import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:skillpe/core/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillpe/services/base_url.dart';

class CategoryService {
  static final String baseUrl = getBaseUrl();

  final Dio _dio = Dio();
  String? _authToken;

  CategoryService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
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
          debugPrint('🚀 Making category request to: ${options.uri}');

          // Get token from shared preferences if not already set
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
          debugPrint('📥 Category response: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Category error: ${error.message}');
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
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('/category/all');
      if (response.statusCode == 200) {
        return response.data['categories'];
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch categories',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching categories: $e');
      rethrow; // Rethrow to handle in the UI
    }
  }

  Future<dynamic> getCategoryById(String id) async {
    try {
      final response = await _dio.get('/category/$id');
      return response.data;
    } catch (e) {
      debugPrint('❌ Error: $e');
      return null;
    }
  }
}
