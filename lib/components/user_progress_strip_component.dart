import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserProgressStripComponent extends StatelessWidget {
  final String message;
  final String? avatarUrl;
  final int sessionsRemaining;
  final VoidCallback? onTap;
  final List<Color> gradientColors;
  final List<double> gradientStops;

  const UserProgressStripComponent({
    super.key,
    this.message = 'Watch more sessions to unlock your exclusive AI mentor.',
    this.avatarUrl = 'https://i.pravatar.cc/48',
    this.sessionsRemaining = 3,
    this.onTap,
    this.gradientColors = const [
      Color(0xFFEDE94A), // Gradient color 1
      Color(0xFFFEFCBC), // Gradient color 2
      Color(0xFFF1ED50), // Gradient color 3
    ],
    this.gradientStops = const [0.0054, 0.5311, 0.9993],
  });

  @override
  Widget build(BuildContext context) {
    final String displayMessage =
        message.isEmpty
            ? 'Watch $sessionsRemaining more ${sessionsRemaining == 1 ? 'session' : 'sessions'} to unlock your exclusive AI mentor.'
            : message;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradientColors,
              stops: gradientStops,
            ),
          ),
          child: Row(
            children: [
              // Part 1: User icon with lock
              Stack(
                children: [
                  // User avatar with gradient border
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.1358, 0.9037],
                        transform: const GradientRotation(160 * 3.14159 / 180),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(
                          avatarUrl ?? 'https://i.pravatar.cc/48',
                        ), // Placeholder image
                      ),
                    ),
                  ),
                  // Lock icon
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Part 2: Text
              Expanded(
                child: Text(
                  displayMessage,
                  style: TextStyle(
                    color: const Color(0xFF171600),
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 18 / 12, // line-height: 18px (150%)
                    letterSpacing: 0.12,
                    fontFeatures: const [
                      FontFeature.proportionalFigures(),
                      FontFeature.enable('dlig'),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Part 3: Right arrow
              Transform.rotate(
                angle: 3.14159, // 180 degrees
                child: SvgPicture.string(
                  '''
                  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
                    <g clip-path="url(#clip0_461_802)">
                      <path d="M20.25 12H3.75" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                      <path d="M10.5 5.25L3.75 12L10.5 18.75" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </g>
                    <defs>
                      <clipPath id="clip0_461_802">
                        <rect width="24" height="24" fill="white"/>
                      </clipPath>
                    </defs>
                  </svg>
                  ''',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
