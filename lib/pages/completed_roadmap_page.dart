import 'package:flutter/material.dart';
import 'dart:ui';
import '../components/header_component.dart';

class CompletedRoadmapPage extends StatelessWidget {
  const CompletedRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the arguments from the route
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String courseTitle = arguments?['courseTitle'] ?? 'Course';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: HeaderComponent(
          subtitle: "Roadmap Completed",
          title: courseTitle,
          isLoading: false,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              const Icon(Icons.celebration, size: 80, color: Colors.amber),
              const SizedBox(height: 32),

              // Congratulatory Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Woohoo! You've completed the roadmap great job!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 32 / 28, // line-height: 32px
                    letterSpacing: 0.28,
                    fontFeatures: [
                      FontFeature(
                        'dlig',
                        1,
                      ), // font-feature-settings: 'dlig' on
                    ],
                    fontVariations: [
                      FontVariation(
                        'lnum',
                        1,
                      ), // font-variant-numeric: lining-nums
                      FontVariation(
                        'pnum',
                        1,
                      ), // font-variant-numeric: proportional-nums
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Return to Dashboard Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Return to Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
