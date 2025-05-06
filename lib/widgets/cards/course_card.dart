import 'dart:math';

import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final dynamic course;
  final VoidCallback? onTap;
  final double? width;
  final bool isWeb;
  final bool disableClick;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.width,
    this.isWeb = false,
    this.disableClick = false,
  });

  Color _toColor(String hexColor) {
    String col = hexColor.replaceAll("#", "");
    if (col.length == 6) {
      col = "FF" + col;
    }
    if (col.length == 8) {
      return Color(int.parse("0x$col"));
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final screenWidth = min(MediaQuery.of(context).size.width, 420);

    return SizedBox(
      width: width,
      child: Card(
        shadowColor: Theme.of(
          context,
        ).colorScheme.shadow.withValues(alpha: 0.1),
        color:
            course['meta'] != null
                ? _toColor(course['meta']['color'])
                : Colors.grey,
        child: InkWell(
          onTap:
              onTap ??
              () {
                if (!disableClick) {
                  Navigator.pushNamed(
                    context,
                    '/roadmaps/${course['_id'] ?? course['courseId']}',
                    arguments: {
                      'courseId': course['_id'] ?? course['courseId'],
                    },
                  );
                }
              },
          child: Stack(
            children: [
              // Top images
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRect(
                        child: Transform.translate(
                          offset: const Offset(-19, -24),
                          child: Image.asset(
                            'assets/images/card-bg.png',
                            height: isIOS ? 70 : 80,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage('assets/images/category.png'),
                              fit: BoxFit.cover,
                            ),
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(11),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          height: isIOS ? 70 : 80,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Bottom aligned text
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 10.0,
                    right: 10.0,
                    bottom: 16.0,
                  ),
                  child: Text(
                    course['title'] ?? course['courseTitle'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: isIOS ? (screenWidth < 375 ? 16 : 18) : 20,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: isWeb ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
