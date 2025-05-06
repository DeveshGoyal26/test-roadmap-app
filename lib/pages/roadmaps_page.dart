import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skillpe/services/base_url.dart';
import '../services/roadmap_service.dart';
import '../components/header_component.dart';
import '../components/progress_slider_component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/zig_zag_path_with_icons.dart';

class RoadmapsPage extends StatefulWidget {
  final String? courseId;

  const RoadmapsPage({super.key, this.courseId});

  @override
  State<RoadmapsPage> createState() => _RoadmapsPageState();
}

class _RoadmapsPageState extends State<RoadmapsPage> {
  final RoadmapService _roadmapService = RoadmapService();
  String baseUrl = getBaseUrl();
  String? _authToken;
  bool isLoading = true;
  int completedRoadmaps = 0;
  int totalRoadmaps = 0;
  String courseTitle = "Course Roadmaps";
  String userPaymentStatus = "free"; // Default as free

  // Store the segments and progress data
  List<dynamic> segments = [];
  Map<String, dynamic> progressData = {};

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  // Load auth token from SharedPreferences
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get the course ID from params
      final String? courseId = widget.courseId;

      if (courseId == null) {
        debugPrint('Error: No courseId provided');
        setState(() {
          isLoading = false;
        });
        return;
      }

      debugPrint('Fetching data for courseId: $courseId');

      // Fetch course details
      final courseResponse = await _roadmapService.getCourseDetails(courseId);
      debugPrint('Course API response success: ${courseResponse['success']}');

      // Fetch progress data
      final progressResponse = await _roadmapService.getUserProgress(courseId);

      // Extract basic info for UI
      if (courseResponse['success'] == true) {
        // Get course title
        if (courseResponse['course'] != null &&
            courseResponse['course']['title'] != null) {
          courseTitle = courseResponse['course']['title'];
          debugPrint('Course title: $courseTitle');
        }

        // Get user payment status
        if (courseResponse['userPaymentStatus'] != null) {
          userPaymentStatus = courseResponse['userPaymentStatus'];
          debugPrint('User payment status: $userPaymentStatus');
        }

        // Get segments
        if (courseResponse['segments'] != null) {
          segments = courseResponse['segments'] as List;
          totalRoadmaps = segments.length;
          debugPrint('Segments found: ${segments.length}');
          // Debug the first segment to verify structure
          if (segments.isNotEmpty) {
            debugPrint('First segment title: ${segments[0]['title']}');
            debugPrint(
              'First segment content count: ${(segments[0]['content'] as List?)?.length ?? 0}',
            );
          }
        } else {
          debugPrint('No segments found in the response!');
          segments = [];
        }
      } else {
        // Handle error case
        debugPrint('Course API response failed');
        segments = [];
      }

      if (progressResponse['success'] == true &&
          progressResponse['progress'] != null) {
        // Store progress data
        progressData = progressResponse['progress'];

        // Get completed roadmaps count
        completedRoadmaps = progressData['completedRoadmapCount'] ?? 0;
        debugPrint('Completed roadmaps: $completedRoadmaps');
      } else {
        // Handle error case
        debugPrint('Progress API response failed');
        progressData = {};
        completedRoadmaps = 0;
      }

      setState(() {
        isLoading = false;
      });

