import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/index.dart';
import '../services/api_service.dart';
import '../components/bottom_navigation_bar.dart';

// Create a custom painter for the arrow
class ArrowPainter extends CustomPainter {
  final bool pointRight;

  ArrowPainter({required this.pointRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color =
              Colors
                  .white // Match the tooltip background color
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
          ..color = Colors.black.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Thumb Shape with Number for Slider
class NumberSliderThumbShape extends SliderComponentShape {
  final String numberText; // Text to display on the thumb
  final bool showNumber; // Flag to show or hide the number

  NumberSliderThumbShape({required this.numberText, required this.showNumber});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(20, 20); // Preferred size of the thumb
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw the circular thumb
    final paint =
        Paint()
          ..color = const Color(0xFF00CC99)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 10, paint); // Draw circle at the center

    // Draw the number if showNumber is true
    if (showNumber) {
      final textSpan = TextSpan(
        text: numberText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      final textCenter = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textCenter); // Paint the number on the thumb
    }
  }
}

// Level Data Model
class LevelData {
  final int level; // Level number
  final String description; // Description of the level
  final bool isCompleted; // Flag to indicate if the level is completed
  final bool isCurrent; // Flag to indicate if this is the current level
  final Position position; // Position of the level (left or right)
  final ContentType contentType; // Type of content (video or quiz)

  LevelData({
    required this.level,
    required this.description,
    required this.isCompleted,
    required this.isCurrent,
    required this.position,
    required this.contentType,
  });
}

// Enum for Position
enum Position { LEFT, RIGHT }

// Enum for ContentType
enum ContentType { VIDEO, QUIZ }

// Spiral Path Painter
class SpiralPathPainter extends CustomPainter {
  final int totalPoints; // Total number of points in the spiral

  SpiralPathPainter(this.totalPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFD8BBF6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width; // Get the width of the canvas
    final segmentHeight = 140.0; // Height of each segment in the spiral
    final controlPointOffset = segmentHeight * 0.9; // Offset for control points
    final initialOffset = 48.0; // Initial vertical offset for the spiral

    // Starting point - moved down further
    path.moveTo(width * 0.2, initialOffset);

    for (int i = 0; i < totalPoints - 1; i++) {
      final isEvenSegment = i % 2 == 0; // Check if the segment is even
      final startY = (i * segmentHeight) + initialOffset; // Start Y position
      final endY = ((i + 1) * segmentHeight) + initialOffset; // End Y position

      if (isEvenSegment) {
        // Draw cubic Bezier curve for even segments
        path.cubicTo(
          width * 0.2,
          startY + controlPointOffset * 0.5,
          width * 0.8,
          endY - controlPointOffset * 0.5,
          width * 0.8,
          endY,
        );
      } else {
        // Draw cubic Bezier curve for odd segments
        path.cubicTo(
          width * 0.8,
          startY + controlPointOffset * 0.5,
          width * 0.2,
          endY - controlPointOffset * 0.5,
          width * 0.2,
          endY,
        );
      }
    }

    // Draw dashed path
    final dashPath = Path();
    final dashWidth = 10.0; // Width of each dash
    final dashSpace = 8.0; // Space between dashes
    final metrics = path.computeMetrics().first; // Get the path metrics
    var distance = 0.0;

    while (distance < metrics.length) {
      final start = distance; // Start of the dash
      final end = (start + dashWidth); // End of the dash
      if (end <= metrics.length) {
        dashPath.addPath(
          metrics.extractPath(start, end),
          Offset.zero,
        ); // Add dash to the path
      }
      distance = end + dashSpace; // Move to the next dash
    }

    canvas.drawPath(dashPath, paint); // Draw the dashed path on the canvas
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // No need to repaint
}

// Spiral Path Component
class SpiralPathComponent extends StatefulWidget {
  final int currentLevel; // Current level of the user
  final int totalLevels; // Total number of levels
  final String description; // Description for the spiral path
  final ScrollController?
  scrollController; // ScrollController for auto-scrolling
  final Function(LevelData)?
  onReadyToShowTooltip; // Callback to notify when ready to show tooltip

