import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillpe/pages/main_screen.dart';
import 'package:skillpe/providers/auth_provider.dart';
import 'package:skillpe/widgets/auth_guard.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Immediately navigate to main screen on web
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) =>
                    const AuthGuard(requireAuth: false, child: MainScreen()),
          ),
        );
      });
    } else {
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(
        'assets/videos/splash_screen.mp4',
      );

      await _controller.initialize();
      await _controller.setLooping(false);
      // Removed the line that sets the volume to 0.0 to prevent stopping background sound

      if (mounted) {
        setState(() {});
        _controller.play();
      }

      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) =>
                      const AuthGuard(requireAuth: false, child: MainScreen()),
            ),
          );
        }
      });
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        _isError = true;
      });
      // Navigate to main screen if video fails
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) =>
                    const AuthGuard(requireAuth: false, child: MainScreen()),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (kIsWeb) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body:
          !_controller.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _controller.dispose();
    }
    super.dispose();
  }
}