      // Verify state after update
      debugPrint(
        'After setState - segments length: ${segments.length}, isLoading: $isLoading',
      );
    } catch (e) {
      debugPrint('Error in _fetchData: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update progress after watching a video
  Future<void> updateProgress(
    String contentId,
    String roadmapId,
    String courseId,
  ) async {
    debugPrint('========== UPDATE VIDEO PROGRESS ==========');
    debugPrint('ContentId: $contentId');
    debugPrint('RoadmapId: $roadmapId');
    debugPrint('CourseId: $courseId');

    // Get auth token if not already loaded
    if (_authToken == null) {
      debugPrint('Auth token not loaded, loading now...');
      try {
        final prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString('auth_token');
        debugPrint(
          'Auth token retrieved: ${_authToken != null ? 'Successfully' : 'Failed'}',
        );
      } catch (e) {
        debugPrint('Error retrieving auth token: $e');
      }
    }

    if (_authToken == null) {
      debugPrint('Error: Auth token is still missing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required. Please login again.'),
        ),
      );
      return;
    }

    try {
      // Prepare request payload
      final Map<String, dynamic> payload = {
        'contentId': contentId,
        'roadmapId': roadmapId,
        'courseId': courseId,
      };

      debugPrint('Sending progress update with payload: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/application/update-progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(payload),
      );

      debugPrint('Progress update response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('Progress update success: $data');

        // Check if this is the last content of the last roadmap
        bool isLastContent = isLastContentOfLastRoadmap(contentId, roadmapId);

        if (isLastContent) {
          debugPrint(
            'This is the last content of the last roadmap - completing course!',
          );
          // Navigate to completion page
          Navigator.pushNamed(
            context,
            '/completed-roadmap',
            arguments: {'courseTitle': courseTitle},
          );
        } else {
          // Refresh the data to show updated progress
          _fetchData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress updated successfully!')),
          );
        }
      } else if (response.statusCode == 401) {
        // Handle auth token expired case
        debugPrint(
          'Auth token expired or invalid. Status: ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );

        // Try to refresh the token if possible or navigate to login
        _refreshAuthToken();
      } else {
        debugPrint(
          'Error updating progress: ${response.statusCode} ${response.body}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update progress: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception updating progress: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    debugPrint('=====================================');
  }

  // Refresh auth token
  Future<void> _refreshAuthToken() async {
    try {
      // Attempt to refresh the auth token
      debugPrint('Attempting to refresh auth token');

      // Get current auth token
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');

      if (_authToken == null) {
        debugPrint('No existing token found to refresh');
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Here you would normally call your auth refresh API
      // For now, we'll just redirect to login if token is invalid
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      debugPrint('Error refreshing auth token: $e');
      // Navigate to login screen on error
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Check if a segment is completed
  bool isSegmentCompleted(String segmentId) {
    if (progressData['roadmapHistory'] == null) return false;

    final roadmapHistory = progressData['roadmapHistory'] as List;
    return roadmapHistory.any(
      (item) => item['roadmap'] != null && item['roadmap']['_id'] == segmentId,
    );
  }

  // Check if a content item is completed
  bool isContentCompleted(String contentId) {
    if (progressData['contentHistory'] == null) return false;

    final contentHistory = progressData['contentHistory'] as List;
    return contentHistory.any(
      (item) => item['content'] != null && item['content']['_id'] == contentId,
    );
  }

  // Check if the content is the last item of the last roadmap
  bool isLastContentOfLastRoadmap(String contentId, String roadmapId) {
    // If no segments, return false
    if (segments.isEmpty) return false;

    // Get the last segment/roadmap
    final lastSegment = segments.last;

    // If this is not the last roadmap, return false
    if (lastSegment['_id'] != roadmapId) return false;

    // Get the content items of the last roadmap
    final List<dynamic> segmentContent = lastSegment['content'] as List? ?? [];

    // If no content in the last roadmap, return false
    if (segmentContent.isEmpty) return false;

    // Get the last content item
    final lastContent = segmentContent.last;

    // Check if the given contentId is the ID of the last content
    return lastContent['_id'] == contentId;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate current value for progress slider
    int currentValue = completedRoadmaps;
    if (completedRoadmaps < totalRoadmaps) {
      currentValue = completedRoadmaps + 1;
    }

    debugPrint(
      'Building UI - segments: ${segments.length}, isLoading: $isLoading',
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: HeaderComponent(
          subtitle: "Learning Path",
          title: courseTitle,
          isLoading: isLoading,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header component with course title
            const SizedBox(height: 16),

            // Progress slider component
            if (!isLoading)
              ProgressSliderComponent(
                currentValue: currentValue,
                totalValue: totalRoadmaps > 0 ? totalRoadmaps : 1,
                isEnabled: false,
              ),

            // Divider line with shadow
            if (!isLoading)
              Container(
                margin: const EdgeInsets.only(top: 10),
                height: 1,
                width: double.infinity,
                decoration: BoxDecoration(
                  // color: Colors.white.withValues(alpha:0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.12),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),

            // Subscription message for non-paid users
            if (!isLoading && userPaymentStatus != 'paid')
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/payment');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                  child: const Text(
                    'Subscription required to access all content',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),

            // Main content
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : segments.isEmpty
                      ? _buildEmptyState()
                      : _buildSegmentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No content available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for updates',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchData, child: const Text('Refresh')),
        ],
      ),
    );
  }

  Widget _buildSegmentsList() {
    debugPrint('Building segments list with ${segments.length} segments');

    // Find the next content item that should be accessible for paid users
    String? nextContentId;
    if (userPaymentStatus == 'paid' && progressData['contentHistory'] != null) {
      final contentHistory = progressData['contentHistory'] as List;

      // Extract completed content IDs
      final completedContentIds =
          contentHistory
              .where(
                (item) =>
                    item['content'] != null && item['content']['_id'] != null,
              )
              .map<String>((item) => item['content']['_id'])
              .toList();

      // Find the first non-completed content in segments order
      outerLoop:
      for (var segment in segments) {
        if (segment['content'] == null) continue;

        final List<dynamic> segmentContent = segment['content'] as List;
        for (var content in segmentContent) {
          final String contentId = content['_id'];
          if (!completedContentIds.contains(contentId)) {
            nextContentId = contentId;
            break outerLoop;
          }
        }
      }

      debugPrint('Next content ID to complete: $nextContentId');
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: segments.length,
        itemBuilder: (context, index) {
          final segment = segments[index];
          final segmentId = segment['_id'];
          final segmentTitle = segment['title'] ?? 'Untitled Segment';
          final segmentContent = segment['content'] as List? ?? [];

          // Get the color from meta
          String colorTheme = 'voilet'; // Default color theme
          if (segment['meta'] != null && segment['meta']['color'] != null) {
            colorTheme = segment['meta']['color'].toString();
          }

          // Define background color based on colorTheme
          Color backgroundColor;
          switch (colorTheme) {
            case 'green':
              backgroundColor = const Color(0xFFF2FFFA); // #F2FFFA
              break;
            case 'orange':
              backgroundColor = const Color(0xFFFCECE8); // #FCECE8
              break;
            case 'yellow':
              backgroundColor = const Color(0xFFFEF8D5); // #FEF8D5
              break;
            case 'voilet':
            default:
              backgroundColor = const Color(0xFFFAF5FF); // #FAF5FF
              break;
          }

          debugPrint(
            'Building segment $index: $segmentTitle with ${segmentContent.length} content items, color: $colorTheme',
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segment header with line-title-line design
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[300], thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        segmentTitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[300], thickness: 1),
                    ),
                  ],
                ),
              ),

              // Segment content with color-themed background
              if (segmentContent.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ZigZagPathWithIcons(
                      contentItems: segmentContent,
                      segmentId: segmentId,
                      colorTheme: colorTheme,
                      isFirstSegment: index == 0,
                      nextContentId: nextContentId,
                      onContentTap: _handleContentTap,
                      userPaymentStatus: userPaymentStatus,
                      progressData: progressData,
                      onPaymentNavigate: () {
                        Navigator.pushNamed(context, '/payment');
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleContentTap(dynamic content, String segmentId) {
    final contentId = content['_id'];
    final contentType = content['type'] ?? '';
    final courseId = widget.courseId;

    if (courseId == null) {
      debugPrint('Error: No courseId available');
      return;
    }

    // Log the IDs for debugging/tracking
    debugPrint('=== CONTENT CLICKED ===');
    debugPrint('courseId: $courseId');
    debugPrint('roadmapId (segmentId): $segmentId');
    debugPrint('contentId: $contentId');

    // Log videoUrl for video content
    if (contentType.toLowerCase() == 'video' && content['videoUrl'] != null) {
      debugPrint('videoUrl: ${content['videoUrl']}');

      // Check if this is the last content
      bool isLastContent = isLastContentOfLastRoadmap(contentId, segmentId);
      debugPrint('Is last content of last roadmap: $isLastContent');

      // Navigate to video player page
      Navigator.pushNamed(
        context,
        '/video',
        arguments: {
          'title': content['title'] ?? 'Video',
          'videoUrl': content['videoUrl'],
          'description': content['description'] ?? '',
          'contentId': contentId, // Add contentId for progress tracking
          'roadmapId': segmentId, // Pass the segment/roadmap ID
          'courseId': courseId,
          'onAction': () {
            // Create a callback function to update progress when video is completed
            debugPrint('Video completed, updating progress');
            updateProgress(contentId, segmentId, courseId);

            // Don't navigate back automatically - this is handled in updateProgress
            // based on whether this is the last content or not
            if (!isLastContent) {
              // Only pop if not the last content
              Navigator.pop(context);
            }
          },
        },
      );
    }

    // Log quizId for quiz content
    if (contentType.toLowerCase() == 'quiz' && content['quizId'] != null) {
      debugPrint('quizId: ${content['quizId']}');

      // Check if this is the last content
      bool isLastContent = isLastContentOfLastRoadmap(contentId, segmentId);
      debugPrint('Is last content of last roadmap: $isLastContent');

      // Navigate to quiz page
      Navigator.pushNamed(
        context,
        '/quiz',
        arguments: {
          'title': content['title'] ?? 'Quiz',
          'quizId': content['quizId'],
          'courseId': courseId,
          'roadmapId': segmentId, // Pass the segment/roadmap ID
          'contentId': contentId, // Pass the content ID for progress tracking
          'isLastContent':
              isLastContent, // Indicate if this is the last content
        },
      );
    }

    debugPrint('=====================');
  }
}
