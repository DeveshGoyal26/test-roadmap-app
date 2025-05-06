import 'dart:math';
import 'package:flutter/material.dart';
import 'package:skillpe/providers/auth_provider.dart';
import 'package:skillpe/services/course_service.dart';
import 'package:skillpe/widgets/cards/course_card.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'premium_banner.dart';

class MainContent extends StatefulWidget {
  const MainContent({super.key});

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  final CourseService _courseService = CourseService();
  List<dynamic> comingSoonCourses = [];
  List<dynamic> trendingCourses = [];
  List<dynamic> inProgressCourses = [];
  bool isLoading = true;
  bool _mounted = true; // Track mounted state

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  @override
  void dispose() {
    _mounted = false; // Set mounted to false when disposing
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    if (!_mounted) return;

    try {
      // Add retry mechanism
      int retryCount = 0;
      const maxRetries = 1;

      while (retryCount < maxRetries) {
        try {
          // Fetch all data in parallel for better performance
          final results = await Future.wait([
            _courseService.getComingSoonCourses(),
            _courseService.getTrendingCourses(),
            _courseService.getInProgressCourses(),
          ]);

          if (!_mounted) return;

          setState(() {
            comingSoonCourses = results[0]['courses'] ?? [];
            trendingCourses = results[1]['courses'] ?? [];
            inProgressCourses = results[2]['inProgressCourses'] ?? [];
            isLoading = false;
          });

          // If successful, break the retry loop
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw e; // Throw the error if max retries reached
          }
          // // Add exponential backoff delay
          // await Future.delayed(
          //   Duration(milliseconds: 500 * pow(2, retryCount).toInt()),
          // );
        }
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (!_mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // Refresh method that can be called to reload data
  Future<void> refreshData() async {
    if (!_mounted) return;

    setState(() {
      isLoading = true;
    });
    await _fetchAllData();
  }

  Color toColor(String hexColor) {
    String col = hexColor.replaceAll("#", "");
    if (col.length == 6) {
      col = "FF" + col;
    }
    if (col.length == 8) {
      return Color(int.parse("0x$col"));
    }
    return Colors.grey;
  }

  Widget _buildCourseGrid(
    BuildContext context,
    String title,
    List<dynamic> courses, {
    bool disableClick = false,
  }) {
    if (courses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get screen dimensions
    final screenWidth = min(MediaQuery.of(context).size.width, 420); //
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    // Determine if web based on screen width
    final isWeb = UniversalPlatform.isWeb;

    // Calculate responsive card dimensions with platform-specific adjustments
    final cardWidth =
        isWeb
            ? (screenWidth * 0.15).clamp(190.0, 250.0)
            : (screenWidth * 0.43).clamp(150.0, 200.0);

    // Adjust grid height for iOS to prevent text clipping
    final gridHeight =
        isIOS
            ? (screenWidth * 0.48).clamp(
              180.0,
              220.0,
            ) // Slightly taller for iOS
            : (screenWidth * 0.45).clamp(170.0, 200.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: isIOS ? 18 : 20, // Slightly smaller on iOS
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (courses.length > 2)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe,
                      size: isIOS ? 11 : 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Scroll for more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: isIOS ? 11 : 12,
                        height:
                            isIOS ? 1.2 : null, // Adjust line height for iOS
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (courses.length <= 2)
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio:
                  isIOS ? 0.95 : 1, // Slightly adjust ratio for iOS
            ),
            itemCount: courses.length,
            itemBuilder:
                (context, index) => CourseCard(
                  course: courses[index],
                  isWeb: isWeb,
                  width: cardWidth,
                  disableClick: disableClick,
                ),
          )
        else
          SizedBox(
            height: gridHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: courses.length,
              itemBuilder:
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: cardWidth,
                      child: CourseCard(
                        course: courses[index],
                        isWeb: isWeb,
                        disableClick: disableClick,
                        // Add extra height for iOS to prevent text clipping
                      ),
                    ),
                  ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (authProvider.userInfo?.subscriptionStatus != 'paid') ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
              child: const PremiumBanner(),
            ),
            const SizedBox(height: 24),
          ],
          if (inProgressCourses.isNotEmpty) ...[
            _buildCourseGrid(context, 'Continue Learning', inProgressCourses),
            const SizedBox(height: 12),
          ],
          if (trendingCourses.isNotEmpty) ...[
            _buildCourseGrid(context, 'Trending', trendingCourses),
            const SizedBox(height: 12),
          ],
          if (comingSoonCourses.isNotEmpty) ...[
            _buildCourseGrid(
              context,
              'Coming Soon',
              comingSoonCourses,
              disableClick: true,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
