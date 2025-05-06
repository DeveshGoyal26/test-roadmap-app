import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:ui';

// -----------------------------------------------------------------
// SPIRAL SQUARE PAGE - IMPLEMENTATION NOTES
// -----------------------------------------------------------------
// This file implements the "Spiral Square" learning path view showing
// course content in a spiral path. The key components are:
//
// API RESPONSE HANDLING:
// - roadmapHistory: Contains segments that have been fully completed
//   - If a segment ID is in roadmapHistory, the entire segment is considered completed
//
// - contentHistory: Contains individual content items that have been completed
//   - Used to determine which specific items are completed in partially completed segments
//
// CONTENT STATUS DETERMINATION:
// For each content item, its status is determined by these rules:
//
// 1. AVAILABILITY:
//    - Paid users: All content is available
//    - Free users: Only the first content of the first segment is available
//
// 2. COMPLETION STATUS:
//    - A content is considered COMPLETED if:
//      a. Its segment ID is in roadmapHistory (entire segment completed) OR
//      b. Its content ID is in contentHistory (individual content completed)
//
// 3. ACTIVE STATUS (for showing active vs. locked icons):
//    - Show ACTIVE icon if:
//      a. Content is COMPLETED, OR
//      b. Content is the NEXT content to be completed AND
//         (user is paid OR it's the first free content)
//    - Show LOCKED icon for all other content
//
// DEBUGGING:
// The code includes extensive debug logging to trace:
// - API data parsing and processing
// - Content ID matching between API and UI
// - Icon selection logic
// - Status determination for each content
// -----------------------------------------------------------------

// Import header components
import '../components/header_component.dart';
import '../components/progress_slider_component.dart';
import '../components/user_progress_strip_component.dart';

// Import services and models
import '../services/course_service.dart';
import '../models/course_models.dart';

// SVG assets - properly imported as used in spiral_content.dart
// Violet (segment 1, 5, 9, etc.)
final videoActiveVioletIcon = 'assets/svg/video_active_voilet.svg';
final videoLockVioletIcon = 'assets/svg/video_lock_voilet.svg';
final quizActiveVioletIcon = 'assets/svg/quiz_active_voilet.svg';
final quizLockVioletIcon = 'assets/svg/quiz_lock_voilet.svg';

// Green (segment 2, 6, 10, etc.)
final videoActiveGreenIcon = 'assets/svg/video_active_green.svg';
final videoLockGreenIcon = 'assets/svg/video_lock_green.svg';
final quizActiveGreenIcon = 'assets/svg/quiz_active_green.svg';
final quizLockGreenIcon = 'assets/svg/quiz_lock_green.svg';

// Orange (segment 3, 7, 11, etc.)
final videoActiveOrangeIcon = 'assets/svg/video_active_orange.svg';
final videoLockOrangeIcon = 'assets/svg/video_lock_orange.svg';
final quizActiveOrangeIcon = 'assets/svg/quiz_active_orange.svg';
final quizLockOrangeIcon = 'assets/svg/quiz_lock_orange.svg';

// Yellow (segment 4, 8, 12, etc.)
final videoActiveYellowIcon = 'assets/svg/video_active_yellow.svg';
final videoLockYellowIcon = 'assets/svg/video_lock_yellow.svg';
final quizActiveYellowIcon = 'assets/svg/quiz_active_yellow.svg';
final quizLockYellowIcon = 'assets/svg/quiz_lock_yellow.svg';

// Legacy variables for backward compatibility
final videoActiveIcon = 'assets/svg/video_active_voilet.svg';
final videoLockIcon = 'assets/svg/video_lock_voilet.svg';
final quizActiveIcon = 'assets/svg/quiz_active_voilet.svg';
final quizLockIcon = 'assets/svg/quiz_lock_voilet.svg';

// Color-specific lock icons
final lockVioletIcon = 'assets/svg/lock_voilet.svg';
final lockGreenIcon = 'assets/svg/lock_green.svg';
final lockOrangeIcon = 'assets/svg/lock_orange.svg';
final lockYellowIcon = 'assets/svg/quiz_lock_yellow.svg';

// Create a custom painter for the arrow
class ArrowPainter extends CustomPainter {
  final bool pointRight;

