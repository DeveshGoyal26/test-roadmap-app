import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

/// A component that renders a zigzag path with icons placed at specific turning points
/// Based on the spiral path implementation, adapted for a zigzag pattern
class ZigZagPathWithIcons extends StatefulWidget {
  final List<dynamic> contentItems;
  final String segmentId;
  final String colorTheme;
  final bool isFirstSegment;
  final String? nextContentId;
  final Function(dynamic, String) onContentTap;
  final String userPaymentStatus;
  final Map<String, dynamic> progressData;
  final VoidCallback onPaymentNavigate;

  const ZigZagPathWithIcons({
    super.key,
    required this.contentItems,
    required this.segmentId,
    required this.colorTheme,
    required this.isFirstSegment,
    required this.nextContentId,
    required this.onContentTap,
    required this.userPaymentStatus,
    required this.progressData,
    required this.onPaymentNavigate,
  });

  @override
  State<ZigZagPathWithIcons> createState() => _ZigZagPathWithIconsState();
}

class _ZigZagPathWithIconsState extends State<ZigZagPathWithIcons> {
  // Keys to locate icon positions for tooltips
  final Map<String, GlobalKey> _nodeKeys = {};

  // Current tooltip overlay entry
  OverlayEntry? _overlayEntry;

  // Add this to track pressed states for each icon
  final Map<String, bool> _pressedStates = {};

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  // Remove any existing tooltip
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get color for the path based on colorTheme
    Color pathColor;
    switch (widget.colorTheme) {
      case 'green':
        pathColor = const Color(0xFF95E9CA); // #95E9CA
        break;
      case 'orange':
        pathColor = const Color(0xFFF3B4A5); // #F3B4A5
        break;
      case 'yellow':
        pathColor = const Color(0xFFDECD69); // #DECD69
        break;
      case 'voilet':
      default:
        pathColor = const Color(0xFFDDBFF9); // #DDBFF9
        break;
    }

