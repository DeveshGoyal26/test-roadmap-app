// Models for Course API data structure

class CourseContent {
  final String id;
  final String title;
  final String description;
  final int order;
  final String type;
  final String icon;
  final List<String> tags;
  final List<String> labels;
  final Map<String, dynamic> meta;

  CourseContent({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.type,
    required this.icon,
    required this.tags,
    required this.labels,
    required this.meta,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    try {
      final contentId = json['_id']?.toString() ?? '';
      print(
        'Parsing content: ${json['title']} with ID: $contentId, type: ${json['type']}',
      );

      return CourseContent(
        id: contentId,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        order:
            json['order'] is int
                ? json['order']
                : (int.tryParse('${json['order']}') ?? 0),
        type: json['type'] ?? '',
        icon: json['icon'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        labels: List<String>.from(json['labels'] ?? []),
        meta:
            json['meta'] ??
            // Special case for quizId (older API format)
            (json['quizId'] != null ? {'quizId': json['quizId']} : {}),
      );
    } catch (e) {
      print('Error parsing content from JSON: $e');
      // Return a default content in case of error
      return CourseContent(
        id: '',
        title: 'Error Loading Content',
        description: 'Could not parse content data',
        order: 0,
        type: 'unknown',
        icon: '',
        tags: [],
        labels: [],
        meta: {},
      );
    }
  }
}

class CourseSegment {
  final String id;
  final String title;
  final String description;
  final int segmentOrder;
  final int totalLevels;
  final bool freeFlow;
  final List<String> tags;
  final List<CourseContent> content;
  final String courseId;

  CourseSegment({
    required this.id,
    required this.title,
    required this.description,
    required this.segmentOrder,
    required this.totalLevels,
    required this.freeFlow,
    required this.tags,
    required this.content,
    required this.courseId,
  });

  factory CourseSegment.fromJson(Map<String, dynamic> json) {
    try {
      final segmentId = json['_id']?.toString() ?? '';
      final contentList = json['content'] as List?;

      print('Parsing segment: ${json['title']} with ID: $segmentId');
      print('Content count: ${contentList?.length ?? 0}');

      return CourseSegment(
        id: segmentId,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        segmentOrder: json['segmentOrder'] ?? 1,
        totalLevels: json['totalLevels'] ?? 0,
        freeFlow: json['freeFlow'] ?? false,
        tags: List<String>.from(json['tags'] ?? []),
        content:
            contentList != null
                ? contentList
                    .map((item) => CourseContent.fromJson(item))
                    .toList()
                : [],
        courseId: json['courseId'] ?? '',
      );
    } catch (e) {
      print('Error parsing segment from JSON: $e');
      // Return a default segment in case of error
      return CourseSegment(
        id: '',
        title: 'Error Loading Segment',
        description: 'Could not parse segment data',
        segmentOrder: 1,
        totalLevels: 0,
        freeFlow: false,
        tags: [],
        content: [],
        courseId: '',
      );
    }
  }
}

class Course {
  final String id;
  final String title;
  final String icon;
  final String description;
  final String category;
  final List<String> tags;
  final List<String> labels;
  final Map<String, dynamic> meta;
  final String createdAt;
  final String updatedAt;
  final List<CourseSegment> segments;
  final String userPaymentStatus;

  Course({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.category,
    required this.tags,
    required this.labels,
    required this.meta,
    required this.createdAt,
    required this.updatedAt,
    required this.segments,
    this.userPaymentStatus = 'free', // Default to free
  });

  factory Course.fromApiResponse(Map<String, dynamic> json) {
    print('Parsing Course from API response');
    try {
      final courseJson = json['course'];
      final segmentsJson = json['segments'];

      if (courseJson == null) {
        print('Error: course data is null in API response');
        // Return a default course
        return Course(
          id: '',
          title: 'Error Loading Course',
          icon: '',
          description: 'Could not load course data',
          category: '',
          tags: [],
          labels: [],
          meta: {},
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          segments: [],
          userPaymentStatus: 'free',
        );
      }

      print('Course title: ${courseJson['title']}');
      print('Segments count: ${segmentsJson?.length ?? 0}');

      return Course(
        id: courseJson['_id'],
        title: courseJson['title'],
        icon: courseJson['icon'] ?? '',
        description: courseJson['description'] ?? '',
        category: courseJson['category'] ?? '',
        tags: List<String>.from(courseJson['tags'] ?? []),
        labels: List<String>.from(courseJson['labels'] ?? []),
        meta: courseJson['meta'] ?? {},
        createdAt: courseJson['createdAt'] ?? DateTime.now().toIso8601String(),
        updatedAt: courseJson['updatedAt'] ?? DateTime.now().toIso8601String(),
        segments:
            segmentsJson != null
                ? (segmentsJson as List)
                    .map((item) => CourseSegment.fromJson(item))
                    .toList()
                : [],
        userPaymentStatus:
            json['userPaymentStatus'] ??
            courseJson['userPaymentStatus'] ??
            'free',
      );
    } catch (e) {
      print('Error parsing Course from API response: $e');
      // Return a default course in case of error
      return Course(
        id: '',
        title: 'Error Loading Course',
        icon: '',
        description: 'Could not parse course data: $e',
        category: '',
        tags: [],
        labels: [],
        meta: {},
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        segments: [],
        userPaymentStatus: 'free',
      );
    }
  }
}

class SegmentProgress {
  final String segmentId;
  final int progress;
  final List<String> completedContent;

  SegmentProgress({
    required this.segmentId,
    required this.progress,
    required this.completedContent,
  });

  factory SegmentProgress.fromJson(Map<String, dynamic> json) {
    return SegmentProgress(
      segmentId: json['segmentId'],
      progress: json['progress'],
      completedContent: List<String>.from(json['completedContent'] ?? []),
    );
  }
}

class CourseProgress {
  final String id;
  final String userId;
  final String courseId;
  final String startedAt;
  final String lastAccessedAt;
  final int overallProgress;
  final SegmentProgress? currentSegment;
  final List<String> completedSegments;
  final List<SegmentProgress> segmentProgress;

  CourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.startedAt,
    required this.lastAccessedAt,
    required this.overallProgress,
    this.currentSegment,
    required this.completedSegments,
    required this.segmentProgress,
  });

  factory CourseProgress.fromApiResponse(Map<String, dynamic> json) {
    final progressData = json['progress'];

    // Handle currentSegment which might be null
    SegmentProgress? currentSegment;
    if (progressData['currentSegment'] != null) {
      currentSegment = SegmentProgress.fromJson(progressData['currentSegment']);
    }

    return CourseProgress(
      id: progressData['_id'] ?? '',
      userId: progressData['userId'],
      courseId: progressData['courseId'],
      startedAt: progressData['startedAt'],
      lastAccessedAt: progressData['lastAccessedAt'],
      overallProgress: progressData['overallProgress'],
      currentSegment: currentSegment,
      completedSegments: List<String>.from(
        progressData['completedSegments'] ?? [],
      ),
      segmentProgress:
          (progressData['segmentProgress'] as List)
              .map((item) => SegmentProgress.fromJson(item))
              .toList(),
    );
  }
}