  const SpiralPathComponent({
    super.key,
    required this.currentLevel,
    required this.totalLevels,
    required this.description,
    this.scrollController,
    this.onReadyToShowTooltip,
  });

  @override
  State<SpiralPathComponent> createState() => _SpiralPathComponentState();
}

class _SpiralPathComponentState extends State<SpiralPathComponent> {
  OverlayEntry? _overlayEntry; // Overlay entry for the tooltip
  final Map<int, GlobalKey> _starKeys = {}; // Global keys for star positions

  @override
  void initState() {
    super.initState();

    // No longer auto-show tooltip here, will be triggered from parent
    if (widget.onReadyToShowTooltip != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Notify the parent component that we're ready to show the tooltip
        // for the next level, passing the level data
        final nextLevel = widget.currentLevel + 1;
        if (nextLevel <= widget.totalLevels) {
          final levels = _generateLevelData();
          final nextLevelData = levels.firstWhere(
            (level) => level.level == nextLevel,
            orElse: () => levels.first,
          );

          widget.onReadyToShowTooltip!(nextLevelData);
        }
      });
    }
  }

  // Public method to show tooltip - can be called from outside
  void showTooltipForLevel(LevelData level) {
    _showTooltip(context, level);
  }

  void _removeOverlay() {
    _overlayEntry?.remove(); // Remove the overlay if it exists
    _overlayEntry = null; // Set overlay entry to null
  }