  ArrowPainter({required this.pointRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill
          ..strokeWidth = 1;

    final path = Path();
    if (pointRight) {
      // Arrow pointing right
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      // Arrow pointing left
      path.moveTo(size.width, size.height / 2);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);

    // Draw shadow
    final shadowPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpiralSquarePage extends StatefulWidget {
  final String? courseId;

  const SpiralSquarePage({Key? key, this.courseId}) : super(key: key);

  @override
  State<SpiralSquarePage> createState() => _SpiralSquarePageState();
}

class _SpiralSquarePageState extends State<SpiralSquarePage> {
  bool isLoading = true;
  String subtitle = 'Design';
  String title = 'Product Design';
  Color subtitleColor = const Color(0xFF9933FF);
  VoidCallback? onBackPressed;

  List<Segment> segments = [];

  // Create a CourseService instance
  final CourseService _courseService = CourseService();

  // Default course ID to use if none is provided
  final String defaultCourseId =
      "680617206fdf0f64202707db"; // Web Development course

  // API response data
  Map<String, dynamic>? courseData;
  Map<String, dynamic>? progressData;

  // Course and progress models
  Course? course;
  CourseProgress? progress;

  // User's payment status - defaults to 'free'
  String _userPaymentStatus = 'free';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Get the course ID (use default if none provided)
      final String courseId = widget.courseId ?? defaultCourseId;
      debugPrint('Fetching data for courseId: $courseId');

      // Set loading state
      setState(() {
        isLoading = true;
      });

      // Make API call to get course details
      try {
        final courseResponse = await _courseService.getCourseDetails(courseId);
        courseData = courseResponse;
        debugPrint(
          'Course data received, success: ${courseResponse['success']}',
        );

        // Parse course data into model
        if (courseResponse['success'] == true) {
          course = Course.fromApiResponse(courseResponse);
          // Set the payment status
          _userPaymentStatus = course?.userPaymentStatus ?? 'free';
          debugPrint('Payment status: $_userPaymentStatus');
          debugPrint('Course segments count: ${course?.segments.length}');

          // Print first segment details to debug
          if (course != null && course!.segments.isNotEmpty) {
            debugPrint('First segment: ${course!.segments[0].title}');
            debugPrint(
              'First segment content count: ${course!.segments[0].content.length}',
            );
          }
        } else {
          debugPrint('Course API returned success=false');
        }
      } catch (e) {
        debugPrint('Error fetching course details: $e');
      }

      // Make API call to get user progress
      try {
        final progressResponse = await _courseService.getUserProgress(courseId);
        progressData = progressResponse;
        debugPrint(
          'Progress data received, success: ${progressResponse['success']}',
        );

        // Create a dummy/default progress object
        Map<String, dynamic> customProgressData = {
          'success': true,
          'progress': {
            '_id': '',
            'userId': '',
            'courseId': courseId,
            'startedAt': DateTime.now().toIso8601String(),
            'lastAccessedAt': DateTime.now().toIso8601String(),
            'overallProgress': 0,
            'currentSegment': null,
            'completedSegments': <String>[],
            'segmentProgress': <Map<String, dynamic>>[],
          },
        };

        // Check if we have valid progress data
        if (progressResponse['success'] == true &&
            progressResponse['progress'] != null) {
          // Get the basic progress info
          customProgressData['progress']['_id'] =
              progressResponse['progress']['_id']?.toString() ?? '';
          customProgressData['progress']['userId'] =
              progressResponse['progress']['userId']?.toString() ?? '';

          // Extract completed content IDs from the contentHistory structure
          List<Map<String, dynamic>> completedContentBySegment = [];
          List<String> completedSegmentIds = [];

          // Process roadmap history (completed segments)
          if (progressResponse['progress']['roadmapHistory'] is List) {
            var roadmapHistory =
                progressResponse['progress']['roadmapHistory'] as List;
            debugPrint('Found ${roadmapHistory.length} completed roadmaps');

            // Extract all the segment IDs from roadmapHistory
            // These segments are considered fully completed
            for (var item in roadmapHistory) {
              if (item is Map &&
                  item['roadmap'] is Map &&
                  item['roadmap']['_id'] != null) {
                // Add the segment ID to the completedSegmentIds list
                completedSegmentIds.add(item['roadmap']['_id'].toString());
                debugPrint(
                  'Added completed segment: ${item['roadmap']['_id']} (${item['roadmap']['title']})',
                );
              }
            }

            // Store the list of completed segment IDs in the progress data
            customProgressData['progress']['completedSegments'] =
                completedSegmentIds;
            debugPrint(
              'Total completed segments: ${completedSegmentIds.length}',
            );
          }

          // Process content history
          // The contentHistory in the API response contains individual content items that have been completed
          if (progressResponse['progress']['contentHistory'] is List &&
              course != null) {
            var contentHistory =
                progressResponse['progress']['contentHistory'] as List;
            debugPrint(
              'Found ${contentHistory.length} completed content items',
            );

            // Group completed content by segmentId
            Map<String, List<String>> contentBySegment = {};

            // Process each content in the history
            for (var item in contentHistory) {
              if (item is Map &&
                  item['content'] is Map &&
                  item['content']['_id'] != null) {
                // Get the content ID directly from the API
                final contentId = item['content']['_id'].toString();
                final contentType = item['content']['type']?.toString() ?? '';
                final contentTitle = item['content']['title']?.toString() ?? '';

                debugPrint(
                  'Processing completed content: $contentId (Type: $contentType, Title: $contentTitle)',
                );

                // Find which segment this content belongs to
                bool contentFound = false;
                for (var segment in course!.segments) {
                  for (var content in segment.content) {
                    // Compare with all properties to help debug matching issues
                    final bool idMatch = content.id == contentId;
                    if (idMatch) {
                      // Found the segment this content belongs to
                      if (!contentBySegment.containsKey(segment.id)) {
                        contentBySegment[segment.id] = [];
                      }
                      contentBySegment[segment.id]!.add(contentId);
                      debugPrint(
                        'Content $contentId (Type: $contentType) belongs to segment ${segment.id} (${segment.title})',
                      );
                      contentFound = true;
                      break;
                    }
                  }
                  if (contentFound) break;
                }

                // If content wasn't found in any segment, log a warning
                if (!contentFound) {
                  debugPrint(
                    'WARNING: Content $contentId (Type: $contentType, Title: $contentTitle) not found in any segment',
                  );
                }
              }
            }

            debugPrint(
              'Grouped content by ${contentBySegment.length} segments',
            );

            // Create segment progress entries
            // This will be used to determine which content has been completed in each segment
            for (var entry in contentBySegment.entries) {
              final segmentId = entry.key;
              final completedContentIds = entry.value;

              // Find the segment to get total content count
              final segment = course!.segments.firstWhere(
                (s) => s.id == segmentId,
                orElse:
                    () => CourseSegment(
                      id: '',
                      title: '',
                      description: '',
                      segmentOrder: 0,
                      totalLevels: 0,
                      freeFlow: false,
                      tags: [],
                      content: [],
                      courseId: '',
                    ),
              );

              if (segment.id.isNotEmpty) {
                final totalContent = segment.content.length;
                final progress =
                    totalContent > 0
                        ? (completedContentIds.length / totalContent * 100)
                            .round()
                        : 0;

                // Add to the progress data the information about completed content in this segment
                completedContentBySegment.add({
                  'segmentId': segmentId,
                  'progress': progress,
                  'completedContent': completedContentIds,
                });

                debugPrint(
                  'Segment $segmentId: ${completedContentIds.length}/$totalContent completed ($progress%)',
                );
              }
            }

            // Store the segment progress in the custom progress data
            customProgressData['progress']['segmentProgress'] =
                completedContentBySegment;

            // Calculate overall progress
            int totalContent = 0;
            int totalCompleted = 0;

            for (var segment in course!.segments) {
              totalContent += segment.content.length;
            }

            for (var segmentProgress in completedContentBySegment) {
              totalCompleted +=
                  (segmentProgress['completedContent'] as List).length;
            }

            final overallProgress =
                totalContent > 0
                    ? (totalCompleted / totalContent * 100).round()
                    : 0;

            customProgressData['progress']['overallProgress'] = overallProgress;
            debugPrint('Calculated overall progress: $overallProgress%');

            // Determine current segment (first incomplete segment or last segment)
            if (course!.segments.isNotEmpty) {
              // Sort segments by order
              final sortedSegments = [...course!.segments]
                ..sort((a, b) => a.segmentOrder.compareTo(b.segmentOrder));

              // Find first incomplete segment
              String? currentSegmentId;
              String? currentSegmentTitle;

              for (var segment in sortedSegments) {
                final segmentProgress = completedContentBySegment.firstWhere(
                  (sp) => sp['segmentId'] == segment.id,
                  orElse: () => {'segmentId': segment.id, 'progress': 0},
                );

                final progress = segmentProgress['progress'] as int;
                if (progress < 100) {
                  currentSegmentId = segment.id;
                  currentSegmentTitle = segment.title;
                  break;
                }
              }

              // If all segments are complete, use the last one
              if (currentSegmentId == null && sortedSegments.isNotEmpty) {
                currentSegmentId = sortedSegments.last.id;
                currentSegmentTitle = sortedSegments.last.title;
              }

              if (currentSegmentId != null) {
                customProgressData['progress']['currentSegment'] = {
                  'segmentId': currentSegmentId,
                  'title': currentSegmentTitle ?? '',
                };
                debugPrint('Current segment: $currentSegmentTitle');
              }
            }
          }
        }

        // Parse progress data into model
        progress = CourseProgress.fromApiResponse(customProgressData);
        debugPrint(
          'Progress parsed successfully: ${progress?.overallProgress}%',
        );
      } catch (e) {
        debugPrint('Error fetching user progress: $e');

        // Create a default progress object in case of error
        progress = CourseProgress.fromApiResponse({
          'success': true,
          'progress': {
            '_id': '',
            'userId': '',
            'courseId': courseId,
            'startedAt': DateTime.now().toIso8601String(),
            'lastAccessedAt': DateTime.now().toIso8601String(),
            'overallProgress': 0,
            'currentSegment': null,
            'completedSegments': [],
            'segmentProgress': [],
          },
        });
      }

      // Convert API data to Segment model for the UI
      final List<Segment> apiSegments = [];

      if (course != null && course!.segments != null) {
        int segmentCounter = 1;
        for (var apiSegment in course!.segments) {
          // Calculate current level based on progress data
          int currentLevel = 0;

          // Use the progress data to determine current level for this segment
          if (progress != null && progress!.segmentProgress.isNotEmpty) {
            // Find the progress for this segment
            final segmentProgress = progress!.segmentProgress.firstWhere(
              (sp) => sp.segmentId == apiSegment.id,
              orElse:
                  () => SegmentProgress(
                    segmentId: apiSegment.id,
                    progress: 0,
                    completedContent: [],
                  ),
            );

            // Count completed content for this segment
            currentLevel = segmentProgress.completedContent.length;
          }

          // Debug print segment and level info
          debugPrint(
            'Adding segment ${apiSegment.title} (ID: ${apiSegment.id}) with currentLevel: $currentLevel, totalLevels: ${apiSegment.content.length}',
          );

          // Create levels list from content items
          final List<Level> levels = [];
          if (apiSegment.content.isNotEmpty) {
            int levelCounter = 1;
            for (var content in apiSegment.content) {
              String? quizId;
              // Extract quizId from meta data if content type is quiz
              if (content.type == 'quiz' &&
                  content.meta.containsKey('quizId')) {
                quizId = content.meta['quizId'];
              }

              // Debug print level info
              debugPrint(
                'Adding level $levelCounter of type ${content.type} for segment ${apiSegment.title}',
              );

              levels.add(
                Level(
                  id: levelCounter,
                  type:
                      content.type == 'video' || content.type == 'text'
                          ? 'video'
                          : 'quiz',
                  title: content.title,
                  description: content.description,
                  quizId: quizId,
                  contentId: content.id,
                ),
              );
              levelCounter++;
            }
          }

          // Add segment to list
          apiSegments.add(
            Segment(
              id: segmentCounter,
              title: apiSegment.title,
              currentLevel: currentLevel,
              totalLevels: levels.length,
              levels: levels,
              courseId: courseId, // Pass the actual course ID here
            ),
          );

          segmentCounter++;
        }
      }

      debugPrint('Created ${apiSegments.length} segments for UI');

      setState(() {
        segments = apiSegments;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in _fetchData: $e');
      setState(() {
        isLoading = false;
        // In case of error, create empty segments list
        segments = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug payment status
    debugPrint('Building UI with payment status: $_userPaymentStatus');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.0),
        title: Column(
          children: [
            // Centered title and subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
                letterSpacing: 0.12,
                fontFeatures: const [
                  FontFeature.proportionalFigures(),
                  FontFeature.enable('dlig'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 18 / 18,
                letterSpacing: 0.18,
                fontFeatures: const [
                  FontFeature.proportionalFigures(),
                  FontFeature.enable('dlig'),
                ],
              ),
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Loading course data...",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child:
                    segments.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sentiment_dissatisfied,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No course data available",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "API returned: ${courseData != null ? 'Data' : 'No data'}",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                        : Column(
                          children: [
                            const SizedBox(height: 14),
                            // Use the first segment's progress if available
                            segments.isNotEmpty
                                ? ProgressSliderComponent(
                                  currentValue:
                                      course?.segments != null &&
                                              progress?.currentSegment != null
                                          ? () {
                                            int index = course!.segments
                                                .indexWhere(
                                                  (s) =>
                                                      s.id ==
                                                      progress!
                                                          .currentSegment
                                                          ?.segmentId,
                                                );
                                            return index >= 0 ? index + 1 : 1;
                                          }()
                                          : 1,
                                  totalValue: course?.segments?.length ?? 1,
                                  isEnabled: false, // Disable the slider
                                )
                                : const SizedBox(),
                            const SizedBox(height: 10),

                            // Payment status indicator if not paid
                            _userPaymentStatus.toLowerCase() != 'paid'
                                ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: const Color(
                                    0xFFFFF9C4,
                                  ), // Light yellow background
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          "This course requires a subscription. Only the first lesson is available for free.",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : const SizedBox(),

                            Container(
                              width: double.infinity,
                              height: 1,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.12),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            // Scrollable content area
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _fetchData,
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    children: [
                                      // Create a vertically scrolling list of segments
                                      ...segments
                                          .map(
                                            (segment) => Column(
                                              children: [
                                                // Segment title and progress
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16.0,
                                                        horizontal: 16.0,
                                                      ),
                                                  decoration: BoxDecoration(),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          // Line on the left side of the title
                                                          Expanded(
                                                            child: Container(
                                                              height: 1,
                                                              color: Colors.grey
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                          // Title with padding
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      16.0,
                                                                ),
                                                            child: Text(
                                                              segment.title,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .bodySmall,
                                                            ),
                                                          ),
                                                          // Line on the right side of the title
                                                          Expanded(
                                                            child: Container(
                                                              height: 1,
                                                              color: Colors.grey
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Spiral map for this segment
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 0,
                                                      ),
                                                  child: Container(
                                                    height: calculateMapHeight(
                                                      segment,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30.0,
                                                          ),
                                                      color: getBackgroundColor(
                                                        segment.id,
                                                      ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30.0,
                                                          ),
                                                      child: SpiralMapView(
                                                        segment: segment,
                                                        isPaid:
                                                            _userPaymentStatus
                                                                .toLowerCase() ==
                                                            'paid',
                                                        isFirstSegment:
                                                            segment.id == 1,
                                                        completedContentIds:
                                                            (() {
                                                              final contentIds =
                                                                  progress
                                                                      ?.segmentProgress
                                                                      .where(
                                                                        (sp) =>
                                                                            sp.segmentId ==
                                                                            segment.id.toString(),
                                                                      )
                                                                      .expand(
                                                                        (sp) =>
                                                                            sp.completedContent,
                                                                      )
                                                                      .toList() ??
                                                                  [];
                                                              debugPrint(
                                                                'SPIRAL MAP INIT: Segment ${segment.id} (${segment.title}) - ' +
                                                                    'passing ${contentIds.length} completedContentIds: $contentIds',
                                                              );
                                                              return contentIds;
                                                            })(),
                                                        isSegmentCompleted:
                                                            (() {
                                                              final isCompleted =
                                                                  progress
                                                                      ?.completedSegments
                                                                      .contains(
                                                                        segment
                                                                            .id
                                                                            .toString(),
                                                                      ) ??
                                                                  false;
                                                              debugPrint(
                                                                'SPIRAL MAP INIT: Segment ${segment.id} (${segment.title}) - ' +
                                                                    'isSegmentCompleted: $isCompleted, ' +
                                                                    'completedSegments: ${progress?.completedSegments}',
                                                              );
                                                              return isCompleted;
                                                            })(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
    );
  }

  double calculateMapHeight(Segment segment) {
    // Calculate total vertices needed based on number of levels
    int levelCount = segment.levels.length;
    int totalVertices = calculateTotalVerticesNeeded(levelCount);

    // Calculate height based on vertex count
    double heightPerVertex;
    if (levelCount == 2) {
      heightPerVertex = 100.0;
    } else if (levelCount == 3) {
      heightPerVertex = 90.0;
    } else {
      heightPerVertex = 70.0;
    }

    return totalVertices * heightPerVertex;
  }
}

class SpiralMapView extends StatefulWidget {
  // The segment containing levels and other data to display
  final Segment segment;

  // Whether the user has a paid subscription
  final bool isPaid;

  // Whether this is the first segment in the course (special handling for free access)
  final bool isFirstSegment;

  // List of content IDs that the user has completed for this segment
  // These come from the API's contentHistory field
  final List<String> completedContentIds;

  // Whether the entire segment is completed (from roadmapHistory)
  // When true, all content in this segment should show active icons
  final bool isSegmentCompleted;

  const SpiralMapView({
    Key? key,
    required this.segment,
    this.isPaid = false,
    this.isFirstSegment = false,
    this.completedContentIds = const [],
    this.isSegmentCompleted = false,
  }) : super(key: key);

  @override
  State<SpiralMapView> createState() => _SpiralMapViewState();
}

class _SpiralMapViewState extends State<SpiralMapView> {
  // OverlayEntry for tooltips
  OverlayEntry? _overlayEntry;

  // Map of node keys used for positioning tooltips
  final Map<int, GlobalKey> _nodeKeys = {};

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    // Debug segment information
    debugPrint(
      'SpiralMapView for segment ${widget.segment.title} - isPaid: ${widget.isPaid}, '
      'isFirstSegment: ${widget.isFirstSegment}, '
      'isSegmentCompleted: ${widget.isSegmentCompleted}, '
      'completedContentIds: ${widget.completedContentIds}',
    );

    return Container(
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: SpiralPathPainter(
              levelsCount: widget.segment.levels.length,
              segmentId: widget.segment.id,
            ),
          ),
          ...buildLevelNodes(context),
        ],
      ),
    );
  }

  // This method builds all the level nodes (icons) for this segment
  List<Widget> buildLevelNodes(BuildContext context) {
    final List<Widget> nodes = [];

    // Get the positions for nodes based on the spiral path
    final List<Offset> nodePositions = calculateNodePositions();

    // Get the vertex indices where levels should be placed
    // (This determines which positions in the spiral should have icons)
    final List<int> vertexIndices = _getIconNodeIndices(
      widget.segment.levels.length,
      widget.segment.levels.length,
    );

    // Ensure we have enough positions for all vertices
    if (nodePositions.length < vertexIndices.last + 1) {
      debugPrint(
        'Warning: Not enough node positions calculated. Need ${vertexIndices.last + 1}, have ${nodePositions.length}',
      );
      return nodes;
    }

    // ---------------------------------------------------------------
    // DETERMINE WHICH CONTENT IS COMPLETED AND WHICH IS NEXT
    // ---------------------------------------------------------------

    // If the segment is completed entirely (found in roadmapHistory)
    // all content should be marked as completed
    final bool isEntireSegmentCompleted = widget.isSegmentCompleted;

    // Find the index of the next content to be completed (if any)
    // This is needed to show the "active" (unlocked) icon for the next content
    int nextContentIndex = -1;
    if (!isEntireSegmentCompleted) {
      // Loop through each level to find the first non-completed one
      for (int i = 0; i < widget.segment.levels.length; i++) {
        final Level level = widget.segment.levels[i];
        // If this content has not been completed (not in contentHistory)
        if (level.contentId != null &&
            !widget.completedContentIds.contains(level.contentId)) {
          nextContentIndex = i;
          break;
        }
      }

      // Edge case: If all content is completed but the segment isn't marked as completed
      if (nextContentIndex == -1 && widget.segment.levels.isNotEmpty) {
        nextContentIndex = widget.segment.levels.length;
      }
    }

    // Log segment analysis results
    debugPrint(
      'SEGMENT ANALYSIS: ${widget.segment.id} (${widget.segment.title}): '
      'isEntireSegmentCompleted: $isEntireSegmentCompleted, '
      'nextContentIndex: $nextContentIndex, '
      'completedContentIds: ${widget.completedContentIds}',
    );

    // Log all level contentIds to help with debugging
    debugPrint('LEVEL CONTENT IDS CHECK:');
    for (int i = 0; i < widget.segment.levels.length; i++) {
      final level = widget.segment.levels[i];
      final isInCompletedList =
          level.contentId != null &&
          widget.completedContentIds.contains(level.contentId);
      debugPrint(
        '  Level ${level.id}: contentId=${level.contentId}, '
        'isInCompletedList=$isInCompletedList',
      );
    }

    // ---------------------------------------------------------------
    // CREATE NODES FOR EACH LEVEL
    // ---------------------------------------------------------------

    // Place each level at its corresponding vertex
    for (
      int i = 0;
      i < widget.segment.levels.length && i < vertexIndices.length;
      i++
    ) {
      final int vertexIndex =
          vertexIndices[i]; // The vertex position for this level
      final Level level = widget.segment.levels[i]; // The level to place

      // ---------------------------------------------------------------
      // DETERMINE CONTENT STATUS
      // ---------------------------------------------------------------

      // Is this the first content of the first segment? (Always available in free tier)
      final bool isFirstContent = widget.isFirstSegment && i == 0;

      // Content is available if:
      // 1. User has paid subscription OR
      // 2. It's the first content of the first segment (free content)
      final bool isAvailable = widget.isPaid || isFirstContent;

      // Content is considered COMPLETED if:
      // 1. The entire segment is completed (present in roadmapHistory) OR
      // 2. This specific content ID is in the user's completedContentIds (from contentHistory)
      final bool isCompleted =
          isEntireSegmentCompleted ||
          (level.contentId != null &&
              widget.completedContentIds.contains(level.contentId));

      // Content is considered the NEXT ACTIVE one if it's the next in sequence
      // after the completed ones
      final bool isNextActive = i == nextContentIndex;

      // ---------------------------------------------------------------
      // DETERMINE WHICH ICON TO SHOW
      // ---------------------------------------------------------------

      // We show the active icon if:
      // 1. The content is available (paid user or first free content) AND
      // 2. Either:
      //    a. The content is completed OR
      //    b. It's the next content to complete (for paid users or the first free content)
      final bool showActiveIcon =
          isAvailable ||
          (isCompleted || (isNextActive && (widget.isPaid || isFirstContent)));

      // Get the appropriate icon based on status
      final String iconUsed =
          isAvailable
              ? _getLevelIcon(level.type, showActiveIcon)
              : _getLockIcon();

      // Log detailed status for debugging
      debugPrint(
        'Level ${level.id} in segment ${widget.segment.id} - '
        'isPaid: ${widget.isPaid}, '
        'isAvailable: $isAvailable, '
        'isCompleted: $isCompleted, '
        'isNextActive: $isNextActive, '
        'showActiveIcon: $showActiveIcon, '
        'contentId: ${level.contentId}, '
        'using icon: $iconUsed',
      );

      // ---------------------------------------------------------------
      // CALCULATE NODE POSITION
      // ---------------------------------------------------------------

      // Get the base position from the vertex index
      Offset position = nodePositions[vertexIndex];

      // For junction nodes (not first or last), adjust position slightly away from corners
      if (i > 0 && i < widget.segment.levels.length - 1) {
        // Get the previous node position
        final int prevVertexIndex = vertexIndices[i - 1];
        final Offset prevPosition = nodePositions[prevVertexIndex];

        // Calculate direction vector
        final double dx = position.dx - prevPosition.dx;
        final double dy = position.dy - prevPosition.dy;

        // Calculate vector length
        final double length = math.sqrt(dx * dx + dy * dy);

        if (length > 0) {
          // Move icon away from the corner to accommodate the more rounded path
          // Adjust placement to be 25% along the path instead of 20%
          position = Offset(
            position.dx - dx * 0.25,
            position.dy -
                dy * 0.25 +
                10, // Increased vertical offset from 7 to 10
          );
        }
      }

      // Create a global key for this node if it doesn't exist
      // (Used for positioning tooltips)
      if (!_nodeKeys.containsKey(level.id)) {
        _nodeKeys[level.id] = GlobalKey();
      }

      // ---------------------------------------------------------------
      // CREATE THE NODE WIDGET
      // ---------------------------------------------------------------

      nodes.add(
        Positioned(
          left: position.dx - 35, // Adjust for larger node size
          top: position.dy - 35, // Adjust for larger node size
          child: GestureDetector(
            key: _nodeKeys[level.id],
            onTap: () {
              // Only show tooltip for available content
              if (isAvailable) {
                _showTooltip(context, level, showActiveIcon);
              }
            },
            child: Stack(
              children: [
                // Use a try-catch block to handle any SVG loading errors
                Builder(
                  builder: (context) {
                    try {
                      return SvgPicture.asset(
                        isAvailable
                            ? _getLevelIcon(level.type, showActiveIcon)
                            : _getLockIcon(),
                        width: 70, // Increased icon size
                        height: 70, // Increased icon size
                        // Add placeholder in case of error
                        placeholderBuilder:
                            (BuildContext context) => Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  level.type == 'quiz'
                                      ? Icons.help
                                      : Icons.play_arrow,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                      );
                    } catch (e) {
                      debugPrint('Error loading SVG: $e');
                      // Fallback to a basic icon if SVG fails to load
                      return Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color:
                              isAvailable
                                  ? showActiveIcon
                                      ? Colors.purple.withValues(alpha: 0.7)
                                      : Colors.grey.withValues(alpha: 0.5)
                                  : Colors.grey.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            level.type == 'quiz'
                                ? Icons.help
                                : Icons.play_arrow,
                            size: 30,
                            color:
                                isAvailable
                                    ? Colors.white
                                    : Colors.grey.shade700,
                          ),
                        ),
                      );
                    }
                  },
                ),
                // Lock icon overlay is disabled
                if (!isAvailable && false)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock, size: 16, color: Colors.orange),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return nodes;
  }

  // Helper method to determine which nodes should have icons
  List<int> _getIconNodeIndices(int totalLevels, int maxAvailableNodes) {
    // Calculate total vertices needed for displaying all levels
    // For 7 levels, we need: 0, 1, 3, 5, 7, 9, 11 (total 12 vertices with skipped odd indices)

    // Create the mapping of level index to vertex index
    List<int> vertexIndices = [];

    // First level at vertex 0
    vertexIndices.add(0);

    // Second level at vertex 1
    if (totalLevels > 1) {
      vertexIndices.add(1);
    }

    // For levels 3 through second-to-last, place them at vertices skipping odd indices
    int vertexIndex = 3;
    for (int levelIndex = 2; levelIndex < totalLevels - 1; levelIndex++) {
      vertexIndices.add(vertexIndex);
      vertexIndex += 2; // Skip to next even-numbered vertex
    }

    // For the last level, if there are more than 2 levels
    if (totalLevels > 2) {
      // Don't skip the next vertex for the last level
      // Just use the next vertex in sequence after the previous one
      int lastVertexIndex = vertexIndices.last;
      vertexIndices.add(lastVertexIndex + 1);
    }

    return vertexIndices;
  }

  String _getLevelIcon(String type, bool isActive) {
    // Calculate segment category (1-4) based on segment ID
    int category = ((widget.segment.id - 1) % 4) + 1;
    debugPrint(
      'Getting icon for segment ${widget.segment.id}, category: $category, type: $type, isActive: $isActive',
    );

    if (type == 'video') {
      switch (category) {
        case 1: // Violet (segments 1, 5, 9, etc.)
          return isActive ? videoActiveVioletIcon : videoLockVioletIcon;
        case 2: // Green (segments 2, 6, 10, etc.)
          return isActive ? videoActiveGreenIcon : videoLockGreenIcon;
        case 3: // Orange (segments 3, 7, 11, etc.)
          return isActive ? videoActiveOrangeIcon : videoLockOrangeIcon;
        case 4: // Yellow (segments 4, 8, 12, etc.)
          debugPrint(
            'Using yellow video icon: ${isActive ? videoActiveYellowIcon : videoLockYellowIcon}',
          );
          return isActive ? videoActiveYellowIcon : videoLockYellowIcon;
        default:
          return isActive ? videoActiveVioletIcon : videoLockVioletIcon;
      }
    } else {
      switch (category) {
        case 1: // Violet (segments 1, 5, 9, etc.)
          return isActive ? quizActiveVioletIcon : quizLockVioletIcon;
        case 2: // Green (segments 2, 6, 10, etc.)
          return isActive ? quizActiveGreenIcon : quizLockGreenIcon;
        case 3: // Orange (segments 3, 7, 11, etc.)
          return isActive ? quizActiveOrangeIcon : quizLockOrangeIcon;
        case 4: // Yellow (segments 4, 8, 12, etc.)
          debugPrint(
            'Using yellow quiz icon: ${isActive ? quizActiveYellowIcon : quizLockYellowIcon}',
          );
          return isActive ? quizActiveYellowIcon : quizLockYellowIcon;
        default:
          return isActive ? quizActiveVioletIcon : quizLockVioletIcon;
      }
    }
  }

  // Helper method for locked content icons
  String _getLockIcon() {
    // Calculate segment category (1-4) based on segment ID
    int category = ((widget.segment.id - 1) % 4) + 1;
    debugPrint(
      'Getting lock icon for segment ${widget.segment.id}, category: $category',
    );

    // Use the color-specific lock icons
    switch (category) {
      case 1: // Violet (segments 1, 5, 9, etc.)
        return lockVioletIcon;
      case 2: // Green (segments 2, 6, 10, etc.)
        return lockGreenIcon;
      case 3: // Orange (segments 3, 7, 11, etc.)
        return lockOrangeIcon;
      case 4: // Yellow (segments 4, 8, 12, etc.)
        debugPrint('Using yellow lock icon: $lockYellowIcon');
        return lockYellowIcon;
      default:
        return lockVioletIcon;
    }
  }

  List<Offset> calculateNodePositions() {
    final List<Offset> positions = [];

    // Calculate total vertices needed based on number of levels
    int totalVertices = calculateTotalVerticesNeeded(
      widget.segment.levels.length,
    );

    // We don't need to account for the padding here since
    // the SpiralMapView is inside a padded container
    final screenWidth =
        MediaQuery.of(context).size.width - 32.0; // Subtract both sides padding

    // Define margins and screen bounds
    final leftMargin = screenWidth * 0.15;
    final rightMargin = screenWidth * 0.85;

    // Normal width between left and right margins
    final normalWidth = (rightMargin - leftMargin);

    // Starting position (leftmost side of screen)
    double startX = leftMargin;
    double startY = 60; // Reduced from 120 to 60 to minimize top gap

    // Vertical and diagonal steps
    double verticalStep = 120;
    double diagonalHorizontalStep = normalWidth;
    double diagonalVerticalStep = 80;

    // Current position
    double currentX = startX;
    double currentY = startY;

    // Add starting point (Point 1)
    positions.add(Offset(currentX, currentY));

    // Calculate positions for every vertex (including ones that will be skipped)
    for (int i = 1; i < totalVertices; i++) {
      // Determine which step in the pattern we're on (0-3)
      int step = (i - 1) % 4;

      // Adjusted values for specific lines
      double adjustedWidth = normalWidth;
      double adjustedVerticalStep = verticalStep;

      // Line 3: line from vertex 3 to 4 (when i=3, we're calculating vertex 4)
      // Reduce length by 10%
      if (i == 3) {
        adjustedVerticalStep = verticalStep * 0.9; // 10% shorter
        // print("Reducing line 3 (vertex 3 to 4) by 10%");
      }
      // Line 5: line from vertex 5 to 6 (when i=5, we're calculating vertex 6)
      // Increase length by 10%
      else if (i == 5) {
        adjustedVerticalStep = verticalStep * 1.1; // 10% longer
        // print("Increasing line 5 (vertex 5 to 6) by 10%");
      }

      if (step == 0) {
        // Diagonal downwards and to the right
        currentX += diagonalHorizontalStep;
        currentY += diagonalVerticalStep;
      } else if (step == 1) {
        // Vertical down - where we need adjustments for lines 3 and 5
        currentY += adjustedVerticalStep; // Use adjusted vertical step
      } else if (step == 2) {
        // Diagonal upwards and to the left
        currentX -= diagonalHorizontalStep;
        currentY -= diagonalVerticalStep;
      } else if (step == 3) {
        // Vertical down
        currentY += verticalStep;
      }

      positions.add(Offset(currentX, currentY));
    }

    return positions;
  }

  void _showTooltip(BuildContext context, Level level, bool isActive) {
    _removeOverlay();

    // Get position of the level node
    final nodeKey = _nodeKeys[level.id];
    if (nodeKey?.currentContext == null) return;

    final RenderBox renderBox =
        nodeKey!.currentContext!.findRenderObject() as RenderBox;
    final Offset nodePosition = renderBox.localToGlobal(Offset.zero);
    final Size nodeSize = renderBox.size;

    final tooltipWidth = 280.0;
    final tooltipArrowSize = 10.0;
    final tooltipHeight = 220.0; // Approximate tooltip height

    // Determine if node is on left or right side of screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLeftNode = nodePosition.dx < screenWidth / 2;

    debugPrint(
      'Showing tooltip for level ${level.id}, type: ${level.type}, active: $isActive, ' +
          'contentId: ${level.contentId}, quizId: ${level.quizId}',
    );

    // Position tooltip on the opposite side of the node
    double tooltipX;
    bool showLeftArrow = false;
    bool showRightArrow = false;

    if (isLeftNode) {
      // Node is on left side - show tooltip to the right
      tooltipX = nodePosition.dx + nodeSize.width;
      // Make sure tooltip doesn't go off right edge
      if (tooltipX + tooltipWidth > screenWidth - 20) {
        tooltipX = screenWidth - tooltipWidth - 20;
      }
      showRightArrow = true;
    } else {
      // Node is on right side - show tooltip to the left
      tooltipX = nodePosition.dx - tooltipWidth - tooltipArrowSize;
      // Make sure tooltip doesn't go off left edge
      if (tooltipX < 20) {
        tooltipX = 20;
        showLeftArrow = false; // Hide arrow if we've moved too far
      } else {
        showLeftArrow = true;
      }
    }

    // Center tooltip vertically with node
    double tooltipY = nodePosition.dy - 100.0;

    // Make sure tooltip doesn't go off top edge
    if (tooltipY < 20) {
      tooltipY = 20;
    }

    // Make sure tooltip doesn't go off bottom edge
    if (tooltipY + tooltipHeight > screenHeight - 80) {
      tooltipY = screenHeight - tooltipHeight - 80;
    }

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              // Transparent full-screen container to handle outside clicks
              Positioned.fill(
                child: GestureDetector(
                  onTap: _removeOverlay,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Tooltip with arrow
              Positioned(
                left: tooltipX,
                top: tooltipY,
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Show arrow on right for left nodes
                      if (showRightArrow)
                        SizedBox(
                          width: 10,
                          height: 20,
                          child: CustomPaint(
                            painter: ArrowPainter(pointRight: true),
                          ),
                        ),

                      // Tooltip content
                      Container(
                        width: tooltipWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child:
                            level.type == 'video'
                                ? _buildVideoTooltip(level)
                                : _buildQuizTooltip(level),
                      ),

                      // Show arrow on left for right nodes
                      if (showLeftArrow)
                        SizedBox(
                          width: 10,
                          height: 20,
                          child: CustomPaint(
                            painter: ArrowPainter(pointRight: false),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Widget for Video tooltip - matching spiral_content.dart style
  Widget _buildVideoTooltip(Level level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9933FF), // Purple background for video
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Level ${level.id}", // Video title with level number
                    style: const TextStyle(
                      color: Color(0xFF171600),
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                level.description, // Video description
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  _removeOverlay(); // Close the tooltip first
                  // Navigate to the video player page
                  Navigator.pushNamed(
                    context,
                    '/video',
                    arguments: {
                      'level': level.id,
                      'title': level.title,
                      'description': level.description,
                    },
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9933FF), // Purple button for video
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      "Watch Video", // Button text for video
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget for Quiz tooltip - matching spiral_content.dart style
  Widget _buildQuizTooltip(Level level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F87A), // Yellow background
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF000000),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "It's Quiz Time", // Quiz title
                    style: TextStyle(
                      color: Color(0xFF171600),
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                level.description,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  _removeOverlay(); // Close the tooltip first
                  // Navigate to the quiz page
                  Navigator.pushNamed(
                    context,
                    '/quiz',
                    arguments: {
                      'title': level.title,
                      'subtitle': 'Product Design',
                      'level': level.id,
                      'quizId':
                          level.quizId ?? 'default-quiz-id', // Add quiz ID
                      'courseId': widget.segment.courseId, // Add course ID
                    },
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F87A), // Yellow button
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      "Start Quiz", // Button text
                      style: TextStyle(
                        color: Color(0xFF171600),
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SpiralPathPainter extends CustomPainter {
  final int levelsCount;
  final int segmentId;

  SpiralPathPainter({required this.levelsCount, required this.segmentId});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate path points based on the spiral pattern
    final List<Offset> points = calculatePathPoints(size);

    // Create path with properly rounded corners
    final Path path = createRoundedCornerPath(points);

    // Get background colors based on segment ID
    Color backgroundColorHex = getBackgroundColorHex(segmentId);
    Color dashColor = getDashColor(segmentId);

    // STEP 1: Draw background path with rounded corners
    // This creates a wider line behind the dashed line as padding
    final Paint backgroundPaint =
        Paint()
          ..color = backgroundColorHex
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              22 // Slightly reduced width for cleaner appearance
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    // Draw the background path first
    canvas.drawPath(path, backgroundPaint);

    // STEP 2: Draw the dashed line on top of the background
    final Paint dashPaint =
        Paint()
          ..color = dashColor
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              8 // Slightly reduced width for cleaner appearance
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    // STEP 3: Create the dashed effect
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      bool draw =
          true; // Alternates between drawing and skipping to create dashes

      // Dash and gap sizes (in pixels)
      const dashLength = 16;
      const gapLength = 13;

      // Draw dashes along the path
      while (distance < pathMetric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          // Extract just the portion of the path for this dash
          final extractPath = pathMetric.extractPath(distance, distance + len);
          // Draw just this dash on the canvas
          canvas.drawPath(extractPath, dashPaint);
        }
        // Move to the next segment (dash or gap)
        distance += len;
        // Toggle between dash and gap
        draw = !draw;
      }
    }
  }

  // Create a path with properly rounded corners
  Path createRoundedCornerPath(List<Offset> points) {
    if (points.length < 2) return Path();

    final Path path = Path();
    final double cornerRadius = 40.0;

    // Create the mapping of level index to vertex index (same logic as in _getIconNodeIndices)
    List<int> vertexIndices = [];

    // First level at vertex 0
    vertexIndices.add(0);

    // Second level at vertex 1
    if (levelsCount > 1) {
      vertexIndices.add(1);
    }

    // For levels 3 through second-to-last, place them at vertices skipping odd indices
    int vertexIndex = 3;
    for (int levelIndex = 2; levelIndex < levelsCount - 1; levelIndex++) {
      vertexIndices.add(vertexIndex);
      vertexIndex += 2; // Skip to next even-numbered vertex
    }

    // For the last level, if there are more than 2 levels
    if (levelsCount > 2) {
      // Don't skip the next vertex for the last level
      // Just use the next vertex in sequence after the previous one
      int lastVertexIndex = vertexIndices.last;
      vertexIndices.add(lastVertexIndex + 1);
    }

    // The highest vertex index with an icon
    int maxVertexIndex = vertexIndices.isNotEmpty ? vertexIndices.last : 0;

    // Start at the first point
    path.moveTo(points[0].dx, points[0].dy);

    // For each segment of the path
    for (int i = 1; i < points.length; i++) {
      // If we've gone beyond the last vertex with an icon, stop drawing
      if (i > maxVertexIndex) break;

      final Offset current = points[i];
      final Offset prev = points[i - 1];

      // First segment (from first to second vertex)
      if (i == 1) {
        // Calculate vectors for the first segment
        final Offset firstSegmentVector = Offset(
          current.dx - prev.dx,
          current.dy - prev.dy,
        );

        // Calculate length of first segment
        final double firstSegmentLength = math.sqrt(
          firstSegmentVector.dx * firstSegmentVector.dx +
              firstSegmentVector.dy * firstSegmentVector.dy,
        );

        if (firstSegmentLength > 0 &&
            points.length > 2 &&
            i < points.length - 1) {
          // Normalize vector
          final Offset normalizedVector = Offset(
            firstSegmentVector.dx / firstSegmentLength,
            firstSegmentVector.dy / firstSegmentLength,
          );

          // Calculate the shortened endpoint of the first segment
          final Offset shortenedEnd = Offset(
            current.dx - normalizedVector.dx * cornerRadius,
            current.dy - normalizedVector.dy * cornerRadius,
          );

          // Draw line to the shortened endpoint
          path.lineTo(shortenedEnd.dx, shortenedEnd.dy);

          // If there's a next segment, prepare the outgoing vector
          final Offset outgoingVector = Offset(
            points[i + 1].dx - current.dx,
            points[i + 1].dy - current.dy,
          );

          final double outgoingLength = math.sqrt(
            outgoingVector.dx * outgoingVector.dx +
                outgoingVector.dy * outgoingVector.dy,
          );

          if (outgoingLength > 0) {
            final Offset normalizedOutgoing = Offset(
              outgoingVector.dx / outgoingLength,
              outgoingVector.dy / outgoingLength,
            );

            // Calculate the shortened start point of the outgoing line
            final Offset shortenedStart = Offset(
              current.dx + normalizedOutgoing.dx * cornerRadius,
              current.dy + normalizedOutgoing.dy * cornerRadius,
            );

            // Connect with a curve through the vertex
            path.quadraticBezierTo(
              current.dx,
              current.dy,
              shortenedStart.dx,
              shortenedStart.dy,
            );

            // Move to the shortened start for the next segment
            path.moveTo(shortenedStart.dx, shortenedStart.dy);
          } else {
            // If there's no valid outgoing vector, just continue to the vertex
            path.lineTo(current.dx, current.dy);
          }
        } else {
          // If we can't calculate vectors or there are no more points, draw line to vertex
          path.lineTo(current.dx, current.dy);
        }
      }
      // Junction points (vertices after the second one)
      else if (i > 1 && i < points.length - 1 && i < maxVertexIndex) {
        // Calculate the incoming vector (from previous point to current)
        final Offset incomingVector = Offset(
          current.dx - prev.dx,
          current.dy - prev.dy,
        );

        // Calculate the outgoing vector (from current to next point)
        final Offset outgoingVector = Offset(
          points[i + 1].dx - current.dx,
          points[i + 1].dy - current.dy,
        );

        // Calculate vector lengths
        final double incomingLength = math.sqrt(
          incomingVector.dx * incomingVector.dx +
              incomingVector.dy * incomingVector.dy,
        );

        final double outgoingLength = math.sqrt(
          outgoingVector.dx * outgoingVector.dx +
              outgoingVector.dy * outgoingVector.dy,
        );

        if (incomingLength > 0 && outgoingLength > 0) {
          // Normalize vectors
          final Offset normalizedIncoming = Offset(
            incomingVector.dx / incomingLength,
            incomingVector.dy / incomingLength,
          );

          final Offset normalizedOutgoing = Offset(
            outgoingVector.dx / outgoingLength,
            outgoingVector.dy / outgoingLength,
          );

          // Calculate the shortened end point of the incoming line
          // Reduce length by cornerRadius to prevent intersection
          final Offset shortenedEnd = Offset(
            current.dx - normalizedIncoming.dx * cornerRadius,
            current.dy - normalizedIncoming.dy * cornerRadius,
          );

          // Calculate the shortened start point of the outgoing line
          final Offset shortenedStart = Offset(
            current.dx + normalizedOutgoing.dx * cornerRadius,
            current.dy + normalizedOutgoing.dy * cornerRadius,
          );

          // Draw line to the shortened end point
          path.lineTo(shortenedEnd.dx, shortenedEnd.dy);

          // Connect the two shortened points with a curve
          path.quadraticBezierTo(
            current.dx,
            current.dy,
            shortenedStart.dx,
            shortenedStart.dy,
          );

          // Continue from this point in the next iteration
          path.moveTo(shortenedStart.dx, shortenedStart.dy);
        } else {
          // Fallback if we can't calculate vectors
          path.lineTo(current.dx, current.dy);
        }
      }
      // For the last segment or direct segments, draw a straight line
      else if (i == maxVertexIndex) {
        path.lineTo(current.dx, current.dy);
      } else {
        path.lineTo(current.dx, current.dy);
      }
    }

    return path;
  }

  List<Offset> calculatePathPoints(Size size) {
    final List<Offset> positions = [];

    // Calculate total vertices needed
    int totalVertices = calculateTotalVerticesNeeded(levelsCount);

    // We don't need to account for the padding here since
    // the SpiralMapView is inside a padded container
    final availableWidth = size.width;

    // Define margins and screen bounds
    final leftMargin = availableWidth * 0.15;
    final rightMargin = availableWidth * 0.85;

    // Normal width between left and right margins
    final normalWidth = (rightMargin - leftMargin);

    // Starting position (leftmost side of screen)
    double startX = leftMargin;
    double startY = 60; // Reduced from 120 to 60 to minimize top gap

    // Vertical and diagonal steps
    double verticalStep = 120;
    double diagonalHorizontalStep = normalWidth;
    double diagonalVerticalStep = 80;

    // Current position
    double currentX = startX;
    double currentY = startY;

    // Add starting point (Point 1)
    positions.add(Offset(currentX, currentY));

    // Calculate positions for every vertex (including ones that will be skipped)
    for (int i = 1; i < totalVertices; i++) {
      // Determine which step in the pattern we're on (0-3)
      int step = (i - 1) % 4;

      // Adjusted values for specific lines
      double adjustedVerticalStep = verticalStep;

      // Line 3: line from vertex 3 to 4 (when i=3, we're calculating vertex 4)
      // Reduce length by 10%
      if (i == 3) {
        adjustedVerticalStep = verticalStep * 0.9; // 10% shorter
        // print("Reducing line 3 (vertex 3 to 4) by 10%");
      }
      // Line 5: line from vertex 5 to 6 (when i=5, we're calculating vertex 6)
      // Increase length by 10%
      else if (i == 5) {
        adjustedVerticalStep = verticalStep * 1.1; // 10% longer
        // print("Increasing line 5 (vertex 5 to 6) by 10%");
      }

      if (step == 0) {
        // Diagonal downwards and to the right
        currentX += diagonalHorizontalStep;
        currentY += diagonalVerticalStep;
      } else if (step == 1) {
        // Vertical down - where we need adjustments for lines 3 and 5
        currentY += adjustedVerticalStep; // Use adjusted vertical step
      } else if (step == 2) {
        // Diagonal upwards and to the left
        currentX -= diagonalHorizontalStep;
        currentY -= diagonalVerticalStep;
      } else if (step == 3) {
        // Vertical down
        currentY += verticalStep;
      }

      positions.add(Offset(currentX, currentY));
    }

    return positions;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Data models
class Segment {
  final int id;
  final String title;
  final int currentLevel;
  final int totalLevels;
  final List<Level> levels;
  final String? courseId; // Add courseId field

  Segment({
    required this.id,
    required this.title,
    required this.currentLevel,
    required this.totalLevels,
    required this.levels,
    this.courseId, // Make it optional
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      id: json['id'],
      title: json['title'],
      currentLevel: json['currentLevel'],
      totalLevels: json['totalLevels'],
      courseId: json['courseId'],
      levels:
          (json['levels'] as List)
              .map((levelData) => Level.fromJson(levelData))
              .toList(),
    );
  }
}

class Level {
  final int id;
  final String type; // 'video' or 'quiz'
  final String title;
  final String description;
  final String? quizId; // Add quizId field for quiz type
  final String? contentId; // Add contentId field to match with completedContent

  Level({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.quizId, // Make it optional
    this.contentId, // Make it optional
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      quizId: json['quizId'], // Parse quizId from JSON
      contentId: json['contentId'], // Parse contentId from JSON
    );
  }
}

Color getBackgroundColor(int segmentId) {
  // Calculate segment category (1-4) based on segment ID
  int category = ((segmentId - 1) % 4) + 1;

  switch (category) {
    case 1: // Violet
      return const Color(0xFFEFDEFF); // Light violet background
    case 2: // Green
      return const Color(0xFFF2FFFA); // Light green background
    case 3: // Orange
      return const Color(0xFFFCECE8); // Light orange background
    case 4: // Yellow
      return const Color(0xFFFEF8D5); // Light yellow background
    default:
      return const Color(0xFFEFDEFF); // Default to light violet
  }
}

Color getDashColor(int segmentId) {
  // Calculate segment category (1-4) based on segment ID
  int category = ((segmentId - 1) % 4) + 1;

  switch (category) {
    case 1: // Violet
      return Colors.purple.withValues(alpha: 0.3);
    case 2: // Green
      return const Color(0xFF95E9CA); // Green dash color
    case 3: // Orange
      return const Color(0xFFF3B4A5); // Orange dash color
    case 4: // Yellow
      return const Color(0xFFDECD69); // Yellow dash color
    default:
      return Colors.purple.withValues(alpha: 0.3); // Default to violet
  }
}

Color getPathBackgroundColor(int segmentId) {
  return getBackgroundColor(segmentId);
}

// Add new function to get the specified background colors
Color getBackgroundColorHex(int segmentId) {
  // Calculate segment category (1-4) based on segment ID
  int category = ((segmentId - 1) % 4) + 1;

  switch (category) {
    case 1: // Violet
      return const Color(0xFFEAD4FF); // Specified light violet background
    case 2: // Green
      return const Color(0xFFD6F5E9); // Specified light green background
    case 3: // Orange
      return const Color(0xFFF9DAD2); // Specified light orange background
    case 4: // Yellow
      return const Color(0xFFFCEE9D); // Specified light yellow background
    default:
      return const Color(0xFFEAD4FF); // Default to light violet
  }
}

// Calculate how many vertices we need total to display all levels
int calculateTotalVerticesNeeded(int totalLevels) {
  if (totalLevels <= 0) return 0;
  if (totalLevels == 1) return 1;
  if (totalLevels == 2) return 2;

  // For levels beyond 2, we need 2 vertices for the first two levels
  // plus 2 more vertices for each additional level (one for the level, one to skip)
  return 2 + 2 * (totalLevels - 2);
}