    // Get the background color based on colorTheme
    Color backgroundColor;
    switch (widget.colorTheme) {
      case 'green':
        backgroundColor = const Color(0xFFD6F5E9); // Light green background
        break;
      case 'orange':
        backgroundColor = const Color(0xFFF9DAD2); // Light orange background
        break;
      case 'yellow':
        backgroundColor = const Color(0xFFFCEE9D); // Light yellow background
        break;
      case 'voilet':
      default:
        backgroundColor = const Color(0xFFEAD4FF); // Light violet background
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dimensions
        final double maxWidth = constraints.maxWidth;

        // Calculate total height needed
        final double totalHeight = calculateMapHeight(
          widget.contentItems.length,
        );

        return SizedBox(
          height: totalHeight,
          width: maxWidth,
          child: CustomPaint(
            size: Size(maxWidth, totalHeight),
            painter: ZigZagPathPainter(
              color: pathColor,
              backgroundColor: backgroundColor,
              levelsCount: widget.contentItems.length,
            ),
            child: Stack(children: _buildLevelNodes(context, maxWidth)),
          ),
        );
      },
    );
  }

  // Calculate height based on content count (similar to SpiralMapView)
  double calculateMapHeight(int levelCount) {
    // Calculate total vertices needed based on number of levels
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

  // Calculate number of vertices needed (same as in SpiralMapView)
  int calculateTotalVerticesNeeded(int totalLevels) {
    if (totalLevels <= 0) return 0;
    if (totalLevels == 1) return 1;
    if (totalLevels == 2) return 2;

    // For levels beyond 2, we need 2 vertices for the first two levels
    // plus 2 more vertices for each additional level (one for the level, one to skip)
    return 2 + 2 * (totalLevels - 2);
  }

  // This builds the level nodes (icons) for the path
  List<Widget> _buildLevelNodes(BuildContext context, double maxWidth) {
    final List<Widget> nodes = [];

    // Get the node positions - these are the turning points along the path
    // Each position is an Offset with x,y coordinates where a vertex/turn occurs in the path
    final List<Offset> nodePositions = calculateNodePositions(
      context,
      maxWidth,
    );

    // Get the vertex indices where icons should be placed
    // This identifies which specific vertices/turning points should have icons
    // For example: [0, 1, 3, 5, 6] means icons should be at vertices 0, 1, 3, 5, and 6
    final List<int> vertexIndices = _getIconNodeIndices(
      widget.contentItems.length,
      widget.contentItems.length,
    );

    // Ensure we have enough positions for all vertices
    if (nodePositions.length < vertexIndices.last + 1) {
      debugPrint(
        'Warning: Not enough node positions calculated. Need ${vertexIndices.last + 1}, have ${nodePositions.length}',
      );
      return nodes;
    }

    // Find the index of the next content to be completed
    int nextContentIndex = -1;
    if (widget.nextContentId != null) {
      for (int i = 0; i < widget.contentItems.length; i++) {
        if (widget.contentItems[i]['_id'] == widget.nextContentId) {
          nextContentIndex = i;
          break;
        }
      }
    }

    // Define icon sizes
    final double iconSize = 59.0; // Width of icons
    final double iconHeight = 64.0; // Height of icons
    final double circleSize = 74.0; // Size of circle for next content

    // Loop through each content item to create nodes
    for (
      int i = 0;
      i < widget.contentItems.length && i < vertexIndices.length;
      i++
    ) {
      // Get the vertex index for this content item
      // This maps content item i to its position in the path
      final int vertexIndex = vertexIndices[i];

      // Get the content item
      final dynamic content = widget.contentItems[i];

      // Get content details
      final String contentId = content['_id'];
      final String contentType = content['type'] ?? '';

      // Determine if this is the first content in the first segment
      final bool isFirstContent = i == 0;

      // Check if the content is completed
      final bool isContentCompleted = _isContentCompleted(contentId);

      // Create a unique key for this content item
      final String keyId = 'content_${contentId}';
      if (!_nodeKeys.containsKey(keyId)) {
        _nodeKeys[keyId] = GlobalKey();
      }

      // Check if this is the next content to complete
      final bool isNextContent = i == nextContentIndex;

      // Determine accessibility logic
      bool isAccessible;
      if (widget.userPaymentStatus == 'paid') {
        // For paid users, completed content and the next content are accessible
        isAccessible = isContentCompleted || isNextContent;
      } else {
        // Only first content of first segment is accessible for unpaid users
        isAccessible = (widget.isFirstSegment && isFirstContent);
      }

      // Determine whether to show active icon
      final bool showActiveIcon =
          isContentCompleted || (isAccessible && isNextContent);

      // Get the correct icon based on status
      String svgAsset;
      if (widget.userPaymentStatus == 'paid') {
        // For paid users: completed content or next content gets active icon, others get locked content icon
        svgAsset =
            showActiveIcon
                ? _getLevelIcon(contentType, true)
                : _getLevelIcon(contentType, false);
      } else {
        // For unpaid users: only first content of first segment gets active icon, all others get lock icon
        svgAsset =
            widget.isFirstSegment && isFirstContent
                ? _getLevelIcon(contentType, true)
                : _getLockIcon();
      }

      // Get the position for this vertex
      // This is the exact x,y coordinates for the turning point
      Offset position = nodePositions[vertexIndex];

      // ==============================
      // ICON POSITIONING EXPLANATION:
      // ==============================
      // 1. The path is drawn through a series of vertices/turning points
      // 2. Icons are centered at specific vertices determined by _getIconNodeIndices()
      // 3. Vertices are calculated in calculateNodePositions() following a pattern:
      //    - Starting at leftMargin, 60px from top
      //    - Follows pattern: diagonal down-right, vertical down, diagonal up-left, vertical down
      // 4. To position icons exactly at turning points:
      //    - Get position from nodePositions[vertexIndex]
      //    - Center the icon by subtracting half its width/height
      //
      // 5. To position icons BEFORE turning points (attempted earlier):
      //    - For most vertices, reduce x value (move left)
      //    - Leave first and last icons at exact turning points
      //    - Implementation varies based on which segment the vertex is in
      // ==============================

      // Create the icon widget
      Widget iconWidget = GestureDetector(
        key: _nodeKeys[keyId],
        onTapDown: (_) {
          setState(() {
            _pressedStates[contentId] = true;
          });
        },
        onTapUp: (_) async {
          setState(() {
            _pressedStates[contentId] = false;
          });
          if (isAccessible) {
            // Add a small delay to allow the pressed state animation to complete
            if (mounted) {
              _showTooltip(context, content, isAccessible);
            }
          } else if (widget.userPaymentStatus != 'paid') {
            widget.onPaymentNavigate();
          }
        },
        onTapCancel: () {
          setState(() {
            _pressedStates[contentId] = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: isNextContent ? circleSize : iconSize,
          height: isNextContent ? circleSize : iconHeight,
          decoration: BoxDecoration(
            shape: isNextContent ? BoxShape.circle : BoxShape.rectangle,
            color: isNextContent ? Colors.white : Colors.transparent,
            boxShadow:
                isNextContent
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: Offset(
                          0,
                          _pressedStates[contentId] == true ? 2 : 4,
                        ),
                        blurRadius: _pressedStates[contentId] == true ? 2 : 4,
                      ),
                    ]
                    : [],
          ),
          transform: Matrix4.translationValues(
            0,
            _pressedStates[contentId] == true ? 2 : 0,
            0,
          ),
          child: Center(
            child: SvgPicture.asset(
              svgAsset,
              width: iconSize,
              height: iconHeight,
            ),
          ),
        ),
      );

      // Add the positioned icon to the list
      nodes.add(
        Positioned(
          left:
              position.dx -
              (isNextContent ? circleSize / 2 : iconSize / 2) +
              _getXOffset(i, widget.contentItems.length, vertexIndex),
          top:
              position.dy -
              (isNextContent ? circleSize / 2 : iconHeight / 2) +
              _getYOffset(i, widget.contentItems.length, vertexIndex),
          child: iconWidget,
        ),
      );
    }

    return nodes;
  }

  // Helper method to calculate x-axis offset to position icons before turning points
  double _getXOffset(int index, int totalItems, int vertexIndex) {
    // No offset for first and last icons
    if (index == 0 || index == totalItems - 1) {
      return 0;
    }

    // Calculate the offset direction based on which segment the icon is in
    int segmentType = (vertexIndex - 1) % 4;

    // For icons at different path segments, shift along the path line
    switch (segmentType) {
      case 0: // Diagonal down-right segment
        return -60.0; // Shift left along the diagonal
      case 2: // Diagonal up-left segment
        return 60.0; // Shift right along the diagonal
      default: // Vertical segments
        return 0.0; // No x-axis shift for vertical segments
    }
  }

  // Helper method to calculate y-axis offset to position icons before turning points
  double _getYOffset(int index, int totalItems, int vertexIndex) {
    // No offset for first and last icons
    if (index == 0 || index == totalItems - 1) {
      return 0;
    }

    // Calculate the offset direction based on which segment the icon is in
    int segmentType = (vertexIndex - 1) % 4;

    // For icons at different path segments, shift along the path line
    switch (segmentType) {
      case 0: // Diagonal down-right segment
        return -20.0; // Shift up along the diagonal
      case 1: // Vertical down segment
        return 0.0; // Shift up along vertical
      case 2: // Diagonal up-left segment
        return 10.0; // Shift down along the diagonal
      case 3: // Vertical down segment
        return 30.0; // Shift up along vertical
      default:
        return 0.0;
    }
  }

  // Helper method to determine which nodes should have icons
  List<int> _getIconNodeIndices(int totalLevels, int maxAvailableNodes) {
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

  // This calculates the positions for nodes along the path
  // Following the same pattern as SpiralMapView's calculateNodePositions
  List<Offset> calculateNodePositions(BuildContext context, double maxWidth) {
    final List<Offset> positions = [];

    // Calculate total vertices needed
    int totalVertices = calculateTotalVerticesNeeded(
      widget.contentItems.length,
    );

    // Define margins and screen bounds
    final leftMargin = maxWidth * 0.15;
    final rightMargin = maxWidth * 0.85;

    // Normal width between left and right margins
    final normalWidth = (rightMargin - leftMargin);

    // Starting position
    double startX = leftMargin;
    double startY = 60; // Positioned at the top like in SpiralMapView

    // Vertical and diagonal steps
    double verticalStep = 120;
    double diagonalHorizontalStep = normalWidth;
    double diagonalVerticalStep = 80;

    // Current position
    double currentX = startX;
    double currentY = startY;

    // Add starting point
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
      }
      // Line 5: line from vertex 5 to 6 (when i=5, we're calculating vertex 6)
      // Increase length by 10%
      else if (i == 5) {
        adjustedVerticalStep = verticalStep * 1.1; // 10% longer
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

  // Checks if a content item has been completed
  bool _isContentCompleted(String contentId) {
    if (widget.progressData['contentHistory'] == null) return false;

    final contentHistory = widget.progressData['contentHistory'] as List;
    return contentHistory.any((historyItem) {
      return historyItem['content'] != null &&
          historyItem['content']['_id'] == contentId;
    });
  }

  // Get the appropriate icon based on content type and status
  String _getLevelIcon(String type, bool isActive) {
    // Get icon based on content type, colorTheme and active status
    if (type.toLowerCase() == 'quiz') {
      switch (widget.colorTheme) {
        case 'green':
          return isActive
              ? 'assets/svg/quiz_active_green.svg'
              : 'assets/svg/quiz_lock_green.svg';
        case 'orange':
          return isActive
              ? 'assets/svg/quiz_active_orange.svg'
              : 'assets/svg/quiz_lock_orange.svg';
        case 'yellow':
          return isActive
              ? 'assets/svg/quiz_active_yellow.svg'
              : 'assets/svg/quiz_lock_yellow.svg';
        case 'voilet':
        default:
          return isActive
              ? 'assets/svg/quiz_active_voilet.svg'
              : 'assets/svg/quiz_lock_voilet.svg';
      }
    } else {
      // Video icon
      switch (widget.colorTheme) {
        case 'green':
          return isActive
              ? 'assets/svg/video_active_green.svg'
              : 'assets/svg/video_lock_green.svg';
        case 'orange':
          return isActive
              ? 'assets/svg/video_active_orange.svg'
              : 'assets/svg/video_lock_orange.svg';
        case 'yellow':
          return isActive
              ? 'assets/svg/video_active_yellow.svg'
              : 'assets/svg/video_lock_yellow.svg';
        case 'voilet':
        default:
          return isActive
              ? 'assets/svg/video_active_voilet.svg'
              : 'assets/svg/video_lock_voilet.svg';
      }
    }
  }

  // Helper method for locked content icons
  String _getLockIcon() {
    // Use color-specific lock icons
    switch (widget.colorTheme) {
      case 'green':
        return 'assets/svg/lock_green.svg';
      case 'orange':
        return 'assets/svg/lock_orange.svg';
      case 'yellow':
        return 'assets/svg/lock_yellow.svg';
      case 'voilet':
      default:
        return 'assets/svg/lock_voilet.svg';
    }
  }

  // Show tooltip for a content item
  void _showTooltip(BuildContext context, dynamic content, bool isAccessible) {
    // Remove any existing tooltip first
    _removeOverlay();

    final String contentId = content['_id'];
    final String contentType = content['type'] ?? '';
    final String keyId = 'content_${contentId}';
    final nodeKey = _nodeKeys[keyId];

    if (nodeKey?.currentContext == null) return;

    // Get the render box and position of the icon
    final RenderBox renderBox =
        nodeKey!.currentContext!.findRenderObject() as RenderBox;
    final Size iconSize = renderBox.size;
    final Offset iconPosition = renderBox.localToGlobal(Offset.zero);

    // Get screen size and safe area
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = math.min(screenSize.width, 300);
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final double safeAreaTop = padding.top;
    final double safeAreaBottom = screenSize.height - padding.bottom;

    // Calculate tooltip dimensions
    const double tooltipWidth = 280.0;
    const double tooltipHeight = 220.0;
    const double arrowSize = 15.0;
    const double margin = 20.0; // Margin from screen edges

    // Determine if icon is on left or right half of screen
    final bool isOnLeftHalf = iconPosition.dx < screenWidth / 2;

    // Calculate initial tooltip position
    double tooltipX;
    double tooltipY;
    bool showArrowOnLeft;

    // Calculate horizontal position
    if (isOnLeftHalf) {
      tooltipX = iconPosition.dx + iconSize.width + arrowSize;
      // Check if tooltip would go off screen on the right
      if (tooltipX + tooltipWidth > screenWidth - margin) {
        tooltipX = iconPosition.dx - tooltipWidth - arrowSize;
        showArrowOnLeft = false;
      } else {
        showArrowOnLeft = true;
      }
    } else {
      tooltipX = iconPosition.dx - tooltipWidth - arrowSize;
      // Check if tooltip would go off screen on the left
      if (tooltipX < margin) {
        tooltipX = iconPosition.dx + iconSize.width + arrowSize;
        showArrowOnLeft = true;
      } else {
        showArrowOnLeft = false;
      }
    }
    // Ensure tooltip X position stays within screen bounds
    tooltipX = math.max(math.min(tooltipX, screenWidth - tooltipWidth - margin), margin);

    // Calculate vertical position
    tooltipY = iconPosition.dy + (iconSize.height - tooltipHeight) / 2;

    // Ensure tooltip Y position stays within screen bounds
    tooltipY = tooltipY.clamp(
      safeAreaTop + margin,
      safeAreaBottom - tooltipHeight - margin,
    );

    // Adjust arrow position based on icon position
    double arrowY = (tooltipHeight - arrowSize * 2) / 2;
    if (tooltipY > iconPosition.dy) {
      // Tooltip is below icon center
      arrowY = iconPosition.dy - tooltipY + iconSize.height / 2 - arrowSize;
    } else if (tooltipY + tooltipHeight < iconPosition.dy + iconSize.height) {
      // Tooltip is above icon center
      arrowY = iconPosition.dy - tooltipY + iconSize.height / 2 - arrowSize;
    }

    // Clamp arrow position to stay within tooltip bounds
    arrowY = arrowY.clamp(arrowSize, tooltipHeight - arrowSize * 3);

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              // Barrier
              Positioned.fill(
                child: GestureDetector(
                  onTap: _removeOverlay,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.black12),
                ),
              ),
              // Tooltip
              Positioned(
                left: tooltipX,
                top: tooltipY,
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // // Arrow
                      // Positioned(
                      //   left: showArrowOnLeft ? -arrowSize : tooltipWidth,
                      //   top: arrowY,
                      //   child: CustomPaint(
                      //     size: Size(arrowSize, arrowSize * 2),
                      //     painter: TooltipArrowPainter(
                      //       pointLeft: !showArrowOnLeft,
                      //       color: Colors.white,
                      //     ),
                      //   ),
                      // ),
                      // Tooltip content
                      Container(
                        width: tooltipWidth,
                        constraints: BoxConstraints(
                          maxHeight: tooltipHeight,
                          minHeight: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child:
                              contentType.toLowerCase() == 'quiz'
                                  ? _buildQuizTooltip(content)
                                  : _buildVideoTooltip(content),
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

  // Widget for Video tooltip
  Widget _buildVideoTooltip(dynamic content) {
    final String title = content['title'] ?? 'Video';
    final String description = content['description'] ?? '';

    // Get button color based on theme
    Color buttonColor;
    switch (widget.colorTheme) {
      case 'green':
        buttonColor = const Color(0xFF3DC795);
        break;
      case 'orange':
        buttonColor = const Color(0xFFF3B4A5);
        break;
      case 'yellow':
        buttonColor = const Color(0xFFDECD69);
        break;
      case 'voilet':
      default:
        buttonColor = const Color(0xFF9933FF);
        break;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF171600),
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                _removeOverlay();
                widget.onContentTap(content, widget.segmentId);
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    "Watch Video",
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
    );
  }

  // Widget for Quiz tooltip
  Widget _buildQuizTooltip(dynamic content) {
    final String description = content['description'] ?? '';

    Color buttonColor;
    Color textColor;
    switch (widget.colorTheme) {
      case 'green':
        buttonColor = const Color(0xFF95E9CA);
        textColor = const Color(0xFF3DC795);
        break;
      case 'orange':
        buttonColor = const Color(0xFFF3B4A5);
        textColor = const Color(0xFFE5855C);
        break;
      case 'yellow':
        buttonColor = const Color(0xFFDECD69);
        textColor = const Color(0xFF171600);
        break;
      case 'voilet':
      default:
        buttonColor = const Color(0xFFDDBFF9);
        textColor = const Color(0xFF9933FF);
        break;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "It's Quiz Time",
                    style: TextStyle(
                      color: Color(0xFF171600),
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                _removeOverlay();
                widget.onContentTap(content, widget.segmentId);
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    "Start Quiz",
                    style: TextStyle(
                      color: textColor,
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
    );
  }
}

/// Custom painter that renders a zigzag path using the same techniques as SpiralPathPainter
class ZigZagPathPainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;
  final int levelsCount;

  ZigZagPathPainter({
    required this.color,
    required this.backgroundColor,
    required this.levelsCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate path points
    final List<Offset> points = calculatePathPoints(size);

    // Create path with properly rounded corners
    final Path path = createRoundedCornerPath(points);

    // STEP 1: Draw background path with rounded corners
    final Paint backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              22 // Width for background
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    // Draw the background path first
    canvas.drawPath(path, backgroundPaint);

    // STEP 2: Draw the dashed line on top of the background
    final Paint dashPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              8 // Width for dashed line
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

    // Create the mapping of level index to vertex index
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

  // Calculate all the points along the zigzag path
  List<Offset> calculatePathPoints(Size size) {
    final List<Offset> positions = [];

    // Calculate total vertices needed
    int totalVertices = calculateTotalVerticesNeeded(levelsCount);

    // Define margins and screen bounds
    final leftMargin = size.width * 0.15;
    final rightMargin = size.width * 0.85;

    // Normal width between left and right margins
    final normalWidth = (rightMargin - leftMargin);

    // Starting position
    double startX = leftMargin;
    double startY = 60; // Top position for first icon

    // Vertical and diagonal steps
    double verticalStep = 120;
    double diagonalHorizontalStep = normalWidth;
    double diagonalVerticalStep = 80;

    // Current position
    double currentX = startX;
    double currentY = startY;

    // Add starting point
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
      }
      // Line 5: line from vertex 5 to 6 (when i=5, we're calculating vertex 6)
      // Increase length by 10%
      else if (i == 5) {
        adjustedVerticalStep = verticalStep * 1.1; // 10% longer
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

  // Calculate total vertices needed
  int calculateTotalVerticesNeeded(int totalLevels) {
    if (totalLevels <= 0) return 0;
    if (totalLevels == 1) return 1;
    if (totalLevels == 2) return 2;

    return 2 + 2 * (totalLevels - 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

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

// Add this custom painter for the tooltip arrow
class TooltipArrowPainter extends CustomPainter {
  final bool pointLeft;
  final Color color;

  TooltipArrowPainter({required this.pointLeft, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    if (pointLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