  void _showTooltip(BuildContext context, LevelData level) {
    // Only process for the level immediately after the current level
    if (level.level != widget.currentLevel + 1) return;

    _removeOverlay(); // Remove any existing overlay

    // Get the current position of the star using its global key
    final starKey = _starKeys[level.level];
    if (starKey?.currentContext == null) return;

    final RenderBox renderBox =
        starKey!.currentContext!.findRenderObject() as RenderBox;
    final Offset starPosition = renderBox.localToGlobal(Offset.zero);
    final Size starSize = renderBox.size;

    final tooltipWidth = 280.0; // Width of the tooltip
    final tooltipArrowSize = 10.0; // Size of the tooltip arrow

    // Calculate positions to align with star
    final isLeftStar =
        level.position == Position.LEFT; // Check if the star is on the left

    // Position tooltip correctly relative to the star
    final tooltipX =
        isLeftStar
            ? starPosition.dx +
                starSize
                    .width // Right of left stars
            : starPosition.dx -
                tooltipWidth -
                tooltipArrowSize; // Left of right stars

    // Align tooltip vertically with the center of the star
    final tooltipY = starPosition.dy - 100.0;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              // Transparent full-screen container to handle outside clicks
              Positioned.fill(
                child: GestureDetector(
                  onTap: _removeOverlay, // Dismiss tooltip on tap
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
                      // Show arrow on right for left stars
                      if (isLeftStar)
                        _buildArrowHorizontal(
                          isPointingRight: true,
                        ), // Arrow pointing to the right
                      // Tooltip content
                      Container(
                        width: tooltipWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child:
                            level.contentType == ContentType.VIDEO
                                ? _buildVideoTooltip(
                                  level,
                                ) // Build video tooltip
                                : _buildQuizTooltip(
                                  level,
                                ), // Build quiz tooltip
                      ),

                      // Show arrow on left for right stars
                      if (!isLeftStar)
                        _buildArrowHorizontal(
                          isPointingRight: false,
                        ), // Arrow pointing to the left
                    ],
                  ),
                ),
              ),
            ],
          ),
    );

    Overlay.of(
      context,
    ).insert(_overlayEntry!); // Insert the overlay into the widget tree
  }

  // Horizontal arrow pointing to the star
  Widget _buildArrowHorizontal({required bool isPointingRight}) {
    return SizedBox(
      width: 10,
      height: 20,
      child: CustomPaint(
        painter: ArrowPainter(pointRight: isPointingRight),
      ), // Draw the arrow
    );
  }

  // Widget for Video tooltip - Updated to match Quiz tooltip style
  Widget _buildVideoTooltip(LevelData level) {
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
                    "Level ${level.level}", // Video title with level number
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
                      'level': level.level,
                      'title': 'Level ${level.level}',
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

  // Widget for Quiz tooltip (based on the image)
  Widget _buildQuizTooltip(LevelData level) {
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
                "Explore your product design skills with this quiz time", // Quiz description
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
                  // Navigate to the quiz page with questions from QuizPage class
                  Navigator.pushNamed(
                    context,
                    '/quiz',
                    arguments: {
                      'title': 'Level ${level.level} Quiz',
                      'subtitle': 'Product Design',
                      'level': level.level,
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

  @override
  void dispose() {
    _removeOverlay(); // Clean up overlay on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels = _generateLevelData(); // Generate level data
    final initialOffset = 48.0; // Initial offset for the spiral path

    // Pre-populate star keys if needed
    for (var level in levels) {
      if (!_starKeys.containsKey(level.level)) {
        _starKeys[level.level] = GlobalKey();
      }
    }

    return SizedBox(
      height:
          (levels.length * 140.0) + initialOffset, // Set height based on levels
      child: Stack(
        children: [
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              (levels.length * 140.0) + initialOffset,
            ),
            painter: SpiralPathPainter(levels.length), // Draw the spiral path
          ),
          ...levels.map((level) {
            final yPosition =
                ((level.level - 1) * 140.0) +
                initialOffset; // Calculate Y position
            final screenWidth =
                MediaQuery.of(context).size.width; // Get screen width
            final xPosition =
                level.position == Position.LEFT
                    ? screenWidth *
                        0.2 // X position for left stars
                    : screenWidth * 0.8; // X position for right stars

            return Positioned(
              left: xPosition - 28, // Position star horizontally
              top: yPosition - 28, // Position star vertically
              child: GestureDetector(
                key: _starKeys[level.level],
                behavior:
                    HitTestBehavior.opaque, // Make the entire area tappable
                onTap: () {
                  _showTooltip(
                    context,
                    level,
                  ); // Show tooltip with current position from GlobalKey
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      level.isCompleted
                          ? 'assets/svg/completed-star.svg' // Completed star icon
                          : 'assets/svg/upcoming-star.svg', // Upcoming star icon
                      width: 56,
                      height: 56,
                    ),
                    Text(
                      '${level.level}', // Display level number
                      style: TextStyle(
                        color: level.isCompleted ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Generate level data for the spiral path
  List<LevelData> _generateLevelData() {
    final levels = <LevelData>[];
    for (int i = 1; i <= widget.totalLevels; i++) {
      levels.add(
        LevelData(
          level: i,
          description: widget.description, // Set level description
          isCompleted: i <= widget.currentLevel, // Check if level is completed
          isCurrent: i == widget.currentLevel, // Check if level is current
          position:
              i.isOdd ? Position.LEFT : Position.RIGHT, // Alternate positions
          contentType:
              i % 3 == 0
                  ? ContentType.QUIZ
                  : ContentType.VIDEO, // Alternate content types
        ),
      );
    }
    return levels; // Return generated levels
  }
}

// Main Page Component
class SpiralContentPage extends StatefulWidget {
  const SpiralContentPage({super.key});

  @override
  State<SpiralContentPage> createState() => _SpiralContentPageState();
}

class _SpiralContentPageState extends State<SpiralContentPage> {
  // Loading state
  bool _isLoading = true;

  // Data that will be loaded from API
  late int currentLevel;
  late int totalLevels;
  late String description;
  late List<LevelData> levels;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<_SpiralPathComponentState> _spiralComponentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSpiralPathData();
  }

  // Load spiral path data from API
  Future<void> _loadSpiralPathData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch data from API
      final data = await ApiService.getSpiralPathData();

      // Check if the widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        currentLevel = data['currentLevel'] ?? 1;
        totalLevels = data['totalLevels'] ?? 10;
        description = data['description'] ?? 'Explore our learning path';

        // Transform API level data to LevelData objects
        levels =
            (data['levels'] as List<dynamic>?)
                ?.map(
                  (levelJson) => LevelData(
                    level: levelJson['level'] ?? 1,
                    description: levelJson['description'] ?? '',
                    isCompleted: levelJson['isCompleted'] ?? false,
                    isCurrent: levelJson['isCurrent'] ?? false,
                    position:
                        levelJson['position'] == 'LEFT'
                            ? Position.LEFT
                            : Position.RIGHT,
                    contentType:
                        levelJson['contentType'] == 'QUIZ'
                            ? ContentType.QUIZ
                            : ContentType.VIDEO,
                  ),
                )
                .toList() ??
            [];

        _isLoading = false;
      });

      // Schedule scroll after the data is loaded and UI is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToNextLevel();
      });
    } catch (e) {
      // Check if the widget is still mounted before updating state
      if (!mounted) return;

      // Handle error with default data
      setState(() {
        currentLevel = 5;
        totalLevels = 10;
        description =
            'Explore the captivating world of video descriptions, where every frame tells a story.';
        levels = _generateDefaultLevelData();
        _isLoading = false;
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load data. Using default values.'),
          backgroundColor: Colors.red,
        ),
      );

      // Still scroll to the next level
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToNextLevel();
      });
    }
  }

  // Generate default level data if API fails
  List<LevelData> _generateDefaultLevelData() {
    final defaultLevels = <LevelData>[];
    final defaultDescription =
        'Explore the captivating world of video descriptions, where every frame tells a story.';

    for (int i = 1; i <= 10; i++) {
      defaultLevels.add(
        LevelData(
          level: i,
          description: defaultDescription,
          isCompleted: i <= 5,
          isCurrent: i == 5,
          position: i.isOdd ? Position.LEFT : Position.RIGHT,
          contentType: i % 3 == 0 ? ContentType.QUIZ : ContentType.VIDEO,
        ),
      );
    }
    return defaultLevels;
  }

  // Auto-scroll to the next level with animation
  void _scrollToNextLevel() {
    // Calculate the position to scroll to (based on level height and offset)
    final nextLevel = currentLevel + 1;
    if (nextLevel <= totalLevels) {
      final segmentHeight = 140.0;
      final initialOffset = 48.0;
      final scrollPosition =
          ((nextLevel - 1) * segmentHeight) -
          100.0; // Scroll to position the next level star in view

      // Animate to the position
      _scrollController
          .animateTo(
            scrollPosition,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          )
          .then((_) {
            // After scrolling completes, show the tooltip
            _showTooltipForNextLevel();
          });
    }
  }

  // Show tooltip for the next level after scrolling
  void _showTooltipForNextLevel() {
    // Delay slightly to ensure everything is properly positioned
    Future.delayed(const Duration(milliseconds: 100), () {
      final nextLevel = currentLevel + 1;
      if (nextLevel <= totalLevels) {
        // Find the next level data
        final nextLevelData = levels.firstWhere(
          (level) => level.level == nextLevel,
          orElse: () => levels.first,
        );

        // Show the tooltip through the component's method
        _spiralComponentKey.currentState?.showTooltipForLevel(nextLevelData);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:
            _isLoading
                ? _buildLoadingIndicator()
                : SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      const HeaderComponent(), // Header component
                      const SizedBox(height: 14),
                      ProgressSliderComponent(
                        currentValue:
                            currentLevel, // Current value for the slider
                        totalValue: totalLevels, // Total value for the slider
                        isEnabled: false, // Disable the slider
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 11),
                      const UserProgressStripComponent(), // User progress strip component
                      const SizedBox(height: 24),
                      SpiralPathComponent(
                        key:
                            _spiralComponentKey, // Use a key to access the component
                        currentLevel: currentLevel, // Pass current level
                        totalLevels: totalLevels, // Pass total levels
                        description: description, // Pass description from API
                        scrollController:
                            _scrollController, // Pass the scroll controller
                      ),
                    ],
                  ),
                ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: 1, // Set to 1 for "Roadmaps" selection
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/');
          }
          // Do nothing for index 1 (current page) and 2 (community)
        },
      ),
    );
  }

  // Loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Color(0xFFF8F87A), // Yellow theme color
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading spiral path...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF171600),
            ),
          ),
        ],
      ),
    );
  }
}
